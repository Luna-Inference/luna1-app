import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:luna_chat/config.dart';

class LunaDevice {
  final String ip;

  LunaDevice({required this.ip});
}

class LunaScanner {
  static int get _port => int.parse(LunaPort.status);
  static const int _timeoutSeconds = 3;

  /// Check if Luna is available at its static IP address
  static Future<LunaDevice?> findLuna({
    int timeoutSeconds = _timeoutSeconds,
  }) async {
    print('Checking Luna at ${LunaPort.lunaIpAddress}:${_port}...');

    try {
      final response = await http
          .get(
            Uri.parse('http://${LunaPort.lunaIpAddress}:$_port/luna'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['device'] == 'luna') {
          print('Luna found at ${LunaPort.lunaIpAddress}');
          return LunaDevice(ip: LunaPort.lunaIpAddress);
        }
      }
    } catch (e) {
      print('Luna not reachable: $e');
    }

    print('Luna not found at ${LunaPort.lunaIpAddress}');
    return null;
  }

  /// Quick availability check (shorter timeout)
  static Future<bool> isLunaAvailable({int timeoutSeconds = 1}) async {
    final device = await findLuna(timeoutSeconds: timeoutSeconds);
    return device != null;
  }
}

// Usage examples:
/*
void main() async {
  print('Looking for Luna...');
  
  final luna = await LunaScanner.findLuna();
  
  if (luna != null) {
    print('Found Luna! Ready to connect.');
    // Make API calls to http://${LunaPort.lunaIpAddress}:${LunaPort.status}/your-endpoints
  } else {
    print('Luna not found. Check ethernet connection.');
  }
  
  // Or quick check
  final isAvailable = await LunaScanner.isLunaAvailable();
  print('Luna available: $isAvailable');
}
*/

// Usage examples:
/*
void main() async {
  print('Scanning for Luna device...');
  
  // Smart scan (recommended)
  final luna = await LunaScanner.findLunaSmart();
  if (luna != null) {
    print('Found Luna at: ${luna.ip}');
    // Make API calls to http://${luna.ip}:1309/
  } else {
    print('Luna device not found');
  }
  
  // Or just quick scan
  final quickLuna = await LunaScanner.findLunaQuick();
  
  // Or full network scan
  final fullLuna = await LunaScanner.findLuna();
}
*/
