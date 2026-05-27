import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String? reading;
  final String rawText;
  const OcrResult({this.reading, required this.rawText});
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
  Future<String?> extractMeterReading(String imagePath,
      {int intDigits = 5}) async {
    final result = await extractMeterReadingWithRaw(imagePath,
        intDigits: intDigits);
    return result.reading;
  }

  Future<OcrResult> extractMeterReadingWithRaw(
    String imagePath, {
    int intDigits = 5,
    double? lastReading,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await recognizer.processImage(inputImage);

      final allLines = recognizedText.blocks.expand((b) => b.lines).toList();
      final rawText = allLines.map((l) => l.text).join(' | ');
      debugPrint('[OCR] Lines: $rawText');

      // Load scaled image for background brightness analysis.
      // Dark background = black roller display (what we want).
      // Bright background = white spec label (what we want to ignore).
      final brightnessSampler = await _BrightnessSampler.load(imagePath, allLines);

      final candidates = <_Candidate>[];

      for (final line in allLines) {
        final box = line.boundingBox;
        final area = box.width * box.height;
        final result = _tryExtractWithPriority(line.text, intDigits);
        if (result != null) {
          final brightness = brightnessSampler?.sample(box) ?? 128.0;
          final brightnessBonus = _brightnessBonus(brightness);
          final score = result.priority * 1000000.0 + area + brightnessBonus;
          debugPrint(
              '[OCR] Candidate: "${line.text}" → ${result.value}  pri=${result.priority}  '
              'area=${area.toStringAsFixed(0)}  bri=${brightness.toStringAsFixed(0)}  bonus=${brightnessBonus.toStringAsFixed(0)}');
          candidates.add(_Candidate(
              value: result.value, score: score, sourceText: line.text));
        }
      }

      // Adjacent line pairs (integer + decimal in separate sections).
      for (int i = 0; i < allLines.length - 1; i++) {
        final combined =
            '${allLines[i].text.trim()} ${allLines[i + 1].text.trim()}';
        final result = _tryExtractWithPriority(combined, intDigits);
        if (result != null) {
          final areaA = allLines[i].boundingBox.width *
              allLines[i].boundingBox.height;
          final areaB = allLines[i + 1].boundingBox.width *
              allLines[i + 1].boundingBox.height;
          final area = areaA + areaB;
          // Use the combined bounding box for brightness
          final combinedBox = allLines[i].boundingBox
              .expandToInclude(allLines[i + 1].boundingBox);
          final brightness =
              brightnessSampler?.sample(combinedBox) ?? 128.0;
          final brightnessBonus = _brightnessBonus(brightness);
          final score = result.priority * 1000000.0 + area + brightnessBonus;
          debugPrint(
              '[OCR] Pair: "$combined" → ${result.value}  pri=${result.priority}  '
              'bri=${brightness.toStringAsFixed(0)}  bonus=${brightnessBonus.toStringAsFixed(0)}');
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
                reading: _truncateTo2Decimals(best.value), rawText: rawText);
          }
          debugPrint(
              '[OCR] All candidates below lastReading=$lastReading, using score-based pick');
        }

        final best = candidates.first;
        debugPrint(
            '[OCR] Best: "${best.sourceText}" → ${best.value}  score=${best.score}');
        return OcrResult(
            reading: _truncateTo2Decimals(best.value), rawText: rawText);
      }

      final fullText = allLines.map((l) => l.text).join(' ');
      final fallback = _tryExtractWithPriority(fullText, intDigits);
      return OcrResult(
        reading: fallback != null ? _truncateTo2Decimals(fallback.value) : null,
        rawText: rawText,
      );
    } catch (e) {
      debugPrint('[OCR] Error: $e');
      return const OcrResult(rawText: '');
    } finally {
      await recognizer.close();
    }
  }

  /// Scoring bonus based on background brightness.
  /// Dark background (black roller display) → big positive bonus.
  /// Bright background (white label area) → negative penalty.
  double _brightnessBonus(double brightness) {
    if (brightness < 80) return 2000000.0;   // clearly dark = roller display
    if (brightness > 160) return -800000.0;  // clearly bright = spec label
    return 0.0;
  }

  /// Truncate to exactly 2 decimal places (drop 3rd decimal digit).
  String _truncateTo2Decimals(String value) {
    final dotIdx = value.indexOf('.');
    if (dotIdx == -1) return value;
    final end = (dotIdx + 3).clamp(0, value.length);
    return value.substring(0, end);
  }

  /// Normalize common OCR misreads of digits on roller/segment displays.
  String _normalizeDigits(String text) {
    var r = text.replaceAllMapped(RegExp(r'[Tl](?=[0-9])'), (_) => '1');
    r = r.replaceAllMapped(RegExp(r'(?<=[0-9])[Tl]'), (_) => '1');
    r = r.replaceAllMapped(RegExp(r'(?<![A-Za-z])O(?=[0-9])'), (_) => '0');
    return r;
  }

  _ExtractResult? _tryExtractWithPriority(String text, int intDigits) {
    final t = _normalizeDigits(text.replaceAll(RegExp(r'\s+'), ' ').trim());

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

      // Decode at a small target width to save memory and speed up sampling.
      const targetWidth = 320;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;

      // Estimate original image dimensions from ML Kit bounding boxes.
      double origW = 0, origH = 0;
      for (final line in allLines) {
        origW = math.max(origW, line.boundingBox.right);
        origH = math.max(origH, line.boundingBox.bottom);
      }
      if (origW < 1) origW = 1920;
      if (origH < 1) origH = 1080;

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

  void dispose() => _image.dispose();
}
