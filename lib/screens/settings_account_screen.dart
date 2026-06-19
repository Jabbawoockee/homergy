import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../theme/colors.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _emailController = TextEditingController();
  bool _isSendingLink = false;
  bool _linkSent      = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    SupabaseService.client.auth.refreshSession().catchError((e) => throw e);
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        if (data.event == AuthChangeEvent.userUpdated) _linkSent = false;
      });
      if ((data.event == AuthChangeEvent.userUpdated ||
              data.event == AuthChangeEvent.signedIn) &&
          !SupabaseService.isAnonymous) {
        SyncService().syncAll();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Bitte eine gültige E-Mail-Adresse eingeben.', isError: true);
      return;
    }
    setState(() => _isSendingLink = true);
    try {
      await SupabaseService.signInWithMagicLink(email);
      if (mounted) setState(() { _isSendingLink = false; _linkSent = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingLink = false);
        _showSnack('Fehler: $e', isError: true);
      }
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    await AppDatabase.instance.clearAllUserData();
    final settings = SettingsService();
    await settings.resetOnboarding();
    await settings.clearRegistrationPending();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? AppColors.error : AppColors.green,
      content: Text(msg, style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isAnon = SupabaseService.isAnonymous;
    final email  = SupabaseService.userEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('USERDATEN', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 4)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(isAnon ? Icons.person_outline : Icons.verified_user_outlined, size: 16,
                      color: isAnon ? AppColors.textSecondary : AppColors.green),
                  const SizedBox(width: 8),
                  Text(isAnon ? 'Anonym' : email ?? 'Verknüpft',
                      style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w600,
                          color: isAnon ? AppColors.textSecondary : AppColors.green)),
                ]),
                const SizedBox(height: 6),
                Text(
                  isAnon
                      ? 'Melde dich mit deinem Homergy-Konto an oder erstelle ein neues — deine Daten werden automatisch geladen.'
                      : 'Deine Ablesungen werden mit der Cloud synchronisiert.',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.8), height: 1.4),
                ),
                const SizedBox(height: 20),

                if (isAnon && !_linkSent) ...[
                  Text('E-Mail-Adresse', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textPrimary),
                      cursorColor: AppColors.green,
                      decoration: InputDecoration(
                        hintText: 'E-Mail-Adresse eingeben',
                        hintStyle: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                        filled: true, fillColor: const Color(0xFFDFE5DA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    label: 'ANMELDELINK SENDEN',
                    isBusy: _isSendingLink,
                    color: AppColors.green,
                    onTap: _sendLink,
                  ),
                ],

                if (isAnon && _linkSent) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.mark_email_read_outlined, size: 16, color: AppColors.green),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'Bestätigungs-E-Mail gesendet. Bitte prüfe dein Postfach und klicke den Link.',
                        style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.green, height: 1.4),
                      )),
                    ]),
                  ),
                ],

                if (!isAnon) ...[
                  const SizedBox(height: 8),
                  _ActionButton(
                    label: 'ABMELDEN',
                    isBusy: false,
                    color: AppColors.error,
                    onTap: _signOut,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isBusy;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.isBusy, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Center(child: isBusy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5))),
      ),
    );
  }
}
