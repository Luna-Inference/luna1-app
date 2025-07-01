import 'package:shared_preferences/shared_preferences.dart';
import 'package:v1/config.dart';

/// Key used for storing the IP address in shared preferences
const String _ipAddressKey = 'llm_ip';

/// Updates or adds the IP address to shared preferences
/// 
/// Returns a [Future<bool>] that completes with true if the operation was
/// successful, false otherwise.
/// Also updates the AppConfig.llmIp value for immediate use.
Future<bool> updateIpAddress(String ipAddress) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Update the AppConfig value for immediate use
    AppConfig.llmIp = ipAddress;
    return await prefs.setString(_ipAddressKey, ipAddress);
  } catch (e) {
    print('Error saving IP address: $e');
    return false;
  }
}

/// Reads the stored IP address from shared preferences
/// 
/// Returns a [Future<String?>] that completes with the stored IP address,
/// or null if no IP address is stored or an error occurs.
/// The default value is AppConfig.llmIp if no value is stored.
Future<String?> readIpAddress() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ipAddressKey) ?? AppConfig.llmIp;
  } catch (e) {
    print('Error reading IP address: $e');
    return AppConfig.llmIp;
  }
}
