import 'package:flutter/material.dart';
import 'package:v1/widgets/hotspot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v1/services/hardware/scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v1/services/hardware/scan.dart';

class FullSetupPage extends StatefulWidget {
  const FullSetupPage({super.key});

  @override
  State<FullSetupPage> createState() => _FullSetupPageState();
}

class _FullSetupPageState extends State<FullSetupPage> {
  final PageController _pageController = PageController();

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luna Setup'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: [
          _HotspotSetupPage(onNext: _nextPage),
          _HardwareSetupPage(onNext: _nextPage),
          _LunaScanSetupPage(onNext: _nextPage),
          _EmailSetupPage(),
        ],
      ),
    );
  }
}

class _HotspotSetupPage extends StatefulWidget {
  final VoidCallback onNext;
  const _HotspotSetupPage({required this.onNext});

  @override
  State<_HotspotSetupPage> createState() => _HotspotSetupPageState();
}

class _HotspotSetupPageState extends State<_HotspotSetupPage> {
  bool _hotspotOpened = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Click the button below to open your device\'s hotspot settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          HotspotSettingsButton(
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _hotspotOpened ? widget.onNext : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _HardwareSetupPage extends StatefulWidget {
  final VoidCallback onNext;
  const _HardwareSetupPage({required this.onNext});

  @override
  State<_HardwareSetupPage> createState() => _HardwareSetupPageState();
}

class _HardwareSetupPageState extends State<_HardwareSetupPage> {
  bool _nextButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _nextButtonEnabled = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Plug your Luna into power'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _nextButtonEnabled ? widget.onNext : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _LunaScanSetupPage extends StatefulWidget {
  final VoidCallback onNext;
  const _LunaScanSetupPage({required this.onNext});

  @override
  State<_LunaScanSetupPage> createState() => _LunaScanSetupPageState();
}

class _LunaScanSetupPageState extends State<_LunaScanSetupPage> {
  List<String> _lunaDevices = [];
  bool _isScanning = false;
  String? _selectedIpAddress;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _lunaDevices = [];
      _selectedIpAddress = null;
    });

    final devices = await scanForLunaDevices();

    setState(() {
      _lunaDevices = devices;
      _isScanning = false;
    });
  }

  Future<void> _saveIpAddress(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('luna_ip_address', ipAddress);
    setState(() {
      _selectedIpAddress = ipAddress;
    });
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
                ..._lunaDevices.map((ip) =>
                  ListTile(
                    title: Text(ip),
                    trailing: _selectedIpAddress == ip
                        ? const Icon(Icons.check)
                        : ElevatedButton(
                            onPressed: () => _saveIpAddress(ip),
                            child: const Text('Select'),
                          ),
                  ),
                ).toList(),
              ],
            ),
          const SizedBox(height: 20),
          if (!_isScanning && _lunaDevices.isNotEmpty)
            ElevatedButton(
              onPressed: _selectedIpAddress != null ? widget.onNext : null,
              child: const Text('Next'),
            ),
        ],
      ),
    );
  }
}

class _EmailSetupPage extends StatelessWidget {
  const _EmailSetupPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Email Setup Page'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }
}