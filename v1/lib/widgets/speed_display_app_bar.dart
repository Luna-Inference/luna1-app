import 'dart:async';
import 'package:flutter/material.dart';
import 'package:v1/services/llm.dart';

class SpeedDisplayAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const SpeedDisplayAppBar({super.key, required this.title});

  @override
  _SpeedDisplayAppBarState createState() => _SpeedDisplayAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SpeedDisplayAppBarState extends State<SpeedDisplayAppBar> {
  ServerHealth? _serverHealth;
  Timer? _healthTimer;
  final LlmService _llmService = LlmService();

  @override
  void initState() {
    super.initState();
    _fetchHealth();
    _healthTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchHealth());
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    super.dispose();
  }

  void _fetchHealth() async {
    if (!mounted) return;
    final health = await _llmService.fetchServerHealth();
    if (mounted) {
      setState(() {
        _serverHealth = health;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const Spacer(),
          if (_serverHealth != null)
            Row(
              children: [
                Icon(Icons.speed, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Input: ${_serverHealth!.promptEvalSpeedWps} wps',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(width: 12),
                Text(
                  'Output: ${_serverHealth!.generationSpeedWps} wps',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
