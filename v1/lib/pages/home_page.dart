import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../persistent_data/app_list.dart';
import '../widgets/setting_appbar.dart';
import '../main.dart' show routeObserver;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, RouteAware {
  List<LunaApp> _installedApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInstalledApps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInstalledApps();
    }
  }

  // Called when the top route has been popped off, and the current route shows up
  @override
  void didPopNext() {
    // Refresh the app list when returning to this page
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final apps = await getInstalledApps();
      
      if (mounted) {
        setState(() {
          _installedApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading apps: $e')),
        );
      }
    }
  }

  void _uninstallApp(LunaApp app) async {
    // Don't allow uninstalling App Store
    if (app.title == 'App Store') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App Store cannot be uninstalled')),
      );
      return;
    }
    
    // Show confirmation dialog
    final shouldUninstall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Uninstall ${app.title}?'),
        content: Text('Are you sure you want to uninstall ${app.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('UNINSTALL'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldUninstall) {
      setState(() {
        _isLoading = true;
      });
      
      final success = await uninstallApp(app.title);
      
      if (success) {
        await _loadInstalledApps();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${app.title} uninstalled')),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to uninstall ${app.title}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: const SettingAppBar(
        title: 'Luna AI Suite',
        //showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadInstalledApps,
                          child: _installedApps.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No apps installed. Visit the App Store to install apps.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Show message when only App Store is installed
                                    if (_installedApps.length == 1 && 
                                        _installedApps.first.title == 'App Store')
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16.0),
                                        child: Center(
                                          child: Text(
                                            'Welcome to Luna! Use the App Store to install more apps.',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: GridView.count(
                                        crossAxisCount: isDesktop ? 4 : 2,
                                        crossAxisSpacing: 24,
                                        mainAxisSpacing: 24,
                                        children: _buildAppGridItems(),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Helper method to build app grid items with App Store always last
  List<Widget> _buildAppGridItems() {
    // Sort apps to ensure App Store is last
    final sortedApps = List<LunaApp>.from(_installedApps);
    
    // Find and remove App Store
    final appStoreIndex = sortedApps.indexWhere((app) => app.title == 'App Store');
    LunaApp? appStore;
    
    if (appStoreIndex != -1) {
      appStore = sortedApps.removeAt(appStoreIndex);
    }
    
    // Build list of app widgets
    final appWidgets = sortedApps.map((app) {
      return _NavigationCard(
        icon: app.icon,
        title: app.title,
        routeName: app.routeName,
        isExperimental: app.isExperimental,
        onUninstall: () => _uninstallApp(app),
      );
    }).toList();
    
    // Add App Store at the end if it exists
    if (appStore != null) {
      appWidgets.add(_NavigationCard(
        icon: appStore.icon,
        title: appStore.title,
        routeName: appStore.routeName,
        isExperimental: appStore.isExperimental,
        // App Store cannot be uninstalled, so no uninstall callback
        onUninstall: null,
      ));
    }
    
    return appWidgets;
  }
}

class _NavigationCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String routeName;
  final bool isExperimental;
  final VoidCallback? onUninstall;

  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.routeName,
    required this.isExperimental,
    this.onUninstall,
  });

  @override
  State<_NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<_NavigationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardColor = _isHovered
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainer;

    final contentColor =
        _isHovered ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push(widget.routeName),
        onSecondaryTap: widget.onUninstall != null 
            ? () => _showUninstallMenu(context)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.outline.withOpacity(0.5)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: _isHovered
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
              const SizedBox(height: 4), // Spacing between title and tag
              if (widget.isExperimental)
                Text(
                  'Experimental',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showUninstallMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'uninstall',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Uninstall ${widget.title}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'uninstall' && widget.onUninstall != null) {
        widget.onUninstall!();
      }
    });
  }
}