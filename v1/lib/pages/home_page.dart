import 'package:flutter/material.dart';
import 'dart:ui';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Luna AI Suite',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            child: GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: const <Widget>[
                _NavigationCard(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  routeName: '/dashboard',
                ),
                _NavigationCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat',
                  routeName: '/chat',
                ),
                _NavigationCard(
                  icon: Icons.mic_none,
                  title: 'Voice',
                  routeName: '/voice',
                ),
                _NavigationCard(
                  icon: Icons.smart_toy_outlined,
                  title: 'Agent',
                  routeName: '/agent',
                ),
                // You can add more cards here if needed
                /*
                _NavigationCard(
                  icon: Icons.camera_alt_outlined,
                  title: 'Vision',
                  routeName: '/vision',
                ),
                _NavigationCard(
                  icon: Icons.work_outline,
                  title: 'Intern',
                  routeName: '/intern',
                ),
                _NavigationCard(
                  icon: Icons.pending_actions_outlined,
                  title: 'Task',
                  routeName: '/task',
                ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationCard extends StatefulWidget {
  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.routeName,
  });

  final IconData icon;
  final String title;
  final String routeName;

  @override
  State<_NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<_NavigationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardColor =
        _isHovered
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainer;

    final contentColor =
        _isHovered ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, widget.routeName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _isHovered
                      ? colorScheme.outline.withOpacity(0.5)
                      : Colors.transparent,
              width: 1,
            ),
            boxShadow:
                _isHovered
                    ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.1),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(widget.icon, size: 48, color: contentColor),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
