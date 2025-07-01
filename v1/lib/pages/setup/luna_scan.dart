import 'package:flutter/material.dart';

import '../../services/hardware/scan.dart';

class LunaScanPage extends StatefulWidget {
  const LunaScanPage({super.key});

  @override
  State<LunaScanPage> createState() => _LunaScanPageState();
}

class _LunaScanPageState extends State<LunaScanPage> {
  List<String> _lunaDevices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _lunaDevices = [];
    });

    final devices = await scanForLunaDevices();

    setState(() {
      _lunaDevices = devices;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan for Luna Devices'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning)
              const CircularProgressIndicator()
            else if (_lunaDevices.isEmpty)
              const Text('No Luna devices found.')
            else
              Column(
                children: [
                  const Text('Found Luna devices:'),
                  ..._lunaDevices.map((ip) => Text(ip)).toList(),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isScanning ? null : _startScan,
              child: const Text('Scan Again'),
            ),
          ],
        ),
      ),
    );
  }
}
