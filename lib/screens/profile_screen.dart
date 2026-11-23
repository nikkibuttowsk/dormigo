import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import 'dorm_equipment_screen.dart';
import 'onboarding_screen.dart';
import 'pantry_screen.dart';
import 'recipes_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = 'Chloe Yzabelle';
  String _handle = '@chloegonzaga';
  String _preferences = 'Budget · No pork';
  bool _notificationsOn = true;

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: _displayName);
    final handleCtrl = TextEditingController(text: _handle);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: handleCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
            onPressed: () {
              setState(() {
                if (nameCtrl.text.trim().isNotEmpty) {
                  _displayName = nameCtrl.text.trim();
                }
                if (handleCtrl.text.trim().isNotEmpty) {
                  _handle = handleCtrl.text.trim();
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPreferencesSheet() {
    final options = [
      'Budget · No pork',
      'Quick meals · High protein',
      'Vegetarian friendly',
      'No restrictions',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dietary & Budget Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (opt) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(opt),
                trailing: _preferences == opt
                    ? const Icon(Icons.check_circle, color: AppColors.green)
                    : null,
                onTap: () {
                  setState(() => _preferences = opt);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final itemCount = provider.items.length;
    final equipCount = provider.selectedEquipment.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          children: [
            // Curved Pale-Green Top Header + Avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 165,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCE8CE),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.elliptical(240, 56),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -44,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCDE0BA),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: const Icon(
                          Icons.face_3_rounded,
                          size: 62,
                          color: AppColors.textDark,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _editProfileDialog,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 54),

            // Name, Handle, Sync Status Pill
            Text(
              _displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _handle,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 15,
                    color: AppColors.green,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Synced just now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Stats Row Card (Pantry items | Meals cooked | Food saved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _statColumn('$itemCount', 'Pantry items'),
                    ),
                    Container(width: 1, height: 34, color: Colors.black12),
                    Expanded(
                      child: _statColumn('12', 'Meals cooked'),
                    ),
                    Container(width: 1, height: 34, color: Colors.black12),
                    Expanded(
                      child: _statColumn('2.5 kg', 'Food saved'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Settings Menu Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _menuTile(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Pantry',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantryScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 60),
                    _menuTile(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Saved Recipes',
                      trailingText: '8',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecipesScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 60),
                    _menuTile(
                      icon: Icons.rice_bowl_outlined,
                      title: 'Dorm Equipment',
                      trailingText:
                          '${equipCount == 0 ? 2 : equipCount} selected',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DormEquipmentScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 60),
                    _menuTile(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Preferences',
                      trailingText: _preferences,
                      onTap: _editPreferencesSheet,
                    ),
                    const Divider(height: 1, indent: 60),
                    _menuTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      trailingText: _notificationsOn ? 'On' : 'Off',
                      onTap: () => setState(
                        () => _notificationsOn = !_notificationsOn,
                      ),
                    ),
                    const Divider(height: 1, indent: 60),
                    _menuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About Dormigo',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Dormigo',
                          applicationVersion: '1.0.0',
                          children: const [
                            Text(
                              'Smart dorm pantry tracker, expiry alert system, and equipment-aware recipe assistant.',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Log Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6DADA),
                    foregroundColor: const Color(0xFF9B2C2C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.green,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.paleGreen.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 19, color: AppColors.green),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}