import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import 'dorm_equipment_screen.dart';
import 'login_screen.dart';
import 'pantry_screen.dart';
import 'recipes_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickAvatarSheet(AuthProvider auth) async {
    final picker = ImagePicker();

    Future<void> pick(BuildContext sheetCtx, ImageSource source) async {
      Navigator.pop(sheetCtx);
      final file = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file != null) {
        await auth.updateAvatar(file.path);
      }
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.green,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => pick(sheetCtx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.green,
                ),
                title: const Text('Take a Photo'),
                onTap: () => pick(sheetCtx, ImageSource.camera),
              ),
              if (auth.avatarPath != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFF9B2C2C),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Color(0xFF9B2C2C)),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    await auth.updateAvatar(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _editProfileSheet(AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.displayName);
    final handleCtrl = TextEditingController(text: auth.handle);
    final dormCtrl = TextEditingController(text: auth.dormInfo);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Display Name',
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.green,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: handleCtrl,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(
                  Icons.alternate_email,
                  color: AppColors.green,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dormCtrl,
              decoration: InputDecoration(
                labelText: 'Dorm / Room Info',
                hintText: 'e.g. Dorm Bldg A · Room 204',
                prefixIcon: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.green,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () async {
                      await auth.updateProfile(
                        displayName: nameCtrl.text,
                        handle: handleCtrl.text,
                        dormInfo: dormCtrl.text,
                      );
                      if (sheetCtx.mounted) {
                        Navigator.pop(sheetCtx);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Profile updated')),
                        );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editPreferencesSheet(AuthProvider auth) {
    final options = [
      'Budget · No pork',
      'Quick meals · High protein',
      'Vegetarian friendly',
      'Halal friendly',
      'No restrictions',
    ];
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
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
                trailing: auth.preferences == opt
                    ? const Icon(Icons.check_circle, color: AppColors.green)
                    : null,
                onTap: () async {
                  await auth.updateProfile(preferences: opt);
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(AuthProvider auth) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(auth.isGuest ? 'Exit Guest Mode?' : 'Log Out?'),
        content: Text(
          auth.isGuest
              ? 'You will return to the login screen where you can sign in or create an account.'
              : 'Are you sure you want to log out of ${auth.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B2C2C),
              minimumSize: const Size(100, 42),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(auth.isGuest ? 'Exit' : 'Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    await auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PantryProvider>();
    final itemCount = provider.items.length;
    final equipCount = provider.selectedEquipment.length;
    final hasValidAvatar =
        auth.avatarPath != null && File(auth.avatarPath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          children: [
            // Curved Pale-Green Top Header + Clickable Avatar
            SizedBox(
              height: 215,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topCenter,
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
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _pickAvatarSheet(auth),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCDE0BA),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              image: hasValidAvatar
                                  ? DecorationImage(
                                      image: FileImage(File(auth.avatarPath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !hasValidAvatar
                                ? const Icon(
                                    Icons.face_3_rounded,
                                    size: 62,
                                    color: AppColors.textDark,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Name, Handle, Dorm Info & Sync Status Pill
            Text(
              auth.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${auth.handle} · ${auth.dormInfo}',
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    auth.isGuest
                        ? Icons.person_outline_rounded
                        : Icons.cloud_done_outlined,
                    size: 15,
                    color: auth.isGuest ? AppColors.orange : AppColors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    auth.isGuest ? 'Guest Session' : 'Synced · ${auth.email}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: auth.isGuest ? AppColors.orange : AppColors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Guest Upgrade Banner
            if (auth.isGuest) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.paleGreen,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_open_rounded,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sign in to back up your pantry across devices.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Stats Row Card
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
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile Info',
                      trailingText: auth.displayName,
                      onTap: () => _editProfileSheet(auth),
                    ),
                    const Divider(height: 1, indent: 60),
                    _menuTile(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Pantry',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: AppColors.cream,
                            appBar: AppBar(
                              title: const Text('My Pantry'),
                              backgroundColor: AppColors.cream,
                              elevation: 0,
                            ),
                            body: const PantryScreen(),
                          ),
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
                          builder: (_) => Scaffold(
                            backgroundColor: AppColors.cream,
                            appBar: AppBar(
                              title: const Text('Saved Recipes'),
                              backgroundColor: AppColors.cream,
                              elevation: 0,
                            ),
                            body: const RecipesScreen(),
                          ),
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
                      trailingText: auth.preferences,
                      onTap: () => _editPreferencesSheet(auth),
                    ),
                    const Divider(height: 1, indent: 60),
                    _menuTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      trailingText: auth.notificationsOn ? 'On' : 'Off',
                      onTap: () => auth.updateProfile(
                        notificationsOn: !auth.notificationsOn,
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
                  onPressed: () => _confirmLogout(auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6DADA),
                    foregroundColor: const Color(0xFF9B2C2C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    auth.isGuest ? 'Exit Guest Mode' : 'Log Out',
                    style: const TextStyle(
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                trailingText,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
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