import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/settings_service.dart';
import '../services/weather_service.dart';
import '../theme/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _settingsService = SettingsService();
  final _pageController = PageController();
  final _plzController = TextEditingController();
  final _cityController = TextEditingController();

  int _selectedDigits = 5;
  int _currentPage = 0;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _plzController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish({bool skipLocation = false}) async {
    setState(() => _saving = true);
    await _settingsService.setMeterIntDigits(_selectedDigits);

    if (!skipLocation) {
      final plz = _plzController.text.trim();
      final city = _cityController.text.trim();
      if (plz.isNotEmpty || city.isNotEmpty) {
        // Save PLZ + city immediately; geocode in background
        await AppDatabase.instance.saveLocation(plz: plz, city: city);
        _geocodeInBackground(city, plz);
      }
    }

    await _settingsService.setOnboardingDone();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  void _geocodeInBackground(String city, String plz) async {
    final coords = await WeatherService().geocode(city, plz);
    if (coords != null) {
      final settings = await AppDatabase.instance.getSettings();
      if (settings != null) {
        await AppDatabase.instance
            .saveCoordinates(settings.id, coords.lat, coords.lon);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  _ProgressDot(active: _currentPage >= 0),
                  const SizedBox(width: 6),
                  _ProgressDot(active: _currentPage >= 1),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _MeterTypePage(
                    selectedDigits: _selectedDigits,
                    onSelect: (d) => setState(() => _selectedDigits = d),
                  ),
                  _LocationPage(
                    plzController: _plzController,
                    cityController: _cityController,
                  ),
                ],
              ),
            ),

            // Bottom button(s)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: _currentPage == 0
                  ? _ActionButton(
                      label: 'WEITER',
                      isBusy: false,
                      onTap: _nextPage,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          label: 'LOSLEGEN',
                          isBusy: _saving,
                          onTap: _saving ? null : () => _finish(),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _saving ? null : () => _finish(skipLocation: true),
                          child: Text(
                            'Überspringen — Standort später in Einstellungen eingeben',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.rajdhani(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 — Meter type
// ---------------------------------------------------------------------------

class _MeterTypePage extends StatelessWidget {
  final int selectedDigits;
  final ValueChanged<int> onSelect;

  const _MeterTypePage({
    required this.selectedDigits,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOMERGY',
            style: GoogleFonts.spaceMono(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.amber,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'EINRICHTUNG  ·  SCHRITT 1 VON 2',
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          Text(
            'WIE VIELE STELLEN HAT DER\nVORKOMMA-BEREICH DEINES ZÄHLERS?',
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diese Einstellung hilft der OCR-Erkennung, den Zählerstand korrekt aufzuteilen. Du kannst sie später in den Einstellungen ändern.',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          _MeterTypeCard(
            intDigits: 4,
            exampleInt: '1234',
            exampleDec: '567',
            isSelected: selectedDigits == 4,
            onTap: () => onSelect(4),
          ),
          const SizedBox(height: 12),
          _MeterTypeCard(
            intDigits: 5,
            exampleInt: '15154',
            exampleDec: '888',
            isSelected: selectedDigits == 5,
            onTap: () => onSelect(5),
          ),
          const SizedBox(height: 12),
          _MeterTypeCard(
            intDigits: 6,
            exampleInt: '123456',
            exampleDec: '789',
            isSelected: selectedDigits == 6,
            onTap: () => onSelect(6),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 — Location
// ---------------------------------------------------------------------------

class _LocationPage extends StatelessWidget {
  final TextEditingController plzController;
  final TextEditingController cityController;

  const _LocationPage({
    required this.plzController,
    required this.cityController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOMERGY',
            style: GoogleFonts.spaceMono(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.amber,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'EINRICHTUNG  ·  SCHRITT 2 VON 2',
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          Text(
            'STANDORT FÜR WETTERDATEN',
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.amber.withOpacity(0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.thermostat_rounded,
                    size: 18, color: AppColors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gib deine Postleitzahl und deinen Wohnort ein — dann können wir dir Temperaturdaten zur Korrelation mit deinem Gasverbrauch anzeigen. Heizkosten hängen direkt von der Außentemperatur ab.',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Postleitzahl',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          _OnboardingTextField(
            controller: plzController,
            hint: 'z.B. 80331',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          Text(
            'Wohnort',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          _OnboardingTextField(
            controller: cityController,
            hint: 'z.B. München',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 8),
          Text(
            'Optional — kann jederzeit in den Einstellungen geändert werden.',
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isBusy;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress dot
// ---------------------------------------------------------------------------

class _ProgressDot extends StatelessWidget {
  final bool active;
  const _ProgressDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.amber : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding text field
// ---------------------------------------------------------------------------

class _OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _OnboardingTextField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withOpacity(0.3), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.rajdhani(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.amber,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: GoogleFonts.rajdhani(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meter type card (unchanged from original)
// ---------------------------------------------------------------------------

class _MeterTypeCard extends StatelessWidget {
  final int intDigits;
  final String exampleInt;
  final String exampleDec;
  final bool isSelected;
  final VoidCallback onTap;

  const _MeterTypeCard({
    required this.intDigits,
    required this.exampleInt,
    required this.exampleDec,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amber.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.amber : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.amber : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? AppColors.amber : AppColors.textSecondary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$intDigits Vorkomma-Stellen',
                  style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? AppColors.amber : AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _MiniDisplay(
                  intDigits: intDigits,
                  exampleInt: exampleInt,
                  exampleDec: exampleDec,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDisplay extends StatelessWidget {
  final int intDigits;
  final String exampleInt;
  final String exampleDec;

  const _MiniDisplay({
    required this.intDigits,
    required this.exampleInt,
    required this.exampleDec,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < intDigits; i++) ...[
          _DigitBox(char: exampleInt[i], isDecimal: false),
          if (i < intDigits - 1) const SizedBox(width: 2),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ',',
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        for (int i = 0; i < 3; i++) ...[
          _DigitBox(char: exampleDec[i], isDecimal: true),
          if (i < 2) const SizedBox(width: 2),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            'm³',
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DigitBox extends StatelessWidget {
  final String char;
  final bool isDecimal;

  const _DigitBox({required this.char, required this.isDecimal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 24,
      decoration: BoxDecoration(
        color: isDecimal ? const Color(0xFF2A1A1A) : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDecimal
              ? const Color(0xFF8B2020).withOpacity(0.6)
              : AppColors.amber.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDecimal ? const Color(0xFFFF6B6B) : AppColors.amber,
          ),
        ),
      ),
    );
  }
}
