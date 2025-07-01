import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App model class to represent each app in the store/home page
class LunaApp {
  final String title;
  final IconData icon;
  final String routeName;
  final bool isExperimental;
  final bool isInstalled;

  LunaApp({
    required this.title,
    required this.icon,
    required this.routeName,
    this.isExperimental = false,
    this.isInstalled = false,
  });

  // Convert app to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'routeName': routeName,
      'isExperimental': isExperimental,
      'isInstalled': isInstalled,
    };
  }

  // Create app from JSON
  factory LunaApp.fromJson(Map<String, dynamic> json) {
    return LunaApp(
      title: json['title'],
      icon: IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
        fontPackage: json['iconFontPackage'],
      ),
      routeName: json['routeName'],
      isExperimental: json['isExperimental'] ?? false,
      isInstalled: json['isInstalled'] ?? false,
    );
  }

  // Create a copy of the app with modified properties
  LunaApp copyWith({
    String? title,
    IconData? icon,
    String? routeName,
    bool? isExperimental,
    bool? isInstalled,
  }) {
    return LunaApp(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      routeName: routeName ?? this.routeName,
      isExperimental: isExperimental ?? this.isExperimental,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }
}

// Default apps available in the app store
List<LunaApp> getDefaultApps() {
  return [
    LunaApp(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      routeName: '/dashboard',
      isExperimental: true,
    ),
    LunaApp(
      icon: Icons.chat_bubble_outline,
      title: 'Chat',
      routeName: '/chat',
      isExperimental: false,
    ),
    LunaApp(
      icon: Icons.mic_none,
      title: 'Voice',
      routeName: '/voice',
      isExperimental: true,
    ),
    LunaApp(
      icon: Icons.smart_toy_outlined,
      title: 'Agent',
      routeName: '/agent',
      isExperimental: false,
    ),
    LunaApp(
      icon: Icons.network_check,
      title: 'Network',
      routeName: '/network',
      isExperimental: false,
    ),
    LunaApp(
      icon: Icons.horizontal_split,
      title: 'Hotspot',
      routeName: '/hotspot-setup',
      isExperimental: false,
    ),
    LunaApp(
      icon: Icons.horizontal_split,
      title: 'Hardware Setup',
      routeName: '/hardware-setup',
      isExperimental: false,
    ),
    LunaApp(
      icon: Icons.scanner,
      title: 'Luna Scan',
      routeName: '/luna-scan',
      isExperimental: false,
    ),
    LunaApp(
      icon: Icons.email,
      title: 'Email Setup',
      routeName: '/email-setup',
      isExperimental: false,
    ),
    LunaApp(
      icon: Icons.apps,
      title: 'App Store',
      routeName: '/app-store',
      isExperimental: false,
    ),
  ];
}

// Key for storing installed apps in shared preferences
const String _installedAppsKey = 'installed_apps';

// Get all installed apps from shared preferences
Future<List<LunaApp>> getInstalledApps() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList(_installedAppsKey);
    
    if (appsJson == null || appsJson.isEmpty) {
      // Return a default set of installed apps if none are saved
      final defaultInstalledApps = [
        'Chat',
        'Agent',
        'Network',
        'App Store',
      ];
      
      final allApps = getDefaultApps();
      final initialInstalledApps = allApps
          .where((app) => defaultInstalledApps.contains(app.title))
          .map((app) => app.copyWith(isInstalled: true))
          .toList();
      
      // Save these default apps
      await saveInstalledApps(initialInstalledApps);
      return initialInstalledApps;
    }
    
    // Convert JSON strings back to LunaApp objects
    final apps = appsJson
        .map((jsonStr) => LunaApp.fromJson(json.decode(jsonStr)))
        .toList();
    
    // Ensure App Store is always included in the installed apps list
    final appStore = getDefaultApps().firstWhere((app) => app.title == 'App Store');
    if (!apps.any((app) => app.title == 'App Store')) {
      apps.add(appStore.copyWith(isInstalled: true));
      await saveInstalledApps(apps);
    }
    
    return apps;
  } catch (e) {
    print('Error getting installed apps: $e');
    return [];
  }
}

// Save the list of installed apps to shared preferences
Future<bool> saveInstalledApps(List<LunaApp> apps) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = apps.map((app) => json.encode(app.toJson())).toList();
    return await prefs.setStringList(_installedAppsKey, appsJson);
  } catch (e) {
    print('Error saving installed apps: $e');
    return false;
  }
}

// Install an app (add to installed apps list)
Future<bool> installApp(LunaApp app) async {
  try {
    final installedApps = await getInstalledApps();
    
    // Check if app is already installed
    if (installedApps.any((installedApp) => installedApp.title == app.title)) {
      return true; // App is already installed
    }
    
    // Add the app with isInstalled set to true
    installedApps.add(app.copyWith(isInstalled: true));
    return await saveInstalledApps(installedApps);
  } catch (e) {
    print('Error installing app: $e');
    return false;
  }
}

// Uninstall an app (remove from installed apps list)
Future<bool> uninstallApp(String appTitle) async {
  try {
    // Don't allow uninstalling the App Store
    if (appTitle == 'App Store') {
      return false;
    }
    
    final installedApps = await getInstalledApps();
    
    // Remove the app with the matching title
    final updatedApps = installedApps
        .where((app) => app.title != appTitle)
        .toList();
    
    return await saveInstalledApps(updatedApps);
  } catch (e) {
    print('Error uninstalling app: $e');
    return false;
  }
}

// Check if an app is installed
Future<bool> isAppInstalled(String appTitle) async {
  final installedApps = await getInstalledApps();
  return installedApps.any((app) => app.title == appTitle);
}

// Get all available apps for the app store (both installed and not installed)
Future<List<LunaApp>> getAllAppsWithInstallStatus() async {
  final defaultApps = getDefaultApps();
  final installedApps = await getInstalledApps();
  
  // Mark apps as installed based on the installed apps list
  return defaultApps.map((app) {
    final isInstalled = installedApps.any((installedApp) => 
        installedApp.title == app.title);
    return app.copyWith(isInstalled: isInstalled);
  }).toList();
}