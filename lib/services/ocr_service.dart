import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum MeterType {
  /// Mechanical roller display — dark background, white digits.
  /// Typically 5 integer + 3 decimal digits, unit m³.
  gas,

  /// LCD / digital display — bright background, dark digits.
  /// Typically 5–6 integer + 1–2 decimal digits, unit kWh.
  electricity,
}

class OcrResult {
  final String? reading;
  final String rawText;
  /// True when the kWh display line was found but digit count didn't match the
  /// configured intDigits + decDigits. The user should retake the photo.
  final bool digitCountMismatch;
  const OcrResult({
    this.reading,
    required this.rawText,
    this.digitCountMismatch = false,
  });
}

class _Candidate {
  final String value;
  final double score;
  final String sourceText;
  _Candidate({required this.value, required this.score, required this.sourceText});
}

class _ExtractResult {
  final String value;
  final int priority;
  _ExtractResult(this.value, this.priority);
}

class OcrService {
  Future<String?> extractMeterReading(
    String imagePath, {
    MeterType meterType = MeterType.gas,
    int intDigits = 5,
  }) async {
    final result = await extractMeterReadingWithRaw(
      imagePath,
      meterType: meterType,
      intDigits: intDigits,
    );
    return result.reading;
  }

  Future<OcrResult> extractMeterReadingWithRaw(
    String imagePath, {
    MeterType meterType = MeterType.gas,
    int intDigits = 5,
    int decDigits = 2,
    double? lastReading,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await recognizer.processImage(inputImage);

      final allLines = recognizedText.blocks.expand((b) => b.lines).toList();
      final rawText = allLines.map((l) => l.text).join(' | ');
      debugPrint('[OCR] Lines: $rawText');

      final brightnessSampler = await _BrightnessSampler.load(imagePath, allLines);

      final candidates = <_Candidate>[];

      for (final line in allLines) {
        final box = line.boundingBox;
        final area = box.width * box.height;
        final result = _tryExtractWithPriority(line.text, intDigits);
        if (result != null) {
          final brightness = brightnessSampler?.sample(box) ?? 128.0;
          final brightnessBonus = _brightnessBonus(brightness);
          // "kWh" / "m³" on the same line → this is the meter display, massive bonus.
          final unitBonus = _unitBonus(line.text);
          final score = result.priority * 1000000.0 + area + brightnessBonus + unitBonus;
          debugPrint(
              '[OCR] Candidate: "${line.text}" → ${result.value}  pri=${result.priority}  '
              'area=${area.toStringAsFixed(0)}  bri=${brightness.toStringAsFixed(0)}  '
              'unit=${unitBonus > 0 ? "YES" : "no"}  score=${score.toStringAsFixed(0)}');
          candidates.add(_Candidate(
              value: result.value, score: score, sourceText: line.text));
        }
      }

      // Adjacent line pairs (integer + decimal split across two ML Kit lines).
      // IMPORTANT: never combine a kWh/m³ display line with its neighbour — the
      // display line is self-contained.
      for (int i = 0; i < allLines.length - 1; i++) {
        final lineAText = allLines[i].text;
        final lineBText = allLines[i + 1].text;
        if (_unitBonus(lineAText) > 0 || _unitBonus(lineBText) > 0) continue;

        final combined = '${lineAText.trim()} ${lineBText.trim()}';
        final result = _tryExtractWithPriority(combined, intDigits);
        if (result != null) {
          final areaA = allLines[i].boundingBox.width *
              allLines[i].boundingBox.height;
          final areaB = allLines[i + 1].boundingBox.width *
              allLines[i + 1].boundingBox.height;
          final area = areaA + areaB;
          final combinedBox = allLines[i].boundingBox
              .expandToInclude(allLines[i + 1].boundingBox);
          final brightness =
              brightnessSampler?.sample(combinedBox) ?? 128.0;
          final brightnessBonus = _brightnessBonus(brightness);
          final score = result.priority * 1000000.0 + area + brightnessBonus;
          debugPrint(
              '[OCR] Pair: "$combined" → ${result.value}  pri=${result.priority}  '
              'score=${score.toStringAsFixed(0)}');
          candidates.add(_Candidate(
              value: result.value, score: score, sourceText: combined));
        }
      }

      if (candidates.isNotEmpty) {
        candidates.sort((a, b) => b.score.compareTo(a.score));

        // History validation: prefer the smallest plausible value >= lastReading.
        if (lastReading != null) {
          final valid = candidates
              .where((c) {
                final v = double.tryParse(c.value);
                return v != null && v >= lastReading;
              })
              .toList();
          if (valid.isNotEmpty) {
            valid.sort((a, b) =>
                double.parse(a.value).compareTo(double.parse(b.value)));
            final best = valid.first;
            debugPrint(
                '[OCR] History pick: "${best.sourceText}" → ${best.value} (lastReading=$lastReading)');
            return OcrResult(
                reading: _truncateToDecimals(best.value, decDigits), rawText: rawText);
          }
          debugPrint(
              '[OCR] All candidates below lastReading=$lastReading, using score-based pick');
        }

        final best = candidates.first;
        debugPrint(
            '[OCR] Best: "${best.sourceText}" → ${best.value}  score=${best.score}');
        return OcrResult(
            reading: _truncateToDecimals(best.value, decDigits), rawText: rawText);
      }

      final fullText = allLines.map((l) => l.text).join(' ');
      final fallback = _tryExtractWithPriority(fullText, intDigits);
      return OcrResult(
        reading: fallback != null ? _truncateToDecimals(fallback.value, decDigits) : null,
        rawText: rawText,
      );
    } catch (e) {
      debugPrint('[OCR] Error: $e');
      return const OcrResult(rawText: '');
    } finally {
      await recognizer.close();
    }
  }

  /// Bonus when the text line contains a meter unit ("kWh" or "m³") —
  /// strongest possible signal that this line is the display, not a label.
  double _unitBonus(String lineText) {
    final t = lineText.toLowerCase();
    if (t.contains('kwh')) return 4000000.0;
    if (t.contains('m³') || t.contains('m3')) return 4000000.0;
    return 0.0;
  }

  // ---------------------------------------------------------------------------
  // Fixed-digit electricity extraction
  // ---------------------------------------------------------------------------

  /// Extracts an electricity meter reading using a fixed digit-count approach.
  ///
  /// The user has configured [intDigits] digits before the decimal and
  /// [decDigits] digits after. The method searches for a line containing "kWh"
  /// and extracts exactly [intDigits] + [decDigits] consecutive digits from it.
  ///
  /// Splitting is purely positional:
  ///   • first [intDigits] digits  → integer part (leading zeros stripped)
  ///   • last  [decDigits] digits  → decimal part  (leading zeros kept)
  ///
  /// Validation: if the digit count on the kWh line ≠ total, [digitCountMismatch]
  /// is set to true so the UI can show a specific retry message.
  Future<OcrResult> extractElectricityReading(
    String imagePath, {
    required int intDigits,
    required int decDigits,
  }) async {
    final totalDigits = intDigits + decDigits;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await recognizer.processImage(inputImage);
      final allLines = recognizedText.blocks.expand((b) => b.lines).toList();
      final rawText = allLines.map((l) => l.text).join(' | ');
      debugPrint('[OCR-Elec] Lines: $rawText');
      debugPrint('[OCR-Elec] Expecting $intDigits + $decDigits = $totalDigits digits');

      // ── Image-level display window detection ─────────────────────────────
      // The roller display has a unique pixel signature:
      //   • Medium mean brightness  (dark bg + white digit strokes combined)
      //   • HIGH variance           (stark black/white contrast within the row)
      // White label panel: high mean, low variance.
      // Black housing:     very low mean, very low variance.
      // We find the display window in pixel space, then only look at ML Kit
      // lines whose vertical center falls inside it.
      final brightnessSampler =
          await _BrightnessSampler.load(imagePath, allLines);
      final displayWindow = brightnessSampler?.findDisplayWindow();
      debugPrint('[OCR-Elec] Display window (orig coords): $displayWindow');

      _ElecCandidate? best;

      for (final line in allLines) {
        final lineText = line.text;

        // ── Spatial filter ──────────────────────────────────────────────────
        // If a display window was detected, skip lines outside it.
        if (displayWindow != null) {
          final centerY =
              (line.boundingBox.top + line.boundingBox.bottom) / 2.0;
          if (centerY < displayWindow.top || centerY > displayWindow.bottom) {
            continue;
          }
        }

        // ── Brightness filter (primary rule) ────────────────────────────────
        // The digit drum has BLACK background + WHITE digits → sampled
        // brightness is LOW. White label areas have bright background → HIGH.
        // We only read white-on-black, so reject anything too bright.
        if (brightnessSampler != null) {
          final bg = brightnessSampler.sample(line.boundingBox);
          debugPrint('[OCR-Elec] bg=${bg.toStringAsFixed(0)} '
              '"${lineText.trim()}"');
          if (bg > 130) {
            debugPrint('[OCR-Elec] → skip (white/bright background)');
            continue;
          }
        } else if (displayWindow == null) {
          // Last resort: no pixel data and no window — suppress serial numbers.
          if (RegExp(r'\bNr[.\s|]*\d', caseSensitive: false)
              .hasMatch(lineText)) { continue; }
        }

        final candidate = _elecExtract(lineText, intDigits, decDigits);
        if (candidate == null) continue;

        // Prefer physically taller lines (digit drum rows > small label text).
        final score = line.boundingBox.height;
        debugPrint('[OCR-Elec] ✓ "${lineText.trim()}" '
            'h=${score.toInt()} → $candidate');

        if (best == null || score > best.score) {
          best = _ElecCandidate(reading: candidate, score: score);
        }
      }

      if (best != null) {
        debugPrint('[OCR-Elec] ✓ ${best.reading}');
        return OcrResult(reading: best.reading, rawText: rawText);
      }

      debugPrint('[OCR-Elec] No usable line found');
      return OcrResult(rawText: rawText);
    } catch (e) {
      debugPrint('[OCR-Elec] Error: $e');
      return const OcrResult(rawText: '');
    } finally {
      await recognizer.close();
    }
  }

  /// Extracts a gas meter reading.
  ///
  /// Strategy: anchor on the "m³" / "m3" unit label that always appears on the
  /// display row, then extract digits from that line via [_elecExtract].
  /// This is display-colour-agnostic — works for both dark-background rollers
  /// and the more common light-background roller displays.
  Future<OcrResult> extractGasReading(
    String imagePath, {
    required int intDigits,
    required int decDigits,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await recognizer.processImage(inputImage);
      final allLines = recognizedText.blocks.expand((b) => b.lines).toList();
      final rawText = allLines.map((l) => l.text).join(' | ');
      debugPrint('[OCR-Gas] Raw lines: $rawText');

      bool isUnitLine(String t) {
        final lower = t.toLowerCase();
        return lower.contains('m³') || lower.contains('m3');
      }

      // Pass 1: line that contains the unit AND enough digits.
      for (final line in allLines) {
        if (!isUnitLine(line.text)) continue;
        final candidate = _elecExtract(line.text, intDigits, decDigits);
        if (candidate != null) {
          debugPrint('[OCR-Gas] Unit-anchored: "${line.text.trim()}" → $candidate');
          return OcrResult(reading: candidate, rawText: rawText);
        }
      }

      // Pass 2: ML Kit sometimes splits the display into two adjacent lines.
      // Combine the unit line with its immediate neighbours.
      for (int i = 0; i < allLines.length; i++) {
        if (!isUnitLine(allLines[i].text)) continue;
        final start = (i - 1).clamp(0, allLines.length - 1);
        final end   = (i + 1).clamp(0, allLines.length - 1);
        final combined = allLines
            .sublist(start, end + 1)
            .map((l) => l.text)
            .join(' ');
        final candidate = _elecExtract(combined, intDigits, decDigits);
        if (candidate != null) {
          debugPrint('[OCR-Gas] Combined near unit: "$combined" → $candidate');
          return OcrResult(reading: candidate, rawText: rawText);
        }
      }

      // Pass 3: no unit found — fall back to the tallest line with enough digits
      // (last resort, same heuristic as extractElectricityReading).
      _ElecCandidate? best;
      for (final line in allLines) {
        final candidate = _elecExtract(line.text, intDigits, decDigits);
        if (candidate == null) continue;
        final score = line.boundingBox.height;
        if (best == null || score > best.score) {
          best = _ElecCandidate(reading: candidate, score: score);
        }
      }
      if (best != null) {
        debugPrint('[OCR-Gas] Fallback height pick → ${best.reading}');
        return OcrResult(reading: best.reading, rawText: rawText);
      }

      debugPrint('[OCR-Gas] No result found');
      return OcrResult(rawText: rawText);
    } catch (e) {
      debugPrint('[OCR-Gas] Error: $e');
      return const OcrResult(rawText: '');
    } finally {
      await recognizer.close();
    }
  }

  /// Normalizes a meter display line and extracts digits.
  /// Returns "intPart.decPart" string if enough digits found, null otherwise.
  String? _elecExtract(String lineText, int intDigits, int decDigits) {
    // Normalize OCR misreads common on roller digit displays:
    //   i / l / I / | (pipe from box borders) → 1
    //   o / O → 0
    final normalized = lineText
        .replaceAll(RegExp(r'[ilI|]'), '1')
        .replaceAll(RegExp(r'[oO]'), '0');
    final digits = normalized.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < intDigits) return null;
    final intRaw    = digits.substring(0, intDigits);
    final remaining = digits.substring(intDigits);
    final decPart   = remaining.isEmpty
        ? '0' * decDigits
        : remaining.substring(0, remaining.length.clamp(0, decDigits));
    final intValue  = int.tryParse(intRaw) ?? 0;
    return '$intValue.$decPart';
  }

  /// Scoring bonus based on background brightness.
  /// Dark background → roller digit window (bonus).
  /// Bright background → spec label / housing (penalty).
  double _brightnessBonus(double brightness) {
    if (brightness < 80) return 2000000.0;
    if (brightness > 160) return -800000.0;
    return 0.0;
  }

  /// Truncate to exactly [dec] decimal places.
  String _truncateToDecimals(String value, int dec) {
    final dotIdx = value.indexOf('.');
    if (dotIdx == -1) return value;
    final end = (dotIdx + 1 + dec).clamp(0, value.length);
    return value.substring(0, end);
  }

  /// Normalize common OCR misreads of digits on roller/segment displays.
  /// Covers characters that look like 1 (T, l, I, i, |) or 0 (O)
  /// when they appear directly adjacent to real digit characters.
  String _normalizeDigits(String text) {
    // Characters visually indistinguishable from "1" on white-on-black rollers:
    //   T, l (lowercase L), I (uppercase I), i (lowercase i), | (vertical bar)
    var r = text.replaceAllMapped(RegExp(r'[TlIi|](?=[0-9])'), (_) => '1');
    r = r.replaceAllMapped(RegExp(r'(?<=[0-9])[TlIi|]'), (_) => '1');
    r = r.replaceAllMapped(RegExp(r'(?<![A-Za-z])O(?=[0-9])'), (_) => '0');
    return r;
  }

  _ExtractResult? _tryExtractWithPriority(String text, int intDigits) {
    var t = _normalizeDigits(text.replaceAll(RegExp(r'\s+'), ' ').trim());

    // Normalize: collapse any space between digits and a decimal separator.
    // ML Kit sometimes reads "151069 ,0" instead of "151069,0" when the decimal
    // drum has a different visual appearance (e.g. red background on roller).
    t = t.replaceAllMapped(
      RegExp(r'(\d)\s+([,.])\s*(\d)'),
      (m) => '${m[1]}${m[2]}${m[3]}',
    );

    // Suppress lines where a serial-number label ("Nr", "Nr.", "Nr:") immediately
    // precedes the digit sequence — these are device IDs, not meter readings.
    final isSerialNumberLine = RegExp(r'\bNr\.?\s*\d', caseSensitive: false).hasMatch(t);
    if (isSerialNumberLine) return null;

    // ── Priority 5: Roller display — intDigits dot-separated groups + decimal ─
    final dotGroups =
        List.generate(intDigits, (_) => r'(\d)').join(r'\.');
    final rfm =
        RegExp('$dotGroups\\s*[,. ]\\s*(\\d{3})').firstMatch(t);
    if (rfm != null) {
      final intPart =
          List.generate(intDigits, (i) => rfm.group(i + 1)!).join();
      return _ExtractResult('$intPart.${rfm.group(intDigits + 1)}', 5);
    }

    // Roller — integer only
    final rim = RegExp('$dotGroups(?![,.\\d])').firstMatch(t);
    if (rim != null) {
      final intPart =
          List.generate(intDigits, (i) => rim.group(i + 1)!).join();
      return _ExtractResult('$intPart.000', 4);
    }

    // ── Priority 4: German thousands format 12.345,678 ───────────────────────
    final gm = RegExp(r'(\d{1,3}(?:\.\d{3})+,\d{1,3})').firstMatch(t);
    if (gm != null) {
      return _ExtractResult(
          gm.group(1)!.replaceAll('.', '').replaceAll(',', '.'), 4);
    }

    // ── Priority 3: Standard decimal — covers 4–7 integer digits ─────────────
    final dm = RegExp(r'(\d{4,7}[.,]\d{1,3})').firstMatch(t);
    if (dm != null) {
      return _ExtractResult(dm.group(1)!.replaceAll(',', '.'), 3);
    }

    // ── Priority 3 (fallback): Exact intDigits or intDigits+1 consecutive digits
    // Covers two common failure modes on roller electricity meters:
    //   • Decimal separator not visible → ML Kit reads "151069" (6 digits, no comma)
    //   • Decimal drum merged with main display → reads "1510699" (7 digits)
    // The extra digit (if present) is treated as the single decimal digit.
    final exactM = RegExp('(?<!\\d)(\\d{$intDigits,${intDigits + 1}})(?!\\d)').firstMatch(t);
    if (exactM != null) {
      final digits = exactM.group(1)!;
      final matchStart = t.indexOf(digits);
      final precededByLetter =
          matchStart > 0 && RegExp(r'[A-Za-z]').hasMatch(t[matchStart - 1]);
      if (!precededByLetter) {
        final intPart = digits.substring(0, intDigits);
        final decPart = digits.length > intDigits ? digits.substring(intDigits) : '0';
        return _ExtractResult('$intPart.$decPart', 3);
      }
    }

    // ── Priority 2: Split sections "15154 888" ────────────────────────────────
    final spm = RegExp('(\\d{$intDigits})\\s+(\\d{3})(?!\\d)').firstMatch(t);
    if (spm != null) {
      final start = spm.start;
      final precededByLetter =
          start > 0 && RegExp(r'[A-Za-z]').hasMatch(t[start - 1]);
      if (!precededByLetter) {
        return _ExtractResult('${spm.group(1)}.${spm.group(2)}', 2);
      }
    }

    // ── Priority 1: Space-separated digit groups ──────────────────────────────
    final fullLen = intDigits + 3;
    final partialLen = intDigits + 2;
    final middleMin = partialLen - 2;
    final middleMax = fullLen + 4;
    final sm =
        RegExp('(\\d[\\d ]{$middleMin,$middleMax}\\d)').firstMatch(t);
    if (sm != null) {
      final stripped = sm.group(1)!.replaceAll(' ', '');
      if (stripped.length == fullLen || stripped.length == partialLen) {
        final start = sm.start;
        final precededByLetter =
            start > 0 && RegExp(r'[A-Za-z]').hasMatch(t[start - 1]);
        if (!precededByLetter) {
          final intPart = stripped.substring(0, intDigits);
          final decPart = stripped.substring(intDigits);
          return _ExtractResult('$intPart.$decPart', 1);
        }
      }
    }

    // ── Priority 0: Plain integer ─────────────────────────────────────────────
    final lm = RegExp('(\\d{$partialLen,$fullLen})').firstMatch(t);
    if (lm != null) {
      final start = lm.start;
      final precededByLetter =
          start > 0 && RegExp(r'[A-Za-z]').hasMatch(t[start - 1]);
      if (!precededByLetter) {
        final digits = lm.group(1)!;
        final intPart = digits.substring(0, intDigits);
        final decPart = digits.substring(intDigits);
        return _ExtractResult('$intPart.$decPart', 0);
      }
    }

    return null;
  }
}

// ---------------------------------------------------------------------------
// Electricity candidate helper
// ---------------------------------------------------------------------------

class _ElecCandidate {
  final String reading;
  final double score;
  const _ElecCandidate({required this.reading, required this.score});
}

// ---------------------------------------------------------------------------
// Brightness sampler — loads image at low resolution and samples pixel
// brightness behind a given bounding box.
// ---------------------------------------------------------------------------

class _BrightnessSampler {
  final ui.Image _image;
  final ByteData _pixels;
  final double _scaleX;
  final double _scaleY;

  _BrightnessSampler._(this._image, this._pixels, this._scaleX, this._scaleY);

  /// Load a low-resolution version of the image for fast brightness sampling.
  /// Returns null if loading fails (OCR continues without brightness analysis).
  static Future<_BrightnessSampler?> load(
      String imagePath, List<TextLine> allLines) async {
    try {
      final bytes = Uint8List.fromList(await File(imagePath).readAsBytes());

      // Read true original dimensions from the file header (JPEG/PNG).
      // This is critical: estimating from ML Kit bounding boxes is unreliable
      // because text often covers only the upper portion of the image, causing
      // the scale factor to be off by 2x or more.
      final dims = _parseImageDimensions(bytes);

      // Decode at a small target width to save memory and speed up sampling.
      const targetWidth = 320;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;

      double origW, origH;
      if (dims != null) {
        origW = dims.$1;
        origH = dims.$2;
        debugPrint('[OCR] Image dimensions from header: ${origW.toInt()}×${origH.toInt()}');
      } else {
        // Fallback: estimate from ML Kit bounding boxes (less accurate).
        origW = 0; origH = 0;
        for (final line in allLines) {
          origW = math.max(origW, line.boundingBox.right);
          origH = math.max(origH, line.boundingBox.bottom);
        }
        if (origW < 1) origW = 1920;
        if (origH < 1) origH = 1080;
        debugPrint('[OCR] Image dimensions estimated from bboxes: ${origW.toInt()}×${origH.toInt()}');
      }

      final scaleX = img.width / origW;
      final scaleY = img.height / origH;

      final pixelData =
          await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (pixelData == null) return null;

      return _BrightnessSampler._(img, pixelData, scaleX, scaleY);
    } catch (e) {
      debugPrint('[OCR] BrightnessSampler load failed: $e');
      return null;
    }
  }

