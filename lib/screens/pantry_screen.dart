import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import 'dorm_equipment_screen.dart';
import 'expiry_tracker_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _searchQuery = '';
  FoodCategory? _selectedCategory; // null = All

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final allItems = provider.items;

    final filtered = allItems.where((item) {
      final matchesCat =
          _selectedCategory == null || item.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: "My Pantry" + Expiry Tracker icon + Equipment Filter icon
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Pantry',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                _CircleIconBtn(
                  icon: Icons.schedule_rounded,
                  tooltip: 'Expiry Tracker',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExpiryTrackerScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CircleIconBtn(
                  icon: Icons.tune_rounded,
                  tooltip: 'Dorm Equipment',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DormEquipmentScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppColors.lightGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppColors.lightGreen),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryPill(
                    label: 'All ${allItems.length}',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ...FoodCategory.values.map((cat) {
                    final label =
                        cat.name[0].toUpperCase() + cat.name.substring(1);
                    return _CategoryPill(
                      label: label,
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2-Column Pantry Grid
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🧺', style: TextStyle(fontSize: 44)),
                          const SizedBox(height: 10),
                          const Text(
                            'Your pantry is empty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap the green + button below to add ingredients!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.86,
                          ),
                      itemBuilder: (context, index) {
                        return _PantryItemCard(item: filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryItemCard extends StatelessWidget {
  final PantryItem item;

  const _PantryItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.expiryStatus;
    final isUrgent =
        status == ExpiryStatus.useFirst || status == ExpiryStatus.expired;

    final badgeBg = isUrgent
        ? AppColors.alertBg
        : status == ExpiryStatus.expiringSoon
        ? const Color(0xFFF6E2B3)
        : AppColors.paleGreen;

    final badgeText = isUrgent
        ? AppColors.alertText
        : status == ExpiryStatus.expiringSoon
        ? const Color(0xFF9E6B00)
        : AppColors.green;

    final days = item.daysUntilExpiry;
    final badgeLabel = days == null
        ? item.storageLabel
        : days < 0
        ? 'Expired'
        : days <= 2
        ? 'Use first · ${days}d'
        : '$days days left';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? AppColors.alertText.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isUrgent
                    ? AppColors.alertBg.withValues(alpha: 0.45)
                    : AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                _emojiForItem(item),
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emojiForItem(PantryItem item) {
    final lower = item.name.toLowerCase();
    if (lower.contains('egg')) return '🥚';
    if (lower.contains('rice')) return '🍚';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('carrot')) return '🥕';
    if (lower.contains('milk')) return '🥛';
    if (lower.contains('chicken')) return '🍗';
    switch (item.category) {
      case FoodCategory.vegetables:
        return '🥬';
      case FoodCategory.protein:
        return '🥩';
      case FoodCategory.grains:
        return '🌾';
      case FoodCategory.dairy:
        return '🧀';
      case FoodCategory.other:
        return '🥫';
    }
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.green,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textDark,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(
          color: selected ? AppColors.green : AppColors.lightGreen,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lightGreen),
          ),
          child: Icon(icon, size: 20, color: AppColors.textDark),
        ),
      ),
    );
  }
}
