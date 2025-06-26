import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // For desktop, we want a more constrained and centered layout.
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Luna AI Suite',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: GridView.count(
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 32,
                mainAxisSpacing: 32,
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
                  /*_NavigationCard(
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
                    icon: Icons.pending,
                    title: 'Task',
                    routeName: '/task',
                  ),*/
                  _NavigationCard(
                    icon: Icons.pending,
                    title: 'Agent',
                    routeName: '/agent',
                  ),
                ],
              ),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, widget.routeName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: _isHovered ? 20 : 10,
                offset: _isHovered ? const Offset(0, 10) : const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 50,
                color: _isHovered
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isHovered
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
