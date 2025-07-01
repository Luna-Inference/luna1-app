import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../persistent_data/app_list.dart';
import '../widgets/setting_appbar.dart';

class AppStore extends StatefulWidget {
  const AppStore({super.key});

  @override
  State<AppStore> createState() => _AppStoreState();
}

class _AppStoreState extends State<AppStore> {
  List<LunaApp> _availableApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    final apps = await getAllAppsWithInstallStatus();
    
    setState(() {
      _availableApps = apps;
      _isLoading = false;
    });
  }

  Future<void> _toggleAppInstallation(LunaApp app) async {
    setState(() {
      _isLoading = true;
    });

    bool success;
    if (app.isInstalled) {
      // Don't allow uninstalling App Store
      if (app.title == 'App Store') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App Store cannot be uninstalled')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      success = await uninstallApp(app.title);
    } else {
      success = await installApp(app);
    }

    if (success) {
      await _loadApps(); // Refresh the app list
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${app.isInstalled ? 'uninstall' : 'install'} ${app.title}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Luna App Store'),
        leading: IconButton(
            onPressed: () => context.push('/home'),

            icon: Icon(Icons.home)),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Available Apps',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: isDesktop ? 4 : 2,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          children: _availableApps.map((app) {
                            return _AppCard(
                              app: app,
                              onToggleInstallation: () => _toggleAppInstallation(app),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final LunaApp app;
  final VoidCallback onToggleInstallation;

  const _AppCard({
    required this.app,
    required this.onToggleInstallation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggleInstallation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                app.icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                app.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (app.isExperimental)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Experimental',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: onToggleInstallation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: app.isInstalled
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  foregroundColor: app.isInstalled
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
                child: Text(app.isInstalled ? 'Uninstall' : 'Install'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
