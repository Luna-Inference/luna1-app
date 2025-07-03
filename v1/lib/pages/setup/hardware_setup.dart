import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../persistent_data/ip_address.dart';
import '../../services/hardware/scan.dart';
import '../../widgets/setting_appbar.dart';

class HardwareSetup extends StatefulWidget {
  const HardwareSetup({super.key});

  @override
  State<HardwareSetup> createState() => _HardwareSetupState();
}

class _HardwareSetupState extends State<HardwareSetup> {
  bool _isScanning = true;
  String _statusMessage = 'Scanning for Luna devices...';
  List<String> _foundDevices = [];
  bool _showDeviceList = false;
  bool _scanFailed = false;
  
  // List of additional IP addresses to scan
  final List<String> _additionalIpsToScan = [
    //'100.76.203.80',     // Known Luna backend server
    'luna.local',
    '10.10.0.1',
  ];

  @override
  void initState() {
    super.initState();
    // Start the scan process when the widget initializes
    _startScanProcess();
  }

  // Main scan process that follows the required logic
  Future<void> _startScanProcess() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for Luna devices...';
      _showDeviceList = false;
      _foundDevices = [];
      _scanFailed = false;
    });

    // Step 1: Try with existing IP address first
    final existingIp = await readIpAddress();
    if (existingIp != null) {
      setState(() {
        _statusMessage = 'Trying to connect to Luna...';
      });

      final isLuna = await _checkIfLuna(existingIp);
      if (isLuna) {
        // Successfully connected to Luna with existing IP
        _onSuccessfulConnection(existingIp);
        return;
      }
    }

    // Step 2: Try the additional IP addresses
    setState(() {
      _statusMessage = 'Checking known Luna IP addresses...';
    });

    for (final ip in _additionalIpsToScan) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Checking $ip...';
      });
      
      final isLuna = await _checkIfLuna(ip);
      if (isLuna) {
        _onSuccessfulConnection(ip);
        return;
      }
    }

    // Step 3: If existing IP and additional IPs don't work, scan the network
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Scanning network for Luna devices...';
    });

    final lunaDevices = await scanForLunaDevices(
      port: 1306,
      timeout: const Duration(seconds: 5),
    );

    if (!mounted) return;
    setState(() {
      _foundDevices = lunaDevices;
      _isScanning = false;
    });

    if (lunaDevices.isNotEmpty) {
      // Found Luna devices
      if (lunaDevices.length == 1) {
        // If only one device is found, connect to it automatically
        _onSuccessfulConnection(lunaDevices[0]);
      } else {
        // If multiple devices are found, show list for selection
        setState(() {
          _statusMessage = 'Multiple Luna devices found. Please select one:';
          _showDeviceList = true;
        });
      }
    } else {
      // No Luna devices found - show setup instructions
      setState(() {
        _statusMessage = 'No Luna devices found. Please follow the setup instructions below.';
        _scanFailed = true;
      });
    }
  }

  // Check if the given IP address is a Luna device
  Future<bool> _checkIfLuna(String ip) async {
    try {
      // Extract just the IP part if a full URL is provided
      final ipOnly = ip.replaceAll(RegExp(r'https?://'), '').split(':')[0];
      
      final uri = Uri.parse('http://$ipOnly:1306/luna');
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body is Map && body['device'] == 'luna';
      }
    } catch (e) {
      print('Error checking Luna at $ip: $e');
    }
    return false;
  }

  // Handle successful connection to a Luna device
  void _onSuccessfulConnection(String ip) async {
    // Save the IP address
    await updateIpAddress(ip);
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Connected to Luna! You can now proceed to the home page.';
      });
    }
  }

  // Select a specific Luna device from the list
  void _selectDevice(String ip) {
    _onSuccessfulConnection(ip);
  }

  @override
  Widget build(BuildContext context) {
    // Check if scan was successful (device found and connected)
    final bool scanSuccessful = _statusMessage.contains('Connected to Luna');
    
    return Scaffold(
      appBar: const SettingAppBar(title: 'Hardware Setup'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Luna Hardware Setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              if (_isScanning)
                const CircularProgressIndicator()
              else if (_showDeviceList && _foundDevices.isNotEmpty)
                SizedBox(
                  height: 300, // Fixed height for the list view
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _foundDevices.length,
                    itemBuilder: (context, index) {
                      final ip = _foundDevices[index];
                      return ListTile(
                        title: Text('Luna Device: $ip'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => _selectDevice(ip),
                      );
                    },
                  ),
                ),
              
              // Only show setup instructions if scan failed and no devices were found
              if (_scanFailed && _foundDevices.isEmpty) ...[
                const SizedBox(height: 20),
                const Text('Connect your Luna to your computer/desktop through an ethernet cable'),
                const Text('Power up Luna by plugging it to the adapter'),
                const SizedBox(height: 20),
                Image.asset('assets/setup/hardware-setup.png'),
              ],
              
              const SizedBox(height: 30),
              
              if (!_isScanning) 
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Only show "Scan Again" if scan was not successful
                    if (!scanSuccessful)
                      ElevatedButton(
                        onPressed: _startScanProcess,
                        child: const Text('Scan Again'),
                      ),
                    
                    // Only show spacing if both buttons are visible
                    if (!scanSuccessful && (_foundDevices.isNotEmpty || scanSuccessful))
                      const SizedBox(width: 20),
                    
                    // Only show the Go to Home button if we have found at least one device
                    if (_foundDevices.isNotEmpty || scanSuccessful)
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: const Text('Next'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
