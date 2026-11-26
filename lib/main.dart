import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/pantry_provider.dart';
import 'screens/amigo_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

String _firstNonEmpty(List<String?> candidates) {
  for (final raw in candidates) {
    if (raw == null) continue;
    final cleaned = raw.replaceAll('"', '').replaceAll("'", '').trim();
    if (cleaned.isNotEmpty) return cleaned;
  }
  return '';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env.local');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {}
  }

  final url = _firstNonEmpty([
    const String.fromEnvironment('SUPABASE_URL'),
    dotenv.env['SUPABASE_URL'],
  ]);

  final anonKey = _firstNonEmpty([
    const String.fromEnvironment('SUPABASE_ANON_KEY'),
    const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    dotenv.env['SUPABASE_ANON_KEY'],
    dotenv.env['SUPABASE_PUBLISHABLE_KEY'],
  ]);

  // ignore: avoid_print
  print('SUPABASE_DEBUG -> urlEmpty=${url.isEmpty}, keyEmpty=${anonKey.isEmpty}');

  if (url.isNotEmpty && anonKey.isNotEmpty && url.startsWith('http')) {
    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      // ignore: avoid_print
      print('SUPABASE_DEBUG -> initialized successfully');
    } catch (e) {
      // ignore: avoid_print
      print('SUPABASE_DEBUG -> init failed: $e');
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
      navigatorKey: amigoNavigatorKey,
      navigatorObservers: [amigoRouteObserver],
      builder: (context, child) => AmigoOverlay(child: child!),
    );
  }
}