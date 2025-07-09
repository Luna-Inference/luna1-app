import 'package:flutter/material.dart';
import 'package:v1/services/tools.dart';
import 'dart:async';
import 'package:v1/widgets/setting_appbar.dart';
import 'package:v1/services/hardware/bluetooth.dart' as bt;
import 'package:v1/services/llm.dart';
import 'package:v1/services/hardware/scan.dart' as net;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  final TextEditingController _controller = TextEditingController();
  // Email controllers
  final TextEditingController _emailReceiverController =
      TextEditingController();
  final TextEditingController _emailBodyController = TextEditingController();
  // Notion controller
  final TextEditingController _notionNoteController = TextEditingController();

  String _result = '';
  String _emailStatus = '';
  String _notionStatus = '';
  String _emailSummary = ''; // New variable to store the email summary
  bool _loading = false;
  bool _sending = false;
  bool _isAddingNote = false;
  List<String> _bluetoothDevices = [];
  bool _scanning = false;
  // Network scan
  List<String> _lunaDevices = [];
  bool _networkScanning = false;
  // Email reading
  List<String> _emails = [];
  bool _fetchingEmails = false;

  void _showErrorSnack(String message) {
    // Use debugPrint so errors are also visible in console for deeper inspection
    debugPrint('Dashboard Error: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _performSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final res = await search(query);
      setState(() {
        _result = res;
      });
    } catch (e, stack) {
      debugPrint('Search error: $e\n$stack');
      setState(() {
        _result = 'Error: $e';
      });
      _showErrorSnack('Search failed: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SettingAppBar(title: 'Dashboard'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWebSearchSection(),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildEmailSection(),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildEmailReadSection(),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildNotionSection(),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildNetworkScanSection(),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBluetoothSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Web Search', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Query',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading ? null : _performSearch,
          child:
              _loading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Search'),
        ),
        const SizedBox(height: 12),
        if (_result.isNotEmpty) Text(_result),
      ],
    );
  }

  Future<void> _sendEmail() async {
    final receiver = _emailReceiverController.text.trim();
    final body = _emailBodyController.text;
    if (receiver.isEmpty || body.isEmpty) return;
    setState(() {
      _sending = true;
      _emailStatus = '';
    });
    try {
      await sendEmail(
        recipient: receiver,
        subject: 'Message from Luna Dashboard',
        body: body,
      );
      setState(() => _emailStatus = 'Email sent!');
    } catch (e, stack) {
      debugPrint('Send email error: $e\n$stack');
      setState(() => _emailStatus = 'Error: $e');
      _showErrorSnack('Failed to send email: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Send Email', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _emailReceiverController,
          decoration: const InputDecoration(
            labelText: 'Recipient Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailBodyController,
          decoration: const InputDecoration(
            labelText: 'Email Body',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _sending ? null : _sendEmail,
          child:
              _sending
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Send Email'),
        ),
        const SizedBox(height: 8),
        if (_emailStatus.isNotEmpty) Text(_emailStatus),
      ],
    );
  }

  Future<void> _addNoteToNotion() async {
    final content = _notionNoteController.text.trim();
    if (content.isEmpty) return;
    setState(() {
      _isAddingNote = true;
      _notionStatus = '';
    });
    try {
      final result = await addNote(content);
      setState(() {
        _notionStatus = result;
        _notionNoteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.green),
      );
    } catch (e) {
      final errorMessage = 'Error: $e';
      setState(() {
        _notionStatus = errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isAddingNote = false;
      });
    }
  }

  Widget _buildNotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Note to Notion',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notionNoteController,
          decoration: const InputDecoration(
            labelText: 'Note Content',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isAddingNote ? null : _addNoteToNotion,
          child:
              _isAddingNote
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Add Note'),
        ),
        const SizedBox(height: 8),
        if (_notionStatus.isNotEmpty && !_isAddingNote) Text(_notionStatus),
      ],
    );
  }

  Future<void> _scanBluetoothDevices() async {
    setState(() { _scanning = true; });
    try {
      final devices = await bt.scanNearbyDeviceIds();
      setState(() { _bluetoothDevices = devices; });
    } catch (e, stack) {
      debugPrint('Bluetooth scan error: $e\n$stack');
      _showErrorSnack('Bluetooth scan failed: $e');
    } finally {
      setState(() { _scanning = false; });
    }
  }

  Future<void> _scanNetworkDevices() async {
    setState(() { _networkScanning = true; });
    try {
      final devices = await net.scanForLunaDevices();
      setState(() { _lunaDevices = devices; });
    } catch (e, stack) {
      debugPrint('Network scan error: $e\n$stack');
      _showErrorSnack('Network scan failed: $e');
    } finally {
      setState(() { _networkScanning = false; });
    }
  }

  Widget _buildNetworkScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Network Scan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _networkScanning ? null : _scanNetworkDevices,
          child: _networkScanning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Scan Network'),
        ),
        const SizedBox(height: 12),
        for (final ip in _lunaDevices) Text(ip),
      ],
    );
  }

  Widget _buildBluetoothSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bluetooth Scan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _scanning ? null : _scanBluetoothDevices,
          child: _scanning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Scan Devices'),
        ),
        const SizedBox(height: 12),
        for (final id in _bluetoothDevices) Text(id),
      ],
    );
  }

  Future<void> _fetchEmails() async {
    setState(() {
      _fetchingEmails = true;
      _emails = [];
      _emailSummary = '';
    });
    try {
      final latest = await readLatestEmails();
      setState(() {
        _emails = latest;
      });
      
      // Generate summary using LLM service if emails were fetched successfully
      if (latest.isNotEmpty) {
        final LlmService llmService = LlmService();
        final String emailContent = latest.join('\n\n---\n\n');
        
        final messages = [
          {
            'role': 'system',
            'content': 'You are a helpful assistant that summarizes emails. Create a concise 2-paragraph summary of the provided emails. The first paragraph should cover the main topics and senders. The second paragraph should highlight any action items or important deadlines mentioned.'
          },
          {
            'role': 'user',
            'content': 'Please summarize these emails:\n\n$emailContent'
          }
        ];
        
        // Use the LLM service to generate the summary
        String summary = '';
        await for (final event in llmService.getAIResponse(messages)) {
          if (event.type == LlmStreamEventType.fullResponse) {
            summary = event.content;
            break;
          }
        }
        
        setState(() {
          _emailSummary = summary;
        });
      }
    } catch (e, stack) {
      debugPrint('Fetch emails error: $e\n$stack');
      final errorMsg = 'Failed to fetch emails: $e';
      setState(() {
        _emails = ['Error: $e'];
        _emailSummary = '';
      });
      _showErrorSnack(errorMsg);
    } finally {
      setState(() {
        _fetchingEmails = false;
      });
    }
  }

  Widget _buildEmailReadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Read Latest Emails', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _fetchingEmails ? null : _fetchEmails,
          child: _fetchingEmails
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Fetch 10 Latest Emails'),
        ),
        const SizedBox(height: 12),
        if (_emails.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _emails.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(_emails[index]),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        if (_emailSummary.isNotEmpty)
          Text('Summary:\n$_emailSummary'),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailReceiverController.dispose();
    _emailBodyController.dispose();
    _notionNoteController.dispose();
    super.dispose();
  }
}
