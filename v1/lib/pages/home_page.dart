import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // For desktop, we want a more constrained and centered layout.
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Luna AI Suite',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 24,
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
              Colors.grey[100]!,
              Colors.grey[300]!,
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
                  _NavigationCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Vision',
                    routeName: '/vision',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
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
                color: _isHovered ? Colors.blueAccent : Colors.black54,
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isHovered ? Colors.blueAccent : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
