import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db_helper.dart';
import '../models/pantry_item.dart';
import '../database/seed_data.dart';

class PantryProvider extends ChangeNotifier {
  final List<PantryItem> _items = [];
  final Set<String> _selectedEquipment = {'Rice Cooker', 'Kettle'};

  static const List<String> allEquipment = [
    'Rice Cooker',
    'Kettle',
    'Microwave',
    'Hot Plate',
    'Toaster',
    'Electric Pan',
  ];

  List<PantryItem> get items => List.unmodifiable(_items);
  Set<String> get selectedEquipment => Set.unmodifiable(_selectedEquipment);

  bool get _isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Loads saved pantry items and equipment from Supabase
  Future<void> loadFromSupabase() async {
    if (!_isSupabaseReady) {
      if (_items.isEmpty) {
        _items.addAll(SeedData.starterPantryItems());
        notifyListeners();
      }
      return;
    }

    try {
      final rows = await DbHelper.instance.fetchPantryItems();
      if (rows.isEmpty) {
        // First-time user: seed starter dorm items into Supabase
        for (final seed in SeedData.starterPantryItems()) {
          final inserted = await DbHelper.instance.insertPantryItem({
            'name': seed.name,
            'category': seed.category.name,
            'quantity': seed.quantity,
            'unit': seed.unit,
            'expiry_date': seed.expiryDate?.toIso8601String().split('T').first,
            'storage_location': seed.storageLocation.name,
          });
          _items.add(PantryItem.fromMap(inserted));
        }
      } else {
        _items
          ..clear()
          ..addAll(rows.map((r) => PantryItem.fromMap(r)));
      }

      final equip = await DbHelper.instance.fetchUserEquipment();
      _selectedEquipment
        ..clear()
        ..addAll(equip);
      notifyListeners();
    } catch (e) {
      debugPrint('Supabase load fallback to local seed: $e');
      if (_items.isEmpty) {
        _items.addAll(SeedData.starterPantryItems());
        notifyListeners();
      }
    }
  }

  /// Adds a new food item (syncs to Supabase + updates UI immediately)
  Future<void> addNewItem({
    required String name,
    required FoodCategory category,
    required double quantity,
    required String unit,
    DateTime? expiryDate,
    required StorageLocation storageLocation,
  }) async {
    if (_isSupabaseReady) {
      final inserted = await DbHelper.instance.insertPantryItem({
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'unit': unit,
        'expiry_date': expiryDate?.toIso8601String().split('T').first,
        'storage_location': storageLocation.name,
      });
      _items.add(PantryItem.fromMap(inserted));
    } else {
      _items.add(
        PantryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          category: category,
          quantity: quantity,
          unit: unit,
          expiryDate: expiryDate,
          storageLocation: storageLocation,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> updateEquipment(Set<String> equipment) async {
    if (_isSupabaseReady) {
      await DbHelper.instance.saveUserEquipment(equipment.toList());
    }
    _selectedEquipment
      ..clear()
      ..addAll(equipment);
    notifyListeners();
  }

  List<PantryItem> get expiringThisWeek {
    final list = _items.where((item) {
      final days = item.daysUntilExpiry;
      return days != null && days >= 0 && days <= 7;
    }).toList();
    list.sort((a, b) => a.daysUntilExpiry!.compareTo(b.daysUntilExpiry!));
    return list;
  }

  List<PantryItem> get expiringLater {
    return _items.where((item) {
      final days = item.daysUntilExpiry;
      return days == null || days > 7;
    }).toList();
  }

  List<PantryItem> get expiredItems {
    return _items.where((item) {
      final days = item.daysUntilExpiry;
      return days != null && days < 0;
    }).toList();
  }

  PantryItem? get urgentItem {
    final thisWeek = expiringThisWeek;
    return thisWeek.isNotEmpty ? thisWeek.first : null;
  }

  String getAmigoShelfLifeTip(String foodName, StorageLocation storage) {
    final name = foodName.trim().toLowerCase();
    if (name.contains('egg')) {
      return storage == StorageLocation.fridge
          ? "Amigo's tip: eggs usually last 3 weeks in the fridge."
          : "Amigo's tip: store eggs in the fridge to keep them fresh up to 3 weeks.";
    }
    if (name.contains('milk')) {
      return "Amigo's tip: opened milk lasts 5–7 days in the fridge.";
    }
    if (name.contains('rice')) {
      return "Amigo's tip: uncooked rice stays fresh for 6+ months in a dry shelf container.";
    }
    if (name.contains('chicken') || name.contains('meat')) {
      return storage == StorageLocation.freezer
          ? "Amigo's tip: frozen chicken keeps well for up to 2–3 months."
          : "Amigo's tip: use raw chicken within 1–2 days if kept in the fridge.";
    }
    return "Amigo's tip: check packaging dates and store perishables in the fridge.";
  }
}