import 'package:flutter/material.dart';
import 'package:v1/services/tools.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final TextEditingController _controller = TextEditingController();
  // Email controllers
  final TextEditingController _emailReceiverController = TextEditingController();
  final TextEditingController _emailBodyController = TextEditingController();
  String _result = '';
  String _emailStatus = '';
  bool _loading = false;
  bool _sending = false;

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
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWebSearchSection(),
            ),
          ),
                    const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildEmailSection(),
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
          child: _loading
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
      await sendEmail(recipient: receiver, subject: 'Message from Luna Dashboard', body: body);
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
          child: _sending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send Email'),
        ),
        const SizedBox(height: 8),
        if (_emailStatus.isNotEmpty) Text(_emailStatus),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailReceiverController.dispose();
    _emailBodyController.dispose();
    super.dispose();
  }
}
