import 'dart:io';

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

  void _openItemFormSheet({PantryItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PantryItemFormSheet(existing: existing),
    );
  }

  Future<void> _confirmAndDelete(PantryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Remove "${item.name}" from your pantry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alertText),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<PantryProvider>().deleteItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${item.name} from pantry')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete item: $e')),
      );
    }
  }

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
            // Header Row: "My Pantry" + Add button + Expiry Tracker + Equipment Filter
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
                  icon: Icons.add_rounded,
                  tooltip: 'Add Item',
                  filled: true,
                  onTap: () => _openItemFormSheet(),
                ),
                const SizedBox(width: 8),
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
                            'Tap the + button to add your first ingredient!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => _openItemFormSheet(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Ingredient'),
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
                            childAspectRatio: 0.84,
                          ),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _PantryItemCard(
                          item: item,
                          onTap: () => _openItemFormSheet(existing: item),
                          onDelete: () => _confirmAndDelete(item),
                        );
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
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PantryItemCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final imgPath = provider.imageForItem(item);
    final hasLocalFile =
        imgPath != null &&
        !imgPath.startsWith('http') &&
        File(imgPath).existsSync();
    final hasNetworkImg = imgPath != null && imgPath.startsWith('http');

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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? AppColors.alertBg.withValues(alpha: 0.45)
                          : AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                      image: hasLocalFile
                          ? DecorationImage(
                              image: FileImage(File(imgPath)),
                              fit: BoxFit.cover,
                            )
                          : hasNetworkImg
                          ? DecorationImage(
                              image: NetworkImage(imgPath),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: (!hasLocalFile && !hasNetworkImg)
                        ? Text(
                            _emojiForItem(item),
                            style: const TextStyle(fontSize: 36),
                          )
                        : null,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.alertText,
                        ),
                      ),
                    ),
                  ),
                ],
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
              '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit} · ${item.storageLabel}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _emojiForItem(PantryItem item) {
    final lower = item.name.toLowerCase();
    if (lower.contains('eggplant')) return '🍆';
    if (RegExp(r'\beggs?\b').hasMatch(lower)) return '🥚';
    if (lower.contains('rice')) return '🍚';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('carrot')) return '🥕';
    if (lower.contains('milk')) return '🥛';
    if (lower.contains('chicken')) return '🍗';
    if (lower.contains('siomai')) return '🥟';
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

class _PantryItemFormSheet extends StatefulWidget {
  final PantryItem? existing;

  const _PantryItemFormSheet({this.existing});

  @override
  State<_PantryItemFormSheet> createState() => _PantryItemFormSheetState();
}

class _PantryItemFormSheetState extends State<_PantryItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late FoodCategory _category;
  late StorageLocation _storage;
  late String _unit;
  late List<String> _availableUnits;
  DateTime? _expiryDate;
  bool _saving = false;

  static const List<String> _baseUnits = ['pcs', 'g', 'kg', 'mL', 'L', 'pack'];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _qtyCtrl = TextEditingController(
      text: e == null
          ? '1'
          : (e.quantity % 1 == 0
                ? e.quantity.toInt().toString()
                : e.quantity.toString()),
    );
    _category = e?.category ?? FoodCategory.vegetables;
    _storage = e?.storageLocation ?? StorageLocation.fridge;

    final existingUnit = e?.unit.trim();
    if (existingUnit != null && existingUnit.isNotEmpty) {
      _unit = existingUnit;
      _availableUnits = _baseUnits.contains(existingUnit)
          ? List<String>.from(_baseUnits)
          : [existingUnit, ..._baseUnits];
    } else {
      _unit = 'pcs';
      _availableUnits = List<String>.from(_baseUnits);
    }

    _expiryDate = e?.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final minDate = now.subtract(const Duration(days: 30));
    final maxDate = now.add(const Duration(days: 365 * 3));
    final candidate = _expiryDate ?? now.add(const Duration(days: 5));
    final initial = candidate.isBefore(minDate)
        ? minDate
        : candidate.isAfter(maxDate)
            ? maxDate
            : candidate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final provider = context.read<PantryProvider>();
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1;

    try {
      if (_isEditing) {
        await provider.updateItem(
          id: widget.existing!.id,
          name: _nameCtrl.text.trim(),
          category: _category,
          quantity: qty,
          unit: _unit,
          expiryDate: _expiryDate,
          clearExpiry: _expiryDate == null,
          storageLocation: _storage,
        );
      } else {
        await provider.addNewItem(
          name: _nameCtrl.text.trim(),
          category: _category,
          quantity: qty,
          unit: _unit,
          expiryDate: _expiryDate,
          storageLocation: _storage,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Updated ${_nameCtrl.text.trim()}'
                : 'Added ${_nameCtrl.text.trim()} to pantry',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: $e')),
      );
    }
  }

  Future<void> _deleteFromSheet() async {
    if (!_isEditing || _saving) return;
    setState(() => _saving = true);
    final item = widget.existing!;
    try {
      await context.read<PantryProvider>().deleteItem(item.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${item.name} from pantry')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Ingredient' : 'Add Ingredient',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: _saving ? null : _deleteFromSheet,
                      tooltip: 'Delete item',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.alertText,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Item Name
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Ingredient Name',
                  hintText: 'e.g., Eggs, Chicken Breast, Rice',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Enter an ingredient name'
                    : null,
              ),
              const SizedBox(height: 12),

              // Quantity + Unit Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (val) {
                        final parsed = double.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: _availableUnits
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _unit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category + Storage Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<FoodCategory>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: FoodCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.name[0].toUpperCase() + c.name.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<StorageLocation>(
                      initialValue: _storage,
                      decoration: InputDecoration(
                        labelText: 'Storage',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: StorageLocation.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.name[0].toUpperCase() + s.name.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _storage = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Expiry Date Picker
              InkWell(
                onTap: _pickExpiryDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        color: AppColors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _expiryDate == null
                              ? 'Expiry Date (Optional)'
                              : 'Expires: ${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _expiryDate == null
                                ? AppColors.textMuted
                                : AppColors.textDark,
                            fontWeight: _expiryDate == null
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_expiryDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _expiryDate = null),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Add to Pantry',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  final bool filled;

  const _CircleIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
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
            color: filled ? AppColors.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? AppColors.green : AppColors.lightGreen,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: filled ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}