import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class MeterDisplay extends StatelessWidget {
  final double? value;

  const MeterDisplay({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: value == null ? _buildDashes() : _buildValue(),
      ),
    );
  }

  Widget _buildValue() {
    final formatted = value!.toStringAsFixed(3);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '000';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          intPart,
          style: GoogleFonts.spaceMono(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: AppColors.amber,
            letterSpacing: 3,
          ),
        ),
        Text(
          '.',
          style: GoogleFonts.spaceMono(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: AppColors.amber.withOpacity(0.7),
          ),
        ),
        Text(
          decPart,
          style: GoogleFonts.spaceMono(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.amber.withOpacity(0.6),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'm³',
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashes() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '------.',
          style: GoogleFonts.spaceMono(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary.withOpacity(0.3),
            letterSpacing: 3,
          ),
        ),
        Text(
          '---',
          style: GoogleFonts.spaceMono(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary.withOpacity(0.2),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'm³',
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withOpacity(0.3),
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
