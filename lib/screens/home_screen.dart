import 'package:material_ui/material_ui.dart';

import '../utils/theme.dart';
import '../widgets/placeholder_screen.dart';
import 'amigo_screen.dart';
import 'expiry_tracker_screen.dart';

/// Figma screen 03.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.onAddFood,
  });

  /// Switches the bottom-nav tab (1 = Pantry, 2 = Recipes).
  final ValueChanged<int> onOpenTab;

  /// Called after a food item is successfully added from the Home screen,
  /// so the parent can refresh the pantry if it needs to.
  final VoidCallback onAddFood;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bookmarked = false;
  bool _hasUnread = true;

  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      icon: Icons.warning_amber_rounded,
      title: 'Eggs expire in 2 days',
      subtitle: 'Use them first!',
    ),
    _NotificationItem(
      icon: Icons.soup_kitchen_outlined,
      title: 'New recipe for you',
      subtitle: 'Creamy Egg Fried Rice · 15 min',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _toggleBookmark() {
    setState(() => _bookmarked = !_bookmarked);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_bookmarked ? 'Recipe saved' : 'Removed from saved'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  void _openNotifications() {
    setState(() => _hasUnread = false);
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
                const _SectionTitle('Notifications'),
                const SizedBox(height: 8),
                if (_notifications.isEmpty)
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
                  ..._notifications.map(
                    (n) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.paleGreen,
                        child: Icon(n.icon, color: AppColors.green),
                      ),
                      title: Text(
                        n.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(n.subtitle),
                    ),
                  ),
              ],
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
                    _push(
                      Scaffold(
                        appBar: AppBar(title: const Text('Take a Photo')),
                        body: const PlaceholderScreen(title: 'Take a Photo'),
                      ),
                    );
                  },
                ),
                _AddOption(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan barcode',
                  subtitle: 'Scan a packaged item',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _push(
                      Scaffold(
                        appBar: AppBar(title: const Text('Scan Barcode')),
                        body: const PlaceholderScreen(title: 'Scan Barcode'),
                      ),
                    );
                  },
                ),
                _AddOption(
                  icon: Icons.edit_outlined,
                  title: 'Add manually',
                  subtitle: 'Type in the details',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final added = await Navigator.push<_FoodEntry>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _ManualAddFoodScreen(),
                      ),
                    );
                    if (!mounted || added == null) return;
                    widget.onAddFood();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text('${added.name} added')),
                      );
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          _buildHeader(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.orange,
          child: Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Chloe!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Cook smart today',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
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
              isLabelVisible: _hasUnread,
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

  Widget _buildUseFirst() {
    return Material(
      color: AppColors.alertBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _push(const ExpiryTrackerScreen()),
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
          IconButton(
            onPressed: _toggleBookmark,
            tooltip: _bookmarked ? 'Remove bookmark' : 'Save recipe',
            icon: Icon(
              _bookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _bookmarked ? AppColors.green : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------

class _NotificationItem {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _FoodEntry {
  const _FoodEntry({
    required this.name,
    required this.quantity,
    required this.expiry,
  });

  final String name;
  final String quantity;
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
  DateTime? _expiry;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
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
        quantity: _quantityController.text.trim(),
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
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a quantity'
                    : null,
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