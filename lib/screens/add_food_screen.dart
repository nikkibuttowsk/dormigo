import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../utils/theme.dart';

enum AddMode { photo, upload, manual }

class DraftFood {
  DraftFood({
    required this.name,
    this.quantity = 1,
    this.unit = 'pcs',
    DateTime? expiry,
    FoodCategory? category,
    this.storage = StorageLocation.fridge,
    this.imagePath,
  })  : expiry = expiry ?? DateTime.now().add(const Duration(days: 7)),
        category = category ?? _inferCategory(name);

  String name;
  int quantity;
  String unit;
  DateTime expiry;
  FoodCategory category;
  StorageLocation storage;
  String? imagePath;

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(expiry.year, expiry.month, expiry.day);
    return end.difference(today).inDays;
  }

  static FoodCategory _inferCategory(String raw) {
    final n = raw.toLowerCase();
    if (n.contains('egg') ||
        n.contains('chicken') ||
        n.contains('meat') ||
        n.contains('pork') ||
        n.contains('beef') ||
        n.contains('fish') ||
        n.contains('tofu') ||
        n.contains('siomai')) {
      return FoodCategory.protein;
    }
    if (n.contains('milk') ||
        n.contains('cheese') ||
        n.contains('yogurt') ||
        n.contains('butter')) {
      return FoodCategory.dairy;
    }
    if (n.contains('rice') ||
        n.contains('bread') ||
        n.contains('pasta') ||
        n.contains('noodle') ||
        n.contains('oat')) {
      return FoodCategory.grains;
    }
    if (n.contains('tomato') ||
        n.contains('carrot') ||
        n.contains('onion') ||
        n.contains('garlic') ||
        n.contains('cabbage') ||
        n.contains('lettuce') ||
        n.contains('potato')) {
      return FoodCategory.vegetables;
    }
    return FoodCategory.other;
  }
}

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final List<DraftFood> _items = [];

  AddMode _mode = AddMode.photo;
  StorageLocation _defaultStorage = StorageLocation.fridge;
  XFile? _image;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        setState(() {
          _image = file;
          // Attach the photo to any already-listed draft items without a photo
          for (final draft in _items) {
            draft.imagePath ??= file.path;
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  void _addItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _items.add(
        DraftFood(
          name: name,
          storage: _defaultStorage,
          imagePath: _image?.path,
        ),
      );
      _nameController.clear();
    });
  }

  Future<void> _pickExpiry(DraftFood item) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item.expiry,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => item.expiry = picked);
  }

  void _changeQuantity(DraftFood item, int delta) {
    setState(() {
      item.quantity += delta;
      if (item.quantity < 1) _items.remove(item);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final pendingText = _nameController.text.trim();
    if (pendingText.isNotEmpty) {
      _items.add(
        DraftFood(
          name: pendingText,
          storage: _defaultStorage,
          imagePath: _image?.path,
        ),
      );
      _nameController.clear();
    }

    if (_items.isEmpty) return;

    _nameFocusNode.unfocus();
    setState(() => _isSaving = true);
    final provider = context.read<PantryProvider>();

    try {
      for (final draft in _items) {
        await provider.addNewItem(
          name: draft.name,
          category: draft.category,
          quantity: draft.quantity.toDouble(),
          unit: draft.unit,
          expiryDate: draft.expiry,
          storageLocation: draft.storage,
          imagePath: draft.imagePath ?? _image?.path,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${_items.length} item${_items.length == 1 ? '' : 's'} to your pantry!',
          ),
        ),
      );
      // Pop without returning _items so the caller does not insert duplicates
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save items: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.deepGreen,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildPreview()),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (screenHeight - bottomInset) * 0.65,
              ),
              child: _buildSheet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modeChip('Photo', AddMode.photo),
                      _modeChip('Upload', AddMode.upload),
                      _modeChip('Manual', AddMode.manual),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, AddMode mode) {
    final selected = _mode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.green : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_mode == AddMode.manual) {
      return const Center(
        child: Text(
          'Type what you bought below',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      );
    }

    final isPhoto = _mode == AddMode.photo;
    final source = isPhoto ? ImageSource.camera : ImageSource.gallery;

    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.green,
    );

    if (_image != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_image!.path), fit: BoxFit.cover),
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              style: buttonStyle,
              onPressed: () => _pickImage(source),
              icon: const Icon(Icons.refresh),
              label: Text(isPhoto ? 'Retake' : 'Change photo'),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPhoto ? Icons.photo_camera_outlined : Icons.photo_library_outlined,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: buttonStyle,
            onPressed: () => _pickImage(source),
            icon: Icon(isPhoto ? Icons.photo_camera : Icons.photo_library),
            label: Text(isPhoto ? 'Take photo' : 'Choose from gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildSheet() {
    final count = _items.length;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Items to add',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  // Default storage selector pills
                  for (final loc in StorageLocation.values)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        label: Text(
                          loc.name[0].toUpperCase() + loc.name.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _defaultStorage == loc
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                        ),
                        selected: _defaultStorage == loc,
                        selectedColor: AppColors.green,
                        backgroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) =>
                            setState(() => _defaultStorage = loc),
                      ),
                    ),
                ],
              ),
              const Text(
                'Set the amount, storage, and expiry date, then add to pantry',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              for (final item in _items) _buildItemRow(item),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addItem(),
                      decoration: InputDecoration(
                        hintText: 'Item name, e.g. Eggs',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addItem,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.green,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, value, _) {
                    final hasTypedText = value.text.trim().isNotEmpty;
                    final totalToAdd = count + (hasTypedText ? 1 : 0);
                    return ElevatedButton(
                      onPressed: (_isSaving || totalToAdd == 0) ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              totalToAdd == 0
                                  ? 'Add items to Pantry'
                                  : 'Add $totalToAdd item${totalToAdd == 1 ? '' : 's'} to Pantry',
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

  Widget _buildItemRow(DraftFood item) {
    final days = item.daysLeft;
    final expiryText = days < 0
        ? 'Expired'
        : days == 0
            ? 'Expires today'
            : 'Expires in $days day${days == 1 ? '' : 's'}';
    final imgPath = item.imagePath ?? _image?.path;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.paleGreen,
            backgroundImage: (imgPath != null && File(imgPath).existsSync())
                ? FileImage(File(imgPath))
                : null,
            child: (imgPath == null || !File(imgPath).existsSync())
                ? const Icon(Icons.restaurant, size: 18, color: AppColors.green)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => _pickExpiry(item),
                      child: Text(
                        expiryText,
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          color: days <= 2
                              ? AppColors.alertText
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          const locs = StorageLocation.values;
                          item.storage =
                              locs[(item.storage.index + 1) % locs.length];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.storage.name[0].toUpperCase() +
                              item.storage.name.substring(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.outlined(
            visualDensity: VisualDensity.compact,
            onPressed: () => _changeQuantity(item, -1),
            icon: const Icon(Icons.remove, size: 18),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton.outlined(
            visualDensity: VisualDensity.compact,
            onPressed: () => _changeQuantity(item, 1),
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}