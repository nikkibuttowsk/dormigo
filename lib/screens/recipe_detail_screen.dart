import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import 'cooking_guide_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map recipe;
  final int matchPercent;
  final Color bannerColor;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.matchPercent,
    this.bannerColor = const Color(0xFFE5A43B),
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _servings = 1;
  bool _bookmarked = false;
  bool _showStepsPreview = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final pantryNames =
        provider.items.map((e) => e.name.toLowerCase()).toList();

    final title = widget.recipe['title'] as String;
    final prep = widget.recipe['prep_minutes'] as int;
    final ingredients = List.from(widget.recipe['ingredients'] ?? []);
    final steps = List.from(widget.recipe['steps'] ?? []);

    // Find first missing ingredient for Amigo swap tip
    String? missingIngredient;
    for (final ing in ingredients) {
      final lower = ing.toString().toLowerCase();
      final hasIt = pantryNames
          .any((p) => p.contains(lower) || lower.contains(p));
      if (!hasIt) {
        missingIngredient = ing.toString();
        break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Hero Banner
          Container(
            height: 245,
            width: double.infinity,
            color: widget.bannerColor,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F2E7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 8),
                      ),
                      child: Icon(
                        Icons.ramen_dining_rounded,
                        size: 74,
                        color: widget.bannerColor,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 20,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 20,
                    child: InkWell(
                      onTap: () => setState(() => _bookmarked = !_bookmarked),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _bookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 20,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable White Card Content
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pills Row
                    Row(
                      children: [
                        _infoPill(Icons.access_time_rounded, '$prep min'),
                        const SizedBox(width: 8),
                        _infoPill(null, '${ingredients.length} ingredients'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${widget.matchPercent}% match',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ingredients + Servings Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            _circleBtn(Icons.remove, () {
                              if (_servings > 1) setState(() => _servings--);
                            }),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$_servings ${_servings == 1 ? 'serving' : 'servings'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            _circleBtn(Icons.add, () {
                              setState(() => _servings++);
                            }),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ingredient Checklist
                    ...ingredients.map((ing) {
                      final name = ing.toString();
                      final lower = name.toLowerCase();
                      final inPantry = pantryNames
                          .any((p) => p.contains(lower) || lower.contains(p));

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: inPantry
                                    ? AppColors.paleGreen
                                    : const Color(0xFFFEF0D8),
                              ),
                              child: Icon(
                                inPantry
                                    ? Icons.check_rounded
                                    : Icons.priority_high_rounded,
                                size: 15,
                                color: inPantry
                                    ? AppColors.green
                                    : const Color(0xFFD98A2B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              inPantry
                                  ? '$_servings portion'
                                  : '$_servings portion · Missing',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: inPantry
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: inPantry
                                    ? AppColors.textMuted
                                    : const Color(0xFFB36B12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 14),

                    // Amigo Tip Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF6E4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5A43B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              missingIngredient != null
                                  ? 'Amigo: No $missingIngredient? You can still cook this or swap in a dorm pantry staple!'
                                  : 'Amigo: You have every single ingredient ready in your dorm pantry!',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8C5308),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Collapsible Step-by-Step Preview
                    InkWell(
                      onTap: () => setState(
                          () => _showStepsPreview = !_showStepsPreview),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Step-by-Step Guide · ${steps.length} steps',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            Icon(
                              _showStepsPreview
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showStepsPreview)
                      ...steps.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${entry.key + 1}. ${entry.value}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Start Cooking Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CookingGuideScreen(recipe: widget.recipe),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start Cooking'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData? icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paleGreen.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.green),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
        ),
        child: Icon(icon, size: 16, color: AppColors.textDark),
      ),
    );
  }
}