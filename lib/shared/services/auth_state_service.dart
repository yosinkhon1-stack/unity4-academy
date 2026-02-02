import 'package:shared_preferences/shared_preferences.dart';

class AuthStateService {
  static const String _keyRole = 'user_role';
  static const String _keyId = 'user_id';
  static const String _keyName = 'user_name';

  static Future<void> saveSession({required String role, required String id, String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyId, id);
    if (name != null) {
      await prefs.setString(_keyName, name);
    }
  }

  static Future<Map<String, String?>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_keyRole);
    final id = prefs.getString(_keyId);
    final name = prefs.getString(_keyName);
    
    if (role != null && id != null) {
      return {'role': role, 'id': id, 'name': name};
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
