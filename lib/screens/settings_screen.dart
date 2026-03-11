import 'package:flutter/material.dart';

/// SettingsScreen - Screen for app settings and user preferences
/// Users can customize app behavior and appearance from here
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Page title
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Description of what settings are available
          const Text(
            'Configure app preferences and options',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),

          // Settings list with multiple options
          Column(
            children: [
              // Font Size setting
              ListTile(
                title: const Text('Font Size'),
                subtitle: const Text('Adjust text size for readability'),
                onTap: () {
                  // Show notification when tapped
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Font size settings coming soon!'),
                    ),
                  );
                },
              ),

              // Theme/Appearance setting
              ListTile(
                title: const Text('Theme'),
                subtitle: const Text('Customize app appearance'),
                onTap: () {
                  // Show notification when tapped
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme settings coming soon!'),
                    ),
                  );
                },
              ),

              // About section
              ListTile(
                title: const Text('About'),
                subtitle: const Text('App version and credits'),
                onTap: () {
                  // Show app version when tapped
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Version 1.0.0')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
