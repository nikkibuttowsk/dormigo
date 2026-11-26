import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/pantry_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env.local');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {}
  }

  final url = (dotenv.env['SUPABASE_URL'] ??
          const String.fromEnvironment('SUPABASE_URL'))
      .trim();
  final anonKey = (dotenv.env['SUPABASE_ANON_KEY'] ??
          const String.fromEnvironment('SUPABASE_ANON_KEY'))
      .trim();

  if (url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url.startsWith('http')) {
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
    } catch (e) {
      debugPrint('Supabase init skipped: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PantryProvider()),
      ],
      child: const DormigoApp(),
    ),
  );
}

class DormigoApp extends StatelessWidget {
  const DormigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dormigo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}