import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class SettingsSectionLabel extends StatelessWidget {
  final String label;
  const SettingsSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 3));
}

class SettingsFieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const SettingsFieldLabel(this.label, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
    if (required) ...[const SizedBox(width: 4), Text('*', style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.error, fontWeight: FontWeight.w700))],
  ]);
}

class SettingsContractPreview extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final DateTime since;
  final double price;
  const SettingsContractPreview({super.key, required this.icon, required this.color, required this.name, required this.since, required this.price});

  @override
  Widget build(BuildContext context) {
    final d = since;
    final dateStr = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
          Text('seit $dateStr  ·  ${price.toStringAsFixed(4)} €/kWh',
              style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class SettingsDatePicker extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  final Color accentColor;
  const SettingsDatePicker({super.key, required this.date, required this.onTap, this.accentColor = AppColors.green});

  @override
  Widget build(BuildContext context) {
    final d = date;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: d == null ? AppColors.textSecondary : accentColor),
          const SizedBox(width: 12),
          Text(
            d == null ? 'Datum auswählen' : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}',
            style: d == null
                ? GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textSecondary)
                : GoogleFonts.spaceMono(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

class SettingsDigitSelector extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String description;
  final int selected;
  final List<int> options;
  final String Function(int) formatHint;
  final void Function(int) onSelect;
  final Color accentColor;

  const SettingsDigitSelector({super.key, required this.icon, required this.iconColor, required this.description, required this.selected, required this.options, required this.formatHint, required this.onSelect, this.accentColor = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 16, color: iconColor), const SizedBox(width: 8),
            Text('Vorkomma-Stellen', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5))]),
          const SizedBox(height: 6),
          Text(description, style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.8), height: 1.4)),
          const SizedBox(height: 16),
          Row(children: [
            for (int i = 0; i < options.length; i++) ...[
              Expanded(child: GestureDetector(
                onTap: () => onSelect(options[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected == options[i] ? accentColor : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected == options[i]
                        ? [BoxShadow(color: accentColor.withValues(alpha: 0.55), offset: const Offset(0, 3), blurRadius: 6)]
                        : AppColors.neu(4),
                  ),
                  child: Center(child: Text('${options[i]}', style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w700,
                      color: selected == options[i] ? Colors.white : AppColors.textSecondary))),
                ),
              )),
              if (i < options.length - 1) const SizedBox(width: 10),
            ],
          ]),
          const SizedBox(height: 12),
          Text('Aktuell: $selected Stellen — Format: ${formatHint(selected)}',
              style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class SettingsToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  const SettingsToggleChip({super.key, required this.label, required this.selected, required this.onTap, this.accentColor = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accentColor : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [BoxShadow(color: accentColor.withValues(alpha: 0.55), offset: const Offset(0, 2), blurRadius: 5)]
              : AppColors.neu(3),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class SettingsPriceField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix, hint;
  final Color accentColor;
  const SettingsPriceField({super.key, required this.controller, required this.suffix, required this.hint, this.accentColor = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.spaceMono(fontSize: 16, color: AppColors.textPrimary),
        cursorColor: accentColor,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: hint, hintStyle: GoogleFonts.spaceMono(fontSize: 14, color: AppColors.textSecondary),
          suffixText: suffix.isNotEmpty ? suffix : null,
          suffixStyle: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accentColor;
  const SettingsTextField({super.key, required this.controller, required this.hint, this.accentColor = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        style: GoogleFonts.rajdhani(fontSize: 16, color: AppColors.textPrimary),
        cursorColor: accentColor,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: hint, hintStyle: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class SettingsSaveButton extends StatelessWidget {
  final String label;
  final bool isBusy;
  final VoidCallback onTap;
  final Color accentColor;
  const SettingsSaveButton({super.key, required this.label, required this.isBusy, required this.onTap, this.accentColor = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.55), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(child: isBusy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5))),
      ),
    );
  }
}
