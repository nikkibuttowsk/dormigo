import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/theme.dart';

enum AddMode { photo, upload, manual }

/// A food item the user is about to add. Later this becomes the FoodItem
/// model that gets saved in the database.
class DraftFood {
  DraftFood({required this.name, this.quantity = 1, DateTime? expiry})
      : expiry = expiry ?? DateTime.now().add(const Duration(days: 7));

  String name;
  int quantity;
  DateTime expiry;

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(expiry.year, expiry.month, expiry.day);
    return end.difference(today).inDays;
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
  final List<DraftFood> _items = [];

  AddMode _mode = AddMode.photo;
  XFile? _image;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) setState(() => _image = file);
    } catch (e) {
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
      _items.add(DraftFood(name: name));
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

  void _save() => Navigator.pop(context, _items);

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.deepGreen,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _buildTopBar(),
              // Hide the preview while typing so the keyboard has room.
              if (!keyboardOpen) Expanded(child: _buildPreview()),
              if (keyboardOpen)
                Expanded(child: _buildSheet())
              else
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: constraints.maxHeight * 0.55),
                  child: _buildSheet(),
                ),
            ],
          );
        },
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
            const SizedBox(width: 48), // keeps the toggle centred
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
              const Text(
                'Items to add',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Text(
                'Set the amount and expiry date, then add to pantry',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              for (final item in _items) _buildItemRow(item),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
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
              ElevatedButton(
                onPressed: count == 0 ? null : _save,
                child: Text(
                  count == 0
                      ? 'Add items to Pantry'
                      : 'Add $count item${count == 1 ? '' : 's'} to Pantry',
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.paleGreen,
            child: Icon(Icons.restaurant, size: 18, color: AppColors.green),
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
                // Tap the expiry text to pick a date.
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