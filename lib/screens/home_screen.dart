import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/placeholder_screen.dart';
import 'expiry_tracker_screen.dart';

/// Figma screen 03.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.onAddFood,
  });

  /// Switches the bottom-nav tab
  final ValueChanged<int> onOpenTab;
  final VoidCallback onAddFood;

  ImageProvider? _avatarImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    final file = File(url);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildSavedCard(),
          const SizedBox(height: 24),
          const _SectionTitle('Quick Actions'),
          const SizedBox(height: 12),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          _buildUseFirst(context),
          const SizedBox(height: 12),
          _buildAmigoTip(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('Recommended for You'),
              TextButton(
                onPressed: () => onOpenTab(2),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          _buildRecipeCard(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fullName = auth.displayName.trim();
    final firstName =
        fullName.isEmpty ? 'Chef' : fullName.split(RegExp(r'\s+')).first;
    final initial = firstName[0].toUpperCase();
    final avatarProvider = _avatarImageProvider(auth.avatarUrl);

    return Row(
      children: [
        GestureDetector(
          onTap: () => onOpenTab(3),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.orange,
            backgroundImage: avatarProvider,
            child: avatarProvider == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onOpenTab(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $firstName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Text(
                  'Cook smart today',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_none),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCard() {
    Widget bar(double height) => Container(
          width: 12,
          height: height,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(3),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You've saved",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '2.5 kg',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'of food this month',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [bar(20), bar(34), bar(48), bar(64)],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          icon: Icons.photo_camera_outlined,
          label: 'Add Food',
          onTap: onAddFood,
        ),
        _QuickAction(
          icon: Icons.soup_kitchen_outlined,
          label: 'Get Recipes',
          onTap: () => onOpenTab(2),
        ),
        _QuickAction(
          icon: Icons.bar_chart,
          label: 'View Stats',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Waste Stats')),
                body: const PlaceholderScreen(title: 'Waste Stats'),
              ),
            ),
          ),
        ),
        _QuickAction(
          icon: Icons.shopping_basket_outlined,
          label: 'My Pantry',
          onTap: () => onOpenTab(1),
        ),
      ],
    );
  }

  Widget _buildUseFirst(BuildContext context) {
    return Material(
      color: AppColors.alertBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpiryTrackerScreen()),
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.alertText),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use First!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertText,
                      ),
                    ),
                    Text(
                      'Eggs · expires in 2 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.alertText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.alertText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmigoTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.orange,
            child: Icon(Icons.pets, size: 16, color: Colors.white),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, color: AppColors.textDark),
                children: [
                  TextSpan(
                    text: 'Amigo: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Eggs + rice = a 15-minute fried rice. '
                        'Want to cook it now? ',
                  ),
                  TextSpan(
                    text: 'Ask Amigo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.paleGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🍳', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Creamy Egg Fried Rice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Text(
                  '15 min · 4 ingredients',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.paleGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Rice cooker',
                    style: TextStyle(fontSize: 11, color: AppColors.green),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.bookmark_border, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.green),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}