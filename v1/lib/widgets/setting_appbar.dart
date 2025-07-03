import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:v1/services/llm.dart';

class SettingAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const SettingAppBar({super.key, required this.title});

  @override
  _SettingAppBarState createState() => _SettingAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SettingAppBarState extends State<SettingAppBar> {
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
      title: Text(
        widget.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
      actions: [
        if (_serverHealth != null)
          Row(
            children: [
              Icon(Icons.speed, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Prefill: ${_serverHealth!.prefillSpeedTps} tps',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(width: 12),
              Text(
                'Generate: ${_serverHealth!.generationSpeedTps} tps',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(width: 12),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.push('/network'),
        ),
      ],
    );
  }
}
