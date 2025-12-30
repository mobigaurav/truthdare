import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _kIsPremium = 'is_premium';

  Future<bool> getIsPremium() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kIsPremium) ?? false;
  }

  Future<void> setIsPremium(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kIsPremium, value);
  }
}
