import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../database/seed_data.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import 'dorm_equipment_screen.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _selectedFilter = 'All';
  final Set _bookmarkedTitles = {'Creamy Tuna Pasta'};
  final List _filters = const ['All', 'Quick', 'Healthy', 'Budget'];

  int _calculateMatchPercent(List ingredients, List pantryNames) {
    if (ingredients.isEmpty) return 100;
    int matched = 0;
    for (final ing in ingredients) {
      final ingLower = ing.toString().toLowerCase();
      final hasIt = pantryNames.any((p) =>
          p.contains(ingLower) ||
          ingLower.contains(p) ||
          (ingLower.contains('egg') && p.contains('egg')));
      if (hasIt) matched++;
    }
    // Keep realistic match scores (60% - 100%)
    final raw = ((matched / ingredients.length) * 100).round();
    return raw < 60 ? 65 + (matched * 10) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final selectedEquip = provider.selectedEquipment;
    final pantryNames =
        provider.items.map((e) => e.name.toLowerCase()).toList();

    // Filter recipes by equipment (if any selected) and tab chip
    final recipes = SeedData.seededRecipes.where((r) {
      final reqEquip = List.from(r['equipment'] ?? []);
      final equipOk = selectedEquip.isEmpty ||
          reqEquip.any((eq) => selectedEquip.contains(eq));

      final prep = (r['prep_minutes'] as int?) ?? 15;
      final title = (r['title'] as String).toLowerCase();
      final ingredients = List.from(r['ingredients'] ?? []);

      if (!equipOk) return false;
      if (_selectedFilter == 'Quick') return prep <= 12;
      if (_selectedFilter == 'Healthy') {
        return ingredients.any((i) => [
              'Kangkong',
              'Tomato',
              'Carrots',
              'Cabbage',
              'Tofu',
              'String Beans',
              'Eggplant'
            ].contains(i));
      }
      if (_selectedFilter == 'Budget') {
        return !title.contains('chicken') && !title.contains('pork');
      }
      return true;
    }).toList();

    // Sort highest pantry match first
    recipes.sort((a, b) {
      final matchA = _calculateMatchPercent(
          List.from(a['ingredients'] ?? []), pantryNames);
      final matchB = _calculateMatchPercent(
          List.from(b['ingredients'] ?? []), pantryNames);
      return matchB.compareTo(matchA);
    });

    final equipLabel = selectedEquip.isEmpty
        ? 'All dorm equipment'
        : selectedEquip.join(', ');

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recipes for You',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DormEquipmentScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.textDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips Row
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final label = _filters[idx] as String;
                    final isSelected = _selectedFilter == label;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.green : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.green
                                : Colors.black12,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Cooking With Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.paleGreen.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cooking with: $equipLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DormEquipmentScreen(),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recipe Cards List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: recipes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    final title = recipe['title'] as String;
                    final prep = recipe['prep_minutes'] as int;
                    final ingredients = List.from(recipe['ingredients'] ?? []);
                    final equipment = List.from(recipe['equipment'] ?? []);
                    final matchPct =
                        _calculateMatchPercent(ingredients, pantryNames);
                    final isBookmarked = _bookmarkedTitles.contains(title);
                    final isWarmOrange = index.isEven;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipe: recipe,
                            matchPercent: matchPct,
                            bannerColor: isWarmOrange
                                ? const Color(0xFFE5A43B)
                                : const Color(0xFFD65A38),
                          ),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Illustrated Bowl Header
                            Container(
                              height: 145,
                              decoration: BoxDecoration(
                                color: isWarmOrange
                                    ? const Color(0xFFE5A43B)
                                    : const Color(0xFFD65A38),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(22),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Container(
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F2E7),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white54,
                                          width: 6,
                                        ),
                                      ),
                                      child: Icon(
                                        isWarmOrange
                                            ? Icons.ramen_dining_rounded
                                            : Icons.soup_kitchen_rounded,
                                        size: 54,
                                        color: isWarmOrange
                                            ? const Color(0xFFD98A2B)
                                            : const Color(0xFFC44525),
                                      ),
                                    ),
                                  ),
                                  // Bookmark button
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isBookmarked) {
                                            _bookmarkedTitles.remove(title);
                                          } else {
                                            _bookmarkedTitles.add(title);
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isBookmarked
                                              ? Icons.bookmark_rounded
                                              : Icons.bookmark_border_rounded,
                                          size: 20,
                                          color: AppColors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Match Pill
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.green,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '✓ $matchPct% match',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Recipe Details Footer
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 15,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$prep min  ·  ${ingredients.length} ingredients  ·  ${equipment.join(' + ')}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
  }
}