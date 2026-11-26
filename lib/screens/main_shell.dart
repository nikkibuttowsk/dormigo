import 'package:dormigo/screens/recipes_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';
import 'add_food_screen.dart';
import 'home_screen.dart';
import 'pantry_screen.dart';
import 'profile_screen.dart';


/// Holds the bottom navigation bar and switches between the main tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _selectTab(int i) => setState(() => _index = i);

 Future<void> _openAddFood() async {
    final drafts = await Navigator.push<List<DraftFood>>(
      context,
      MaterialPageRoute(builder: (_) => const AddFoodScreen()),
    );
    if (!mounted || drafts == null || drafts.isEmpty) return;

    final pantry = context.read<PantryProvider>();
    final defaultCategory = FoodCategory.values.firstWhere(
      (c) => c.name == 'other',
      orElse: () => FoodCategory.values.first,
    );
    final defaultStorage = StorageLocation.values.firstWhere(
      (s) => s.name == 'pantry' || s.name == 'shelf',
      orElse: () => StorageLocation.values.first,
    );

    try {
      for (final draft in drafts) {
        await pantry.addNewItem(
          name: draft.name,
          category: defaultCategory,
          quantity: draft.quantity.toDouble(),
          unit: 'pcs',
          expiryDate: draft.expiry,
          storageLocation: defaultStorage,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Added ${drafts.length} item${drafts.length == 1 ? '' : 's'} to pantry',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save items. Check your connection.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps every tab alive so they don't reset when you switch.
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenTab: _selectTab, onAddFood: _openAddFood),
          const PantryScreen(),
          const RecipesScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFood,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: _index == 0,
              onTap: () => _selectTab(0),
            ),
            _NavItem(
              icon: Icons.shopping_basket_outlined,
              label: 'Pantry',
              selected: _index == 1,
              onTap: () => _selectTab(1),
            ),
            const Expanded(child: SizedBox()), // space for the + button
            _NavItem(
              icon: Icons.soup_kitchen_outlined,
              label: 'Recipes',
              selected: _index == 2,
              onTap: () => _selectTab(2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              selected: _index == 3,
              onTap: () => _selectTab(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}