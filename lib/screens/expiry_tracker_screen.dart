import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';

class ExpiryTrackerScreen extends StatefulWidget {
  const ExpiryTrackerScreen({super.key});

  @override
  State<ExpiryTrackerScreen> createState() => _ExpiryTrackerScreenState();
}

class _ExpiryTrackerScreenState extends State<ExpiryTrackerScreen> {
  int _selectedFilter = 0; // 0: This week, 1: Later, 2: Expired

  String _formatShortDate(DateTime? date) {
    if (date == null) return 'No expiry';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Exp: ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final thisWeek = provider.expiringThisWeek;
    final later = provider.expiringLater;
    final expired = provider.expiredItems;
    final urgent = provider.urgentItem;

    final displayedList = _selectedFilter == 0
        ? thisWeek
        : _selectedFilter == 1
            ? later
            : expired;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                    const Text(
                      'Expiry Tracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.green,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3-Segment Filter Bar (This week | Later | Expired)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.paleGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _FilterTab(
                    label: 'This week · ${thisWeek.length}',
                    selected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  _FilterTab(
                    label: 'Later · ${later.length}',
                    selected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                  ),
                  _FilterTab(
                    label: 'Expired · ${expired.length}',
                    selected: _selectedFilter == 2,
                    onTap: () => setState(() => _selectedFilter = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Red "Use First!" Hero Banner
            if (urgent != null && _selectedFilter == 0) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.alertBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('🥚', style: TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.alertText,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Use First!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.alertText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            urgent.daysUntilExpiry == 0
                                ? '${urgent.name} expires today!'
                                : '${urgent.name} will expire in ${urgent.daysUntilExpiry} days',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.alertText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Navigate to Recipes filtered by urgent.name
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.alertText,
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Cook with ${urgent.name.toLowerCase()}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Section Title
            Text(
              _selectedFilter == 0
                  ? 'Soon to Expire'
                  : _selectedFilter == 1
                      ? 'Fresh & Shelf-Stable'
                      : 'Expired Items',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Items List
            if (displayedList.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'No items in this category yet!',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...displayedList.map((item) {
                final days = item.daysUntilExpiry;
                final isUrgent = days != null && days <= 3;
                final badgeColor = isUrgent
                    ? const Color(0xFFF6E2B3)
                    : AppColors.paleGreen;
                final textColor = isUrgent
                    ? const Color(0xFF9E6B00)
                    : AppColors.green;
                final progress = days == null
                    ? 1.0
                    : (days.clamp(0, 10) / 10.0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _emojiForCategory(item.category),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatShortDate(item.expiryDate)} · ${item.quantity.toInt()} ${item.unit}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: AppColors.paleGreen,
                                valueColor: AlwaysStoppedAnimation(
                                  isUrgent ? AppColors.orange : AppColors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          days == null
                              ? 'Safe'
                              : days < 0
                                  ? '${days.abs()}d ago'
                                  : '${days}d',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Bottom Amigo Recipe Suggestion Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paleGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.orange,
                    child: Icon(Icons.pets, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amigo says: try this recipe!',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          urgent != null
                              ? 'Quick ${urgent.name} Stir-Fry · 15 min'
                              : 'Egg Fried Rice · 15 min',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emojiForCategory(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.vegetables:
        return '🥕';
      case FoodCategory.protein:
        return '🥚';
      case FoodCategory.grains:
        return '🍚';
      case FoodCategory.dairy:
        return '🥛';
      case FoodCategory.other:
        return '🥫';
    }
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}