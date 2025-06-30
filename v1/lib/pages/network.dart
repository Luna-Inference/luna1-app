
import 'package:flutter/material.dart';
import '/services/hardware/scan.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isScanning = false;
  String _scanStatus = '';
  List<String> _lunaDevices = [];

  Future<void> _scanForLuna() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning for Luna devices...';
      _lunaDevices = [];
    });

    try {
      final result = await scanForLunaDevicesWithAllIps(port: 1306, timeout: const Duration(seconds: 10));
      setState(() {
        _lunaDevices = result.lunaIps;
        _scanStatus = 'Found ${_lunaDevices.length} Luna device(s).';
      });
    } catch (e) {
      setState(() {
        _scanStatus = 'Error during scan: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToWifi() async {
    if (_lunaDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Luna device found to connect to.')),
      );
      return;
    }

    final ssid = _ssidController.text;
    final password = _passwordController.text;

    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Wi-Fi name (SSID).')),
      );
      return;
    }

    // For simplicity, we'll try to connect to the first Luna device found.
    final lunaIp = _lunaDevices.first;
    final url = Uri.parse('http://$lunaIp:1306/wifi');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'uuid': ssid, 'password': password}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send connection request: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to Wi-Fi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isScanning ? null : _scanForLuna,
              child: Text(_isScanning ? 'Scanning...' : 'Scan for Luna Devices'),
            ),
            const SizedBox(height: 16),
            Text(_scanStatus, textAlign: TextAlign.center),
            if (_lunaDevices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Found Luna at: ${_lunaDevices.join(', ')}', textAlign: TextAlign.center),
              ),
            const SizedBox(height: 32),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: 'Wi-Fi Name (SSID)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Wi-Fi Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _connectToWifi,
              child: const Text('Connect to Wi-Fi'),
            ),
          ],
        ),
      ),
    );
  }
}
