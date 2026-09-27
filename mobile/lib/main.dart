import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state/app_providers.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/theme/nexus_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations & transparent system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: NexusColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NexusRemoteApp(),
    ),
  );
}

class NexusRemoteApp extends StatelessWidget {
  const NexusRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Remote',
      debugShowCheckedModeBanner: false,
      theme: NexusTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}
