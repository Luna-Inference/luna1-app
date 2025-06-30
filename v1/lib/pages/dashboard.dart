import 'package:flutter/material.dart';
import 'package:v1/services/tools.dart';
import 'dart:async';
import 'package:v1/widgets/speed_display_app_bar.dart';
import 'package:v1/services/hardware/bluetooth.dart' as bt;

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
  bool _loading = false;
  bool _sending = false;
  bool _isAddingNote = false;
  List<String> _bluetoothDevices = [];
  bool _scanning = false;

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
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SpeedDisplayAppBar(title: 'Dashboard'),
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
    } catch (e) {
      setState(() => _emailStatus = 'Error: $e');
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
    } catch (e) {
      // ignore: avoid_print
      print('Bluetooth scan error: $e');
    } finally {
      setState(() { _scanning = false; });
    }
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

  @override
  void dispose() {
    _controller.dispose();
    _emailReceiverController.dispose();
    _emailBodyController.dispose();
    _notionNoteController.dispose();
    super.dispose();
  }
}
