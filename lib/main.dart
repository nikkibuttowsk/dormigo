import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/pantry_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'screens/amigo_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env.local');
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
    if (url.isNotEmpty && key.isNotEmpty) {
      await Supabase.initialize(url: url, publishableKey: key);
    }
  } catch (e) {
    debugPrint('Supabase init skipped: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => PantryProvider()..loadFromSupabase(),
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