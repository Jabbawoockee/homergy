import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database.dart';
import '../services/ocr_service.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';
import '../theme/colors.dart';

enum _ScanStep { pickImage, confirm }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _ocrService = OcrService();
  final _picker = ImagePicker();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  final _editFocusNode = FocusNode();
  final _db = AppDatabase.instance;
  final _settingsService = SettingsService();

  _ScanStep _step = _ScanStep.pickImage;
  String? _imagePath;
  bool _isProcessing = false;
  bool _isSaving = false;
  bool _isManualEntry = false;
  bool _isEditing = false;
  String? _ocrRawHint;
  int _meterIntDigits = 5;
  double? _lastReading;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final digits = await _settingsService.getMeterIntDigits();
    final latest = await _db.getLatestReading();
    if (mounted) {
      setState(() {
        _meterIntDigits = digits;
        _lastReading = latest?.value;
      });
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image picking
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      setState(() {
        _imagePath = picked.path;
        _step = _ScanStep.confirm;
        _isEditing = false;
        _isManualEntry = false;
        _isProcessing = true;
        _valueController.text = '';
        _ocrRawHint = null;
      });

      final result = await _ocrService.extractMeterReadingWithRaw(
        picked.path,
        intDigits: _meterIntDigits,
        lastReading: _lastReading,
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _valueController.text = result.reading ?? '';
          _ocrRawHint = result.reading == null && result.rawText.isNotEmpty
              ? 'Erkannt: "${result.rawText}"'
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Bild konnte nicht geladen werden: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final text = _valueController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(text);
    if (parsed == null) {
      _showError('Bitte einen gültigen Zählerstand eingeben.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _db.insertReading(
        MeterReadingsCompanion(
          value: Value(parsed),
          timestamp: Value(DateTime.now()),
          note: Value(_noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim()),
          imagePath: Value(_imagePath),
        ),
      );

      // Fire-and-forget background sync.
      SyncService().syncAll();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.green,
            content: Text(
              'Zählerstand ${parsed.toStringAsFixed(2)} m³ gespeichert.',
              style: GoogleFonts.rajdhani(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Fehler beim Speichern: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(msg,
            style: GoogleFonts.rajdhani(
                fontSize: 15, fontWeight: FontWeight.w600)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _resetToPickStep() {
    setState(() {
      _step = _ScanStep.pickImage;
      _imagePath = null;
      _isManualEntry = false;
      _isEditing = false;
      _valueController.text = '';
      _noteController.text = '';
      _isProcessing = false;
      _ocrRawHint = null;
    });
  }

  void _startManualEntry() {
    setState(() {
      _step = _ScanStep.confirm;
      _imagePath = null;
      _isManualEntry = true;
      _isEditing = true;
      _isProcessing = false;
      _valueController.text = '';
      _noteController.text = '';
      _ocrRawHint = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    String title;
    if (_step == _ScanStep.pickImage) {
      title = 'ABLESEN';
    } else if (_isManualEntry) {
      title = 'MANUELL EINGEBEN';
    } else if (_isEditing) {
      title = 'ANPASSEN';
    } else {
      title = 'BESTÄTIGEN';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () {
            // If editing after OCR, go back to review mode instead of leaving
            if (_isEditing && !_isManualEntry) {
              setState(() => _isEditing = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.amber,
            letterSpacing: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _step == _ScanStep.pickImage
              ? _buildPickStep()
              : (_isEditing ? _buildEditMode() : _buildReviewMode()),
        ),
      ),
    );
  }

  // ── Step 1: Pick image ──────────────────────────────────────────────────────

  Widget _buildPickStep() {
    return SingleChildScrollView(
      key: const ValueKey('pick'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Foto des Gaszählers aufnehmen oder aus der Galerie wählen.',
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          _PickButton(
            icon: Icons.photo_camera_outlined,
            label: 'FOTO AUFNEHMEN',
            sublabel: 'Kamera öffnen',
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _PickButton(
            icon: Icons.photo_library_outlined,
            label: 'AUS GALERIE WÄHLEN',
            sublabel: 'Vorhandenes Bild',
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          _PickButton(
            icon: Icons.edit_outlined,
            label: 'MANUELL EINGEBEN',
            sublabel: 'Zählerstand direkt eintippen',
            onPressed: _startManualEntry,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.amber.withOpacity(0.25), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wb_incandescent_outlined,
                    color: AppColors.amber, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Für beste Erkennung auf ausreichende Beleuchtung achten oder Blitz einschalten.',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      color: AppColors.amber,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Opacity(
              opacity: 0.06,
              child: Icon(Icons.speed, size: 100, color: AppColors.amber),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2a: Review mode (OCR result, read-only) ────────────────────────────

  Widget _buildReviewMode() {
    final hasValue = _valueController.text.isNotEmpty;

    return SingleChildScrollView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo preview with OCR overlay
          if (_imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(
                    File(_imagePath!),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (_isProcessing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.amber, strokeWidth: 2),
                              SizedBox(height: 12),
                              Text('Texterkennung läuft…',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Label
          Text(
            'ERKANNTER ZÄHLERSTAND',
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),

          // Read-only value display
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasValue
                    ? AppColors.amber.withOpacity(0.6)
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: hasValue
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_valueController.text}  m³',
                      style: GoogleFonts.spaceMono(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                    ),
                  )
                : Text(
                    _isProcessing
                        ? '…'
                        : 'Nicht erkannt — bitte anpassen',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),

          // OCR raw hint
          if (_ocrRawHint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.amber.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.amber, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ocrRawHint!,
                      style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          color: AppColors.amber,
                          letterSpacing: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Primary button: ÜBERNEHMEN
          _ActionButton(
            label: 'ÜBERNEHMEN',
            icon: Icons.check_rounded,
            color: AppColors.amber,
            textColor: Colors.black,
            isLoading: _isSaving,
            onPressed: _isProcessing || _isSaving || !hasValue
                ? null
                : _save,
          ),
          const SizedBox(height: 12),

          // Secondary row: NOCHMAL | ANPASSEN
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'NOCHMAL',
                  icon: Icons.refresh_rounded,
                  color: AppColors.surface,
                  textColor: AppColors.textPrimary,
                  isLoading: false,
                  borderColor: AppColors.border,
                  onPressed:
                      _isProcessing || _isSaving ? null : _resetToPickStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'ANPASSEN',
                  icon: Icons.edit_rounded,
                  color: AppColors.surface,
                  textColor: AppColors.amber,
                  isLoading: false,
                  borderColor: AppColors.amber.withOpacity(0.4),
                  onPressed:
                      _isProcessing || _isSaving ? null : _startEditing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 2b: Edit mode (manual input with keyboard) ─────────────────────────

  Widget _buildEditMode() {
    return SingleChildScrollView(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Smaller photo preview (only for photo scans)
          if (_imagePath != null && !_isManualEntry) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_imagePath!),
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Label
          Text(
            'ZÄHLERSTAND (m³)',
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),

          // Editable value field — auto-focused, keyboard opens
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.amber.withOpacity(0.6), width: 1),
            ),
            child: TextField(
              controller: _valueController,
              focusNode: _editFocusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.spaceMono(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
              decoration: InputDecoration(
                hintText: '00000.00',
                hintStyle: GoogleFonts.spaceMono(
                  fontSize: 32,
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                suffixText: 'm³',
                suffixStyle: GoogleFonts.rajdhani(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Note field
          Text(
            'NOTIZ (OPTIONAL)',
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: TextField(
              controller: _noteController,
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'z.B. Zählerstand nach Heizungscheck',
                hintStyle: GoogleFonts.rajdhani(
                  fontSize: 15,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Save
          _ActionButton(
            label: 'SPEICHERN',
            icon: Icons.check_rounded,
            color: AppColors.amber,
            textColor: Colors.black,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),

          // Back to review (only when editing an OCR result, not manual entry)
          if (!_isManualEntry) ...[
            const SizedBox(height: 12),
            _ActionButton(
              label: 'ZURÜCK',
              icon: Icons.arrow_back_rounded,
              color: AppColors.surface,
              textColor: AppColors.textPrimary,
              isLoading: false,
              borderColor: AppColors.border,
              onPressed: _isSaving
                  ? null
                  : () => setState(() => _isEditing = false),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onPressed;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.amber, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sublabel,
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary, size: 14),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final Color? borderColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.isLoading,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1.0,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : null,
            boxShadow: color == AppColors.amber
                ? [
                    BoxShadow(
                      color: AppColors.amber.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: textColor, strokeWidth: 2),
                )
              else
                Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
