import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/pantry_provider.dart';
import '../utils/theme.dart';

class DormEquipmentScreen extends StatefulWidget {
  const DormEquipmentScreen({super.key});

  @override
  State<DormEquipmentScreen> createState() => _DormEquipmentScreenState();
}

class _DormEquipmentScreenState extends State<DormEquipmentScreen> {
  late Set<String> _localSelected;
  bool _isSaving = false;

  final List _equipmentOptions = const [
    {'name': 'Rice Cooker', 'icon': Icons.rice_bowl_rounded},
    {'name': 'Kettle', 'icon': Icons.coffee_maker_rounded},
    {'name': 'Microwave', 'icon': Icons.microwave_rounded},
    {'name': 'Hot Plate', 'icon': Icons.countertops_rounded},
    {'name': 'Toaster', 'icon': Icons.breakfast_dining_rounded},
    {'name': 'Electric Pan', 'icon': Icons.soup_kitchen_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<PantryProvider>();
    _localSelected = Set<String>.from(provider.selectedEquipment);
  }

  Future<void> _applyFilters() async {
    setState(() => _isSaving = true);
    try {
      await context.read<PantryProvider>().updateEquipment(_localSelected);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save equipment: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Back Button
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
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
              const SizedBox(height: 20),

              // Title & Subtitle
              const Text(
                'Select Your\nCooking Equipment',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose what you have in your dorm. We'll only suggest recipes you can actually cook.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 2-Column Equipment Grid
              Expanded(
                child: GridView.builder(
                  itemCount: _equipmentOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final item = _equipmentOptions[index];
                    final name = item['name'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = _localSelected.contains(name);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _localSelected.remove(name);
                          } else {
                            _localSelected.add(name);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.paleGreen.withValues(alpha: 0.55)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Top-right Checkmark Circle
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.green
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.green
                                        : AppColors.textMuted.withValues(
                                            alpha: 0.35,
                                          ),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 15,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),

                            // Centered Icon & Name
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 42,
                                    color: isSelected
                                        ? AppColors.green
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.textDark
                                          : AppColors.textMuted,
                                    ),
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

              // Footer Status + Apply Button
              Row(
                children: [
                  const Icon(Icons.check, size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_localSelected.length} of ${_equipmentOptions.length} selected · you can change this anytime in Profile',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _isSaving ? null : _applyFilters,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Apply Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
