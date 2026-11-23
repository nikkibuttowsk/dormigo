import 'package:material_ui/material_ui.dart';

import '../utils/theme.dart';

/// Temporary screen for tabs that are not built yet.
/// Replace it with the real screen when you get to it.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$title: coming soon',
          style: const TextStyle(fontSize: 18, color: AppColors.textMuted),
        ),
      ),
    );
  }
}