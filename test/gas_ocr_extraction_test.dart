// Testet alle 4 Passes der Gas-OCR-Logik.
// Elster BK-G4M, Zählerstand 15211,543 m³, intDigits=5, decDigits=3

import 'package:flutter_test/flutter_test.dart';

// --- Kopie der privaten Logik aus ocr_service.dart ---

String norm(String s) => s
    .replaceAll(RegExp(r'[ilI|]'), '1')
    .replaceAll(RegExp(r'[oO]'), '0');

bool hasUnit(String t) {
  final l = t.toLowerCase();
  return l.contains('m³') || RegExp(r'm\s*3').hasMatch(l);
}

String? elecExtract(String lineText, int intDigits, int decDigits) {
  final normalized = norm(lineText);
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

String? simulateGasOcr(List<String> lines, int intDigits, int decDigits) {
  // Pass 1: unit line + enough digits
  for (final line in lines) {
    if (!hasUnit(line)) continue;
    final c = elecExtract(norm(line), intDigits, decDigits);
    if (c != null) return c;
  }

  // Pass 2: unit line ±2 neighbours combined (only digit-containing lines)
  final hasDigit = RegExp(r'\d');
  for (int i = 0; i < lines.length; i++) {
    if (!hasUnit(lines[i])) continue;
    final s = (i - 2).clamp(0, lines.length - 1);
    final e = (i + 2).clamp(0, lines.length - 1);
    final band = lines
        .sublist(s, e + 1)
        .where((l) => hasDigit.hasMatch(l) || hasUnit(l))
        .map(norm)
        .join(' ');
    final c = elecExtract(band, intDigits, decDigits);
    if (c != null) return c;
  }

  // Pass 3: comma/dot pattern in joined text
  final joined = lines.map(norm).join(' ');
  final sepRe = RegExp(
    r'(?<![,.\d])(\d(?:\s*\d){' '${intDigits - 1}' r'})\s*[,.]\s*'
    r'(\d(?:\s*\d){' '${decDigits - 1}' r'})(?!\s*\d)',
  );
  final sepM = sepRe.firstMatch(joined);
  if (sepM != null) {
    final intStr = sepM.group(1)!.replaceAll(RegExp(r'\s'), '');
    final decStr = sepM.group(2)!.replaceAll(RegExp(r'\s'), '');
    final intVal = int.tryParse(intStr) ?? 0;
    return '$intVal.$decStr';
  }

  // Pass 4: height-based, serial numbers excluded (no bounding box in test →
  // iterate in order; first valid non-serial line wins)
  final maxDigits = intDigits + decDigits + 2;
  for (final line in lines) {
    final d = norm(line).replaceAll(RegExp(r'[^\d]'), '');
    if (d.length > maxDigits) continue;
    final c = elecExtract(norm(line), intDigits, decDigits);
    if (c != null) return c;
  }

  return null;
}

void main() {
  const intDigits = 5;
  const decDigits = 3;
  const expected  = '15211.543';

  group('Gas-OCR Elster BK-G4M — 15211,543', () {

    test('1 (Pass 1): Ziffern + m3 auf einer Zeile — exakt wie Screenshot 020', () {
      final lines = [
        'BK-G4 M', 'SWM',
        '15 2 11.5 4 3 m3',   // echter ML-Kit-Output aus Screenshot 020
        '15', 'NG-4701BM0443 DIN EN 1359:2007',
        '002532352125',
      ];
      expect(simulateGasOcr(lines, intDigits, decDigits), expected);
    });

    test('2 (Pass 2): m3 steht allein auf eigener Zeile', () {
      final lines = [
        'elster',
        '1 5 2 1 1, 5 4 3',   // Ziffern ohne m3
        'm3',                   // m3 allein
        '002532352125',
      ];
      expect(simulateGasOcr(lines, intDigits, decDigits), expected);
    });

    test('3 (Pass 3): kein m3 erkannt, aber Komma sichtbar', () {
      // ML Kit erkennt m3 gar nicht — Komma-Pattern greift
      final lines = [
        'BK-G4 M', 'SWM',
        '1 5 2 1 1, 5 4 3',   // Komma vorhanden, kein m3
        '002532352125',
        'NG-4701BM0443',
      ];
      expect(simulateGasOcr(lines, intDigits, decDigits), expected);
    });

    test('4 (Pass 4): kein m3, kein Komma, Seriennummer MUSS ausgeschlossen werden', () {
      // Schlimmster Fall: kein Unit, kein Komma
      // Die Seriennummer (12 Ziffern > maxDigits=10) darf nicht gewählt werden
      final lines = [
        'BK-G4 M',
        '002532352125',         // 12 Ziffern → muss ausgeschlossen werden
        '15 2 1 1 5 4 3',       // 8 Ziffern ≤ 10 → wird verwendet
        'SWM',
      ];
      final result = simulateGasOcr(lines, intDigits, decDigits);
      expect(result, isNot('253.235'));     // alter Fehler darf nicht mehr auftreten
      expect(result, expected);
    });

    test('5 (Pass 1): m³ als Unicode-Zeichen auf selber Zeile', () {
      final lines = [
        'elster',
        '15211,543 m³',
        '002532352125',
      ];
      expect(simulateGasOcr(lines, intDigits, decDigits), expected);
    });

  });
}
