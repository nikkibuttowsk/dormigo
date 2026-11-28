import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/auth_provider.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import '../widgets/placeholder_screen.dart';
import 'amigo_screen.dart';
import 'dorm_equipment_screen.dart';
import 'expiry_tracker_screen.dart';

/// Figma screen 03.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.onAddFood,
  });

  /// Switches the bottom-nav tab (1 = Pantry, 2 = Recipes, 3 = Profile).
  final ValueChanged<int> onOpenTab;

  /// Opens the main Add Food screen (photo / upload / manual).
  final VoidCallback onAddFood;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasUnread = true;

  /// Must match the recipe title in SeedData so Home and Recipes share the
  /// same saved state.
  static const _homeRecipeTitle = 'Creamy Egg Fried Rice';

  // Notifications
  List<_NotificationItem> _buildNotifications(PantryProvider pantry) {
    final alerts = <PantryItem>[
      ...pantry.expiredItems,
      ...pantry.expiringThisWeek.where((i) => (i.daysUntilExpiry ?? 99) <= 3),
    ];

    String titleFor(PantryItem item) {
      final d = item.daysUntilExpiry!;
      if (d < 0) return '${item.name} expired';
      if (d == 0) return '${item.name} expires today';
      return '${item.name} expires in $d day${d == 1 ? '' : 's'}';
    }

    return [
      for (final item in alerts)
        _NotificationItem(
          icon: (item.daysUntilExpiry ?? 0) < 0
              ? Icons.error_outline_rounded
              : Icons.warning_amber_rounded,
          iconColor: (item.daysUntilExpiry ?? 0) < 0
              ? AppColors.alertText
              : const Color(0xFF9E6B00),
          badgeBg: (item.daysUntilExpiry ?? 0) < 0
              ? AppColors.alertBg
              : const Color(0xFFF6E2B3),
          title: titleFor(item),
          subtitle: (item.daysUntilExpiry ?? 0) < 0
              ? 'Expired — tap to review in Expiry Tracker'
              : 'Use it first — tap to manage',
          target: _NotificationTarget.expiryTracker,
        ),
      if (pantry.items.isEmpty)
        const _NotificationItem(
          icon: Icons.shopping_basket_outlined,
          title: 'Your pantry is empty',
          subtitle: 'Tap to open My Pantry and add ingredients',
          target: _NotificationTarget.pantry,
        ),
      if (pantry.selectedEquipment.length <= 2)
        const _NotificationItem(
          icon: Icons.tune_rounded,
          title: 'Set up your dorm equipment',
          subtitle: 'Update appliances to unlock matching recipes',
          target: _NotificationTarget.equipment,
        ),
      const _NotificationItem(
        icon: Icons.soup_kitchen_outlined,
        title: 'New recipe for you',
        subtitle: 'Creamy Egg Fried Rice · 15 min',
        target: _NotificationTarget.recipe,
      ),
    ];
  }

  void _handleNotificationTap(
    BuildContext sheetContext,
    _NotificationItem notification,
  ) {
    Navigator.pop(sheetContext);

    switch (notification.target) {
      case _NotificationTarget.expiryTracker:
        _push(const ExpiryTrackerScreen());
        break;
      case _NotificationTarget.pantry:
        widget.onOpenTab(1);
        break;
      case _NotificationTarget.equipment:
        _push(const DormEquipmentScreen());
        break;
      case _NotificationTarget.recipe:
        widget.onOpenTab(2);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _toggleBookmark() {
    final pantry = context.read<PantryProvider>();
    pantry.toggleRecipeSaved(_homeRecipeTitle);
    final saved = pantry.isRecipeSaved(_homeRecipeTitle);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(saved ? 'Recipe saved' : 'Removed from saved'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  void _openNotifications() {
    final notifications = _buildNotifications(context.read<PantryProvider>());
    setState(() => _hasUnread = false);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.65;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Notifications'),
                  const SizedBox(height: 8),
                  if (notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          "You're all caught up!",
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final n = notifications[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () =>
                                _handleNotificationTap(sheetContext, n),
                            leading: CircleAvatar(
                              backgroundColor: n.badgeBg ?? AppColors.paleGreen,
                              child: Icon(
                                n.icon,
                                color: n.iconColor ?? AppColors.green,
                              ),
                            ),
                            title: Text(
                              n.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(n.subtitle),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAmigo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AmigoScreen()),
    );
  }

  void _openAddFood() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Add Food'),
                const SizedBox(height: 8),
                _AddOption(
                  icon: Icons.photo_camera_outlined,
                  title: 'Take a photo',
                  subtitle: 'Snap your groceries',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    // Opens the main Add Food screen (camera picker lives there).
                    widget.onAddFood();
                  },
                ),
                _AddOption(
                  icon: Icons.edit_outlined,
                  title: 'Add manually',
                  subtitle: 'Type in the details',
                  onTap: () async {
                    final pantry = context.read<PantryProvider>();
                    Navigator.pop(sheetContext);
                    final added = await Navigator.push<_FoodEntry>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _ManualAddFoodScreen(),
                      ),
                    );
                    if (!mounted || added == null) return;

                    try {
                      await pantry.addNewItem(
                        name: added.name,
                        category: added.category,
                        quantity: added.quantity,
                        unit: added.unit,
                        expiryDate: added.expiry,
                        storageLocation: added.storageLocation,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text('${added.name} added')),
                        );
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Could not save. Check your connection.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  ImageProvider? _avatarImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    final file = File(url);
    return file.existsSync() ? FileImage(file) : null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
          _buildQuickActions(),
          const SizedBox(height: 20),
          _buildUseFirst(),
          const SizedBox(height: 12),
          _buildAmigoTip(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('Recommended for You'),
              TextButton(
                onPressed: () => widget.onOpenTab(2),
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
    final pantry = context.watch<PantryProvider>();
    final hasAlerts = _buildNotifications(pantry).isNotEmpty;

    final fullName = auth.displayName.trim();
    final firstName =
        fullName.isEmpty ? 'Chef' : fullName.split(RegExp(r'\s+')).first;
    final initial = firstName[0].toUpperCase();
    final avatarProvider = _avatarImageProvider(auth.avatarUrl);

    return Row(
      children: [
        GestureDetector(
          onTap: () => widget.onOpenTab(3),
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
            onTap: () => widget.onOpenTab(3),
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
            onPressed: _openNotifications,
            icon: Badge(
              smallSize: 8,
              isLabelVisible: _hasUnread && hasAlerts,
              child: const Icon(Icons.notifications_none),
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

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          icon: Icons.photo_camera_outlined,
          label: 'Add Food',
          onTap: _openAddFood,
        ),
        _QuickAction(
          icon: Icons.soup_kitchen_outlined,
          label: 'Get Recipes',
          onTap: () => widget.onOpenTab(2),
        ),
        _QuickAction(
          icon: Icons.bar_chart,
          label: 'View Stats',
          onTap: () => _push(
            Scaffold(
              appBar: AppBar(title: const Text('Waste Stats')),
              body: const PlaceholderScreen(title: 'Waste Stats'),
            ),
          ),
        ),
        _QuickAction(
          icon: Icons.shopping_basket_outlined,
          label: 'My Pantry',
          onTap: () => widget.onOpenTab(1),
        ),
      ],
    );
  }

  /// Red "Use First!" card. Only shown when something in the pantry is
  /// actually about to expire (0–3 days).
  Widget _buildUseFirst() {
    final urgent = context.watch<PantryProvider>().urgentItem;
    if (urgent == null) return const SizedBox.shrink();

    final d = urgent.daysUntilExpiry!;
    final when =
        d == 0 ? 'expires today' : 'expires in $d day${d == 1 ? '' : 's'}';

    return Material(
      color: AppColors.alertBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _push(const ExpiryTrackerScreen()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.alertText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Use First!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertText,
                      ),
                    ),
                    Text(
                      '${urgent.name} · $when',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.alertText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.alertText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmigoTip() {
    return Material(
      color: AppColors.lightGreen,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openAmigo,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.green.withAlpha(77)),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.green,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard() {
    final saved =
        context.watch<PantryProvider>().isRecipeSaved(_homeRecipeTitle);

    return InkWell(
      onTap: () => widget.onOpenTab(2),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                    _homeRecipeTitle,
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
            IconButton(
              onPressed: _toggleBookmark,
              tooltip: saved ? 'Remove bookmark' : 'Save recipe',
              icon: Icon(
                saved ? Icons.bookmark : Icons.bookmark_border,
                color: saved ? AppColors.green : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------

enum _NotificationTarget { pantry, expiryTracker, equipment, recipe }

class _NotificationItem {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.target,
    this.iconColor,
    this.badgeBg,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _NotificationTarget target;
  final Color? iconColor;
  final Color? badgeBg;
}

class _FoodEntry {
  const _FoodEntry({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.storageLocation,
    required this.expiry,
  });

  final String name;
  final double quantity;
  final String unit;
  final FoodCategory category;
  final StorageLocation storageLocation;
  final DateTime expiry;
}

// -----------------------------------------------------------------------------
// Manual add food screen
// -----------------------------------------------------------------------------

class _ManualAddFoodScreen extends StatefulWidget {
  const _ManualAddFoodScreen();

  @override
  State<_ManualAddFoodScreen> createState() => _ManualAddFoodScreenState();
}

class _ManualAddFoodScreenState extends State<_ManualAddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  static const _units = ['pcs', 'g', 'kg', 'ml', 'L', 'pack', 'can'];
  String _unit = 'pcs';
  FoodCategory _category = FoodCategory.values.first;
  StorageLocation _storage = StorageLocation.values.first;
  DateTime? _expiry;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _labelize(String enumName) {
    if (enumName.isEmpty) return enumName;
    return enumName[0].toUpperCase() + enumName.substring(1);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final parsedQty = double.tryParse(_quantityController.text.trim());
    if (parsedQty == null || parsedQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive quantity')),
      );
      return;
    }
    if (_expiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an expiry date')),
      );
      return;
    }
    Navigator.pop(
      context,
      _FoodEntry(
        name: _nameController.text.trim(),
        quantity: parsedQty,
        unit: _unit,
        category: _category,
        storageLocation: _storage,
        expiry: _expiry!,
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a quantity';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _unit = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FoodCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: FoodCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_labelize(c.name)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StorageLocation>(
                initialValue: _storage,
                decoration: const InputDecoration(
                  labelText: 'Storage location',
                  border: OutlineInputBorder(),
                ),
                items: StorageLocation.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_labelize(s.name)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _storage = v);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _expiry == null ? 'Select a date' : _formatDate(_expiry!),
                    style: TextStyle(
                      color: _expiry == null
                          ? AppColors.textMuted
                          : AppColors.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small shared widgets
// -----------------------------------------------------------------------------

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.paleGreen,
        child: Icon(icon, color: AppColors.green),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
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