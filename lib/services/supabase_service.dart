import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const _url = 'https://qeaubfgthytjfcgvckzw.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFlYXViZmd0aHl0amZjZ3Zja3p3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MzU4MzgsImV4cCI6MjA5NTExMTgzOH0'
      '.H8lJyT2KJHShxupxNd4Ilw8NyldkDPffwUP006BpNQk';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static bool get isAnonymous =>
      currentUser == null || (currentUser!.isAnonymous);

  static String? get userEmail => currentUser?.email;

  /// Signs in anonymously if no session exists.
  static Future<void> ensureSignedIn() async {
    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
      debugPrint('[Auth] Signed in anonymously: ${currentUser?.id}');
    } else {
      debugPrint('[Auth] Existing session: ${currentUser?.id} '
          '(anon=${currentUser?.isAnonymous})');
    }
  }

  /// Links an email to the current anonymous account.
  /// The user receives a confirmation link → after clicking, the account is promoted.
  static Future<void> linkEmail(String email) async {
    await client.auth.updateUser(UserAttributes(email: email));
  }

  /// Sends a magic-link for signing in on a new device.
  static Future<void> signInWithMagicLink(String email) async {
    await client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'homergy://auth-callback',
    );
  }

  /// Signs out completely (back to anonymous on next launch).
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
