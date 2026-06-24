import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

class SettingsService {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyRegistrationPending = 'registration_pending';

  Future<int> getMeterIntDigits() async {
    final s = await AppDatabase.instance.getSettings();
    if (s?.meterIntDigits != null) return s!.meterIntDigits!;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('meter_int_digits') ?? 5;
  }

  Future<void> setMeterIntDigits(int digits) async {
    await AppDatabase.instance.saveMeterIntDigits(digits);
  }

  Future<int> getMeterDecDigits() async {
    final s = await AppDatabase.instance.getSettings();
    return s?.meterDecDigits ?? 3;
  }

  Future<void> setMeterDecDigits(int digits) async {
    await AppDatabase.instance.saveMeterDecDigits(digits);
  }

  Future<int> getElectricityIntDigits() async {
    final s = await AppDatabase.instance.getSettings();
    return s?.electricityIntDigits ?? 6;
  }

  Future<void> setElectricityIntDigits(int digits) async {
    await AppDatabase.instance.saveElectricityIntDigits(digits);
  }

  Future<int> getElectricityDecDigits() async {
    final s = await AppDatabase.instance.getSettings();
    // Default 1: most roller electricity meters show 1 decimal digit.
    return s?.electricityDecDigits ?? 1;
  }

  Future<void> setElectricityDecDigits(int digits) async {
    await AppDatabase.instance.saveElectricityDecDigits(digits);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingDone);
  }

  Future<bool> isRegistrationPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRegistrationPending) ?? false;
  }

  Future<void> setRegistrationPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRegistrationPending, true);
  }

  Future<void> clearRegistrationPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRegistrationPending);
  }

  Future<String> getTrackingMode() async {
    final s = await AppDatabase.instance.getSettings();
    if (s?.trackingMode != null) return s!.trackingMode!;
    // Fallback: SharedPreferences (set during onboarding before DB write)
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tracking_mode') ?? 'both';
  }

  Future<void> setTrackingMode(String mode) async {
    await AppDatabase.instance.saveTrackingMode(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracking_mode', mode);
  }
}
