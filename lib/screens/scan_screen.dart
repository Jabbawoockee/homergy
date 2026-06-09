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
  final MeterType meterType;
  const ScanScreen({super.key, this.meterType = MeterType.gas});

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

  static const _blue = Color(0xFF5B8DB8);
  bool get _isElec => widget.meterType == MeterType.electricity;
  Color get _accentColor => _isElec ? _blue : AppColors.green;
  Color get _highlightColor => _isElec ? _blue : AppColors.amber;
  int _meterDecDigits = 1;
  double? _lastReading;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isElec = widget.meterType == MeterType.electricity;
    int digits;
    int decDigits = 1;
    double? lastValue;
    if (isElec) {
      digits = await _settingsService.getElectricityIntDigits();
      decDigits = await _settingsService.getElectricityDecDigits();
      lastValue = (await _db.getLatestElectricityReading())?.value;
    } else {
      digits = await _settingsService.getMeterIntDigits();
      lastValue = (await _db.getLatestReading())?.value;
    }
    if (mounted) {
      setState(() {
        _meterIntDigits = digits;
        _meterDecDigits = decDigits;
        _lastReading = lastValue;
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

      final OcrResult result;
      if (widget.meterType == MeterType.electricity) {
        result = await _ocrService.extractElectricityReading(
          picked.path,
          intDigits: _meterIntDigits,
          decDigits: _meterDecDigits,
        );
      } else {
        result = await _ocrService.extractMeterReadingWithRaw(
          picked.path,
          meterType: MeterType.gas,
          intDigits: _meterIntDigits,
          lastReading: _lastReading,
        );
      }
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _valueController.text = result.reading ?? '';
          if (result.reading == null && result.rawText.isNotEmpty) {
            _ocrRawHint = 'Erkannt: "${result.rawText}"';
          } else {
            _ocrRawHint = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Bild konnte nicht geladen werden: $e');
      }
    }
  }

  String get _unit => widget.meterType == MeterType.gas ? 'm³' : 'kWh';

  Future<void> _save() async {
    final text = _valueController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(text);
    if (parsed == null) {
      _showError('Bitte einen gültigen Zählerstand eingeben.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final note = Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim());
      if (widget.meterType == MeterType.gas) {
        await _db.insertReading(MeterReadingsCompanion(
          value: Value(parsed),
          timestamp: Value(DateTime.now()),
          note: note,
          imagePath: Value(_imagePath),
        ));
      } else {
        await _db.insertElectricityReading(ElectricityReadingsCompanion(
          value: Value(parsed),
          timestamp: Value(DateTime.now()),
          note: note,
          imagePath: Value(_imagePath),
        ));
      }

      SyncService().syncAll();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _accentColor,
            content: Text(
              'Zählerstand ${parsed.toStringAsFixed(2)} $_unit gespeichert.',
              style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
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
            color: _accentColor,
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

  Widget _buildPickStep() {
    return SingleChildScrollView(
      key: const ValueKey('pick'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.meterType == MeterType.gas
                ? 'Foto des Gaszählers aufnehmen oder aus der Galerie wählen.'
                : 'Foto des Stromzählers aufnehmen oder aus der Galerie wählen.',
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
            accentColor: _highlightColor,
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _PickButton(
            icon: Icons.photo_library_outlined,
            label: 'AUS GALERIE WÄHLEN',
            sublabel: 'Vorhandenes Bild',
            accentColor: _highlightColor,
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          _PickButton(
            icon: Icons.edit_outlined,
            label: 'MANUELL EINGEBEN',
            sublabel: 'Zählerstand direkt eintippen',
            accentColor: _highlightColor,
            onPressed: _startManualEntry,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wb_incandescent_outlined,
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
              opacity: 0.08,
              child: Icon(_isElec ? Icons.bolt : Icons.speed, size: 100, color: _accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewMode() {
    final hasValue = _valueController.text.isNotEmpty;

    return SingleChildScrollView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: _highlightColor, strokeWidth: 2),
                              const SizedBox(height: 12),
                              const Text('Texterkennung läuft…',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 24),

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

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.neu(5),
            ),
            child: hasValue
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_valueController.text}  $_unit',
                      style: GoogleFonts.spaceMono(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: _highlightColor,
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

          if (_ocrRawHint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _highlightColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _highlightColor, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ocrRawHint!,
                      style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          color: _highlightColor,
                          letterSpacing: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          _ActionButton(
            label: 'ÜBERNEHMEN',
            icon: Icons.check_rounded,
            isPrimary: true,
            isLoading: _isSaving,
            accentColor: _accentColor,
            onPressed: _isProcessing || _isSaving || !hasValue ? null : _save,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'NOCHMAL',
                  icon: Icons.refresh_rounded,
                  isPrimary: false,
                  isLoading: false,
                  accentColor: _accentColor,
                  onPressed: _isProcessing || _isSaving ? null : _resetToPickStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'ANPASSEN',
                  icon: Icons.edit_rounded,
                  isPrimary: false,
                  isLoading: false,
                  accentColor: _accentColor,
                  onPressed: _isProcessing || _isSaving ? null : _startEditing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          Text(
            'ZÄHLERSTAND ($_unit)',
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
              color: const Color(0xFFDFE5DA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _valueController,
              focusNode: _editFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.spaceMono(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: _highlightColor,
              ),
              cursorColor: _accentColor,
              decoration: InputDecoration(
                hintText: '00000.00',
                hintStyle: GoogleFonts.spaceMono(
                  fontSize: 32,
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                suffixText: _unit,
                suffixStyle: GoogleFonts.rajdhani(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

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
              color: const Color(0xFFDFE5DA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _noteController,
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              cursorColor: _accentColor,
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

          _ActionButton(
            label: 'SPEICHERN',
            icon: Icons.check_rounded,
            isPrimary: true,
            isLoading: _isSaving,
            accentColor: _accentColor,
            onPressed: _isSaving ? null : _save,
          ),

          if (!_isManualEntry) ...[
            const SizedBox(height: 12),
            _ActionButton(
              label: 'ZURÜCK',
              icon: Icons.arrow_back_rounded,
              isPrimary: false,
              isLoading: false,
              accentColor: _accentColor,
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
  final Color accentColor;
  final VoidCallback onPressed;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onPressed,
    this.accentColor = AppColors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.neu(5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
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
            Icon(Icons.arrow_forward_ios,
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
  final bool isPrimary;
  final bool isLoading;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isLoading,
    required this.onPressed,
    this.accentColor = AppColors.green,
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
            color: isPrimary ? accentColor : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.45),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ]
                : AppColors.neu(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: isPrimary ? Colors.white : accentColor,
                      strokeWidth: 2),
                )
              else
                Icon(icon,
                    color: isPrimary ? Colors.white : AppColors.textSecondary,
                    size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
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
