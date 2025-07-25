import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:luna_chat/config.dart';

/// Checks the health status of the Luna device by making a request to its API.
/// Returns `true` if the device is online and responding correctly, `false` otherwise.
Future<bool> checkLunaHealth() async {
  try {
    final url = Uri.parse(
      'http://${LunaPort.lunaIpAddress}:${LunaPort.status}/luna',
    );
    final response = await http
        .get(url, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['device'] == 'luna';
    }
    return false;
  } catch (e) {
    // Handle any errors (timeout, network error, etc.)
    return false;
  }
}
