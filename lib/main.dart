import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(1700, 900),
    size: Size(1700, 900),
    center: true,
    title: 'Church Presentation App',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ChurchPresentationApp());
}

class ChurchPresentationApp extends StatelessWidget {
  const ChurchPresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeNotifierWidget(
      child: MaterialApp(
        title: 'Church Presentation App',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TRADITIONAL MENU BAR (File, Edit, View, Settings, Help)
        Material(
          color: const Color.fromARGB(255, 37, 37, 37),
          child: Row(
            children: [
              _buildMenuBarItem(context, 'File', [
                'New',
                'Open',
                'Save',
                'Save As',
                'Exit',
              ]),
              _buildMenuBarItem(context, 'Edit', [
                'Undo',
                'Redo',
                'Cut',
                'Copy',
                'Paste',
              ]),
              _buildMenuBarItem(context, 'View', [
                'Zoom In',
                'Zoom Out',
                'Reset Zoom',
                'Fullscreen',
              ]),
              _buildMenuBarItem(context, 'Settings', [
                'Preferences',
                'Display Output',
                'Font Size',
                'Theme',
                'About',
              ]),
              _buildMenuBarItem(context, 'Help', [
                'Documentation',
                'Keyboard Shortcuts',
              ]),
            ],
          ),
        ),

        // Scaffold provides Material ancestor + ScaffoldMessenger for snackbars
        Expanded(
          child: Scaffold(
            body: const HomeScreen(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuBarItem(
      BuildContext context, String menuName, List<String> items) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$menuName > $value clicked')),
        );
      },
      itemBuilder: (BuildContext context) => items
          .map((item) => PopupMenuItem<String>(value: item, child: Text(item)))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text(
          menuName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}