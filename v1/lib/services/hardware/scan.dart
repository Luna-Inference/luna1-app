// Goal: Scan & detect luna device on a network

// Flow: Given Luna on the same network as user. First, scan for all device ip address and do an api call as below to detect
/*
Endpoint: /luna
Method: GET
Description: Used for device recognition among all devices on the network. Returns a simple JSON object indicating the device type.
Request Body: None
Response (JSON):
{
    "device": "luna"
}
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Scans the local network for Luna devices.
///
/// A Luna device is detected by sending an HTTP GET request to
/// `http://<ip>:<port>/luna` and expecting a JSON `{"device":"luna"}`
/// response. All sub-nets of the host machine (first three octets) are
/// scanned. If no interface is discovered (e.g. emulator), we fall back to
/// the common `192.168.0.*` and `192.168.1.*` ranges.
///
/// The scan is performed concurrently and will finish once every IP in the
/// range has been probed or the requests have timed-out.
///
/// Returns a list of IP addresses where a Luna device was detected.
/// Holds the results of a network scan.
class ScanResult {
  /// All IP addresses that were probed (i.e. every host in the detected sub-nets).
  final List<String> allIps;

  /// IP addresses that responded positively as Luna devices.
  final List<String> lunaIps;

  const ScanResult({required this.allIps, required this.lunaIps});
}

/// Scans the local network and returns both the list of every IP that was
/// probed and the subset that identify themselves as Luna devices. This keeps
/// the existing [scanForLunaDevices] helper (which only returns Luna devices)
/// intact for backwards-compatibility.
Future<ScanResult> scanForLunaDevicesWithAllIps({
  int port = 8080,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final Set<String> subnets = <String>{};

  // Discover sub-nets from the active network interfaces.
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length == 4) {
          subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    }
  } catch (_) {
    // ignore errors – fall back to default ranges below
  }

  // If no subnets are discovered, print an error and exit gracefully.
  if (subnets.isEmpty) {
    print('No active network interfaces found. Cannot scan for devices.');
    return const ScanResult(allIps: [], lunaIps: []);
  }

  final List<String> allIps = [];
  for (final subnet in subnets) {
    for (int host = 1; host < 255; host++) {
      allIps.add('$subnet.$host');
    }
  }

  print('Scanning for devices on the network...');

  final activeIps = <String>[];
  final discoveryTasks = <Future<void>>[];
  for (final ip in allIps) {
    discoveryTasks.add(_isReachable(ip, port, timeout).then((isReachable) {
      if (isReachable) {
        activeIps.add(ip);
      }
    }));
  }
  await Future.wait(discoveryTasks);

  print('Found active devices on port $port:');
  activeIps.sort((a, b) => a.compareTo(b)); // Sort for consistent output
  for (final ip in activeIps) {
    print('- $ip');
  }

  final lunaIps = <String>[];
  if (activeIps.isNotEmpty) {
    print('Checking which of these are Luna devices...');
    final lunaCheckTasks = <Future<void>>[];
    for (final ip in activeIps) {
      lunaCheckTasks.add(_probeIp(ip, port, timeout).then((isLuna) {
        if (isLuna) {
          lunaIps.add(ip);
        }
      }));
    }
    await Future.wait(lunaCheckTasks);
  }

  print('Scan complete.');
  if (lunaIps.isNotEmpty) {
    print('Found ${lunaIps.length} Luna device(s):');
    for (final ip in lunaIps) {
      print('- $ip');
    }
  } else {
    print('No Luna devices were found on the network.');
  }

  return ScanResult(allIps: allIps, lunaIps: lunaIps);
}

/// Scans the local network for Luna devices only.
///
/// A Luna device is detected by sending an HTTP GET request to
/// `http://<ip>:<port>/luna` and expecting a JSON `{"device":"luna"}`
/// response.
Future<List<String>> scanForLunaDevices({
  int port = 1306,
  Duration timeout = const Duration(seconds: 1),
}) async {
  final result = await scanForLunaDevicesWithAllIps(port: port, timeout: timeout);
  return result.lunaIps;
}

/// Returns `true` if a host is reachable on a given port by attempting a socket connection.
Future<bool> _isReachable(String ip, int port, Duration timeout) async {
  try {
    final socket = await Socket.connect(ip, port, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {
    // This will catch SocketException and TimeoutException, indicating the host is not reachable on that port.
    return false;
  }
}

/// Returns `true` if the given [ip] responds as a Luna device.
Future<bool> _probeIp(String ip, int port, Duration timeout) async {
  final uri = Uri.parse('http://$ip:$port/luna');
  print('  - Probing $ip...');
  try {
    final response = await http.get(uri).timeout(timeout);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is Map && body['device'] == 'luna') {
        print('    ... $ip is a Luna device!');
        return true;
      }
    }
  } catch (e) {
    // Swallow timeouts and socket errors, but log that the probe failed.
    print('    ... $ip did not respond as a Luna device ($e)');
  }
  return false;
}
