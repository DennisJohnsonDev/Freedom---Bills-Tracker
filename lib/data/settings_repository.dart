import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  Settings._(this._prefs);

  static const _kOnboarded = 'onboarded_v1';
  static const _kUserName = 'user_name';

  static Future<Settings> open() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings._(prefs);
  }

  final SharedPreferences _prefs;

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool v) async => _prefs.setBool(_kOnboarded, v);

  String? get userName => _prefs.getString(_kUserName);
  Future<void> setUserName(String name) =>
      _prefs.setString(_kUserName, name.trim());
}