  /// Reads image dimensions from a JPEG or PNG file header without full decode.
  /// Returns (width, height) or null if the format is unrecognised.
  static (double, double)? _parseImageDimensions(Uint8List bytes) {
    // JPEG: scan for SOF0 (0xC0), SOF1 (0xC1) or SOF2 (0xC2) markers.
    // Each SOF segment: FF marker len(2) precision(1) height(2) width(2)
    if (bytes.length > 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      int i = 2;
      while (i + 4 < bytes.length) {
        if (bytes[i] != 0xFF) break;
        final marker = bytes[i + 1];
        if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
          if (i + 9 <= bytes.length) {
            final h = ((bytes[i + 5] << 8) | bytes[i + 6]).toDouble();
            final w = ((bytes[i + 7] << 8) | bytes[i + 8]).toDouble();
            if (w > 0 && h > 0) return (w, h);
          }
          return null;
        }
        // Markers with no payload (RST0–RST7, SOI, EOI, TEM).
        if (marker == 0xD9) break;
        if ((marker >= 0xD0 && marker <= 0xD9) || marker == 0x01) {
          i += 2;
          continue;
        }
        final segLen = (bytes[i + 2] << 8) | bytes[i + 3];
        if (segLen < 2) break;
        i += 2 + segLen;
      }
    }
    // PNG: 8-byte signature, then IHDR chunk at offset 8.
    // IHDR layout: length(4) "IHDR" width(4) height(4) ...
    if (bytes.length >= 24 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47) {
      final w = ((bytes[16] << 24) | (bytes[17] << 16) |
                 (bytes[18] << 8)  |  bytes[19]).toDouble();
      final h = ((bytes[20] << 24) | (bytes[21] << 16) |
                 (bytes[22] << 8)  |  bytes[23]).toDouble();
      if (w > 0 && h > 0) return (w, h);
    }
    return null;
  }

  /// Returns the average pixel brightness (0–255) in the scaled region.
  double sample(ui.Rect box) {
    final w = _image.width;
    final h = _image.height;
    final left = (box.left * _scaleX).clamp(0, w - 1).toInt();
    final right = (box.right * _scaleX).clamp(0, w - 1).toInt();
    final top = (box.top * _scaleY).clamp(0, h - 1).toInt();
    final bottom = (box.bottom * _scaleY).clamp(0, h - 1).toInt();

    if (left >= right || top >= bottom) return 128.0;

    double total = 0;
    int count = 0;
    // Sample every 3 pixels for speed.
    for (int y = top; y < bottom; y += 3) {
      for (int x = left; x < right; x += 3) {
        final offset = (y * w + x) * 4;
        if (offset + 2 >= _pixels.lengthInBytes) continue;
        final r = _pixels.getUint8(offset);
        final g = _pixels.getUint8(offset + 1);
        final b = _pixels.getUint8(offset + 2);
        total += 0.299 * r + 0.587 * g + 0.114 * b;
        count++;
      }
    }
    return count > 0 ? total / count : 128.0;
  }

  /// Detects the digit drum (Zahlentrommel) of an electricity meter.
  ///
  /// Pixel signature of the digit drum: BLACK background + WHITE digits.
  ///   → LOW mean brightness (dark dominates) + HIGH variance (stark contrast).
  /// White label areas of the meter: HIGH mean → excluded from consideration.
  /// Solid black housing: low mean but also LOW variance → excluded by score.
  ///
  /// Returns a Rect in ORIGINAL (unscaled) image coordinates, or null.
  ui.Rect? findDisplayWindow() {
    final w = _image.width;
    final h = _image.height;
    const strips = 40;
    final stripH = math.max(1, h ~/ strips);

    final means     = List<double>.filled(strips, 0);
    final variances = List<double>.filled(strips, 0);

    for (int s = 0; s < strips; s++) {
      final yStart = s * stripH;
      final yEnd   = math.min(yStart + stripH, h);
      double sum = 0, sumSq = 0;
      int count = 0;
      for (int y = yStart; y < yEnd; y += 2) {
        for (int x = 0; x < w; x += 3) {
          final offset = (y * w + x) * 4;
          if (offset + 2 >= _pixels.lengthInBytes) continue;
          final r = _pixels.getUint8(offset);
          final g = _pixels.getUint8(offset + 1);
          final b = _pixels.getUint8(offset + 2);
          final lum = 0.299 * r + 0.587 * g + 0.114 * b;
          sum   += lum;
          sumSq += lum * lum;
          count++;
        }
      }
      if (count == 0) continue;
      means[s]     = sum / count;
      variances[s] = (sumSq / count) - (means[s] * means[s]);
    }

    // Pick the highest-variance strip among non-bright strips.
    // Bright/white areas (mean >= 180) are label panels — skip them.
    // Solid black areas have near-zero variance — naturally score low.
    double bestScore = 0;
    int bestStrip = -1;
    for (int s = 0; s < strips; s++) {
      if (means[s] >= 180) continue;
      final score = variances[s];
      debugPrint('[OCR-Elec] Strip $s: mean=${means[s].toStringAsFixed(1)} '
          'var=${variances[s].toStringAsFixed(0)}');
      if (score > bestScore) { bestScore = score; bestStrip = s; }
    }

    if (bestStrip == -1 || bestScore < 400) {
      debugPrint('[OCR-Elec] findDisplayWindow: no dark high-contrast band found');
      return null;
    }

    // Grow to neighbouring strips that are also dark + high-contrast.
    final threshold = bestScore * 0.20;
    int top = bestStrip, bottom = bestStrip;
    while (top > 0 && variances[top - 1] >= threshold && means[top - 1] < 180) { top--; }
    while (bottom < strips - 1 && variances[bottom + 1] >= threshold && means[bottom + 1] < 180) { bottom++; }
    top    = math.max(0, top - 1);            // one-strip padding
    bottom = math.min(strips - 1, bottom + 1);

    final topPx    = top * stripH;
    final bottomPx = math.min((bottom + 1) * stripH, h);
    debugPrint('[OCR-Elec] Display window strips $top–$bottom  '
        'score=${bestScore.toStringAsFixed(0)}');

    // Convert from scaled-image coordinates back to original image coordinates.
    return ui.Rect.fromLTRB(
      0,
      topPx / _scaleY,
      w / _scaleX,
      bottomPx / _scaleY,
    );
  }

  void dispose() => _image.dispose();
}
