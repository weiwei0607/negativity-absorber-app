import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const String _pinKey = 'app_pin';
  static const String _enabledKey = 'pin_enabled';

  // WARNING: This is simple base64 obfuscation, not cryptographically secure.
  // For production-grade security, use a proper hashing library (e.g., crypto
  // package with sha256) and store only the hash + salt.
  static String _obfuscate(String pin) => base64Encode(utf8.encode(pin));
  static String? _deobfuscate(String? stored) {
    if (stored == null) return null;
    try {
      return utf8.decode(base64Decode(stored));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  static Future<bool> validatePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    return _deobfuscate(stored) == pin;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _obfuscate(pin));
    await prefs.setBool(_enabledKey, true);
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_enabledKey, false);
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}
