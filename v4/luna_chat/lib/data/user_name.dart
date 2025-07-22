import 'package:shared_preferences/shared_preferences.dart';

const String _userNameKey = 'user_name';

/// Saves or updates the user's name in SharedPreferences.
/// Returns true if the operation was successful, false otherwise.
Future<bool> saveUserName(String name) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_userNameKey, name);
  } catch (e) {
    print('Error saving user name: $e');
    return false;
  }
}

/// Retrieves the user's name from SharedPreferences.
/// Returns the user's name if found, or an empty string if not found or an error occurs.
Future<String> getUserName() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '';
  } catch (e) {
    print('Error getting user name: $e');
    return '';
  }
}