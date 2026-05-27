import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

class SettingsService {
  static const _keyOnboardingDone = 'onboarding_done';

  Future<int> getMeterIntDigits() async {
    final s = await AppDatabase.instance.getSettings();
    if (s?.meterIntDigits != null) return s!.meterIntDigits!;
    // Migrate from SharedPreferences if present
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('meter_int_digits') ?? 5;
  }

  Future<void> setMeterIntDigits(int digits) async {
    await AppDatabase.instance.saveMeterIntDigits(digits);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }
}
