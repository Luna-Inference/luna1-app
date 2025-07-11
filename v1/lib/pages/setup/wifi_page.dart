import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v1/config.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({Key? key}) : super(key: key);

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;

  Future<String> _getBaseUrl() async {
    // Retrieve the IP address that was discovered & stored during hardware setup.
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('llm_ip');
    return (savedIp ?? AppConfig.llmIp).replaceAll(RegExp(r"/+ ?"), '');
  }

  Future<void> _connectToWifi() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    if (ssid.isEmpty || password.isEmpty) {
      setState(() => _statusMessage = 'SSID and password cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('http://$baseUrl:1306/wifi');
      final response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'uuid': ssid, 'password': password}))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final success = body['success'] == true;
        setState(() => _statusMessage =
            success ? 'Connected to $ssid successfully!' : 'Connection failed: ${body['stderr'] ?? 'Unknown error'}');
      } else {
        setState(() => _statusMessage =
            'Server error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi Setup')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ssidController,
                decoration: const InputDecoration(
                  labelText: 'SSID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _connectToWifi,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Connect'),
                    ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 24),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.toLowerCase().contains('success')
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}