import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db_helper.dart';
import '../models/pantry_item.dart';
import '../database/seed_data.dart';

class PantryProvider extends ChangeNotifier {
  final List<PantryItem> _items = [];
  final Set<String> _selectedEquipment = {'Rice Cooker', 'Kettle'};
  final Set<String> _locallyAddedIds = {};

  Future<void>? _inFlightLoad;
  bool _loadStarted = false;
  final Completer<void> _loaded = Completer<void>();

  Future<void> get whenLoaded =>
      _loadStarted ? _loaded.future : Future<void>.value();

  final Set<String> _savedRecipeTitles = {};

  Set<String> get savedRecipeTitles => Set.unmodifiable(_savedRecipeTitles);

  bool isRecipeSaved(String title) => _savedRecipeTitles.contains(title);

  void toggleRecipeSaved(String title) {
    if (!_savedRecipeTitles.remove(title)) _savedRecipeTitles.add(title);
    notifyListeners();
  }

  final List<String> _shoppingList = [];

  List<String> get shoppingList => List.unmodifiable(_shoppingList);

  void addToShoppingList(Iterable<String> names) {
    for (final n in names) {
      final exists =
          _shoppingList.any((s) => s.toLowerCase() == n.toLowerCase());
      if (!exists) _shoppingList.add(n);
    }
    notifyListeners();
  }

  /// Comments 8 & 9: Match normalized names exactly (not substrings) and exclude expired items.
  List<String> missingIngredients(List ingredients) {
    final validNormalized = _items
        .where((e) => e.daysUntilExpiry == null || e.daysUntilExpiry! >= 0)
        .map((e) => _normalizeIngredient(e.name))
        .toSet();

    return [
      for (final ing in ingredients)
        if (!validNormalized.contains(_normalizeIngredient(ing.toString())))
          ing.toString(),
    ];
  }

  String _normalizeIngredient(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.endsWith('es') && s.length > 4) {
      s = s.substring(0, s.length - 2);
    } else if (s.endsWith('s') && !s.endsWith('ss') && s.length > 3) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

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

  /// Comment 3: Serialize overlapping loads by sharing the active Future.
  Future<void> loadFromSupabase() {
    _loadStarted = true;
    return _inFlightLoad ??= _loadFromSupabase().whenComplete(() {
      _inFlightLoad = null;
      if (!_loaded.isCompleted) _loaded.complete();
    });
  }

  Future<void> _loadFromSupabase() async {
    if (!_isSupabaseReady) {
      if (_items.isEmpty) {
        _items.addAll(SeedData.starterPantryItems());
        notifyListeners();
      }
      return;
    }

    try {
      final rows = await DbHelper.instance.fetchPantryItems();
      if (rows.isEmpty && _items.isEmpty) {
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
        // Comment 1: Keep items added locally while the initial fetch was in flight.
        final fetched = rows.map((r) => PantryItem.fromMap(r)).toList();
        final fetchedIds = fetched.map((e) => e.id).toSet();
        final pendingLocal = _items
            .where((item) =>
                _locallyAddedIds.contains(item.id) &&
                !fetchedIds.contains(item.id))
            .toList();

        _items
          ..clear()
          ..addAll(fetched)
          ..addAll(pendingLocal);
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

  /// Comment 4: Reconcile on timeout/error so retrying never creates duplicate rows.
  Future<void> addNewItem({
    required String name,
    required FoodCategory category,
    required double quantity,
    required String unit,
    DateTime? expiryDate,
    required StorageLocation storageLocation,
  }) async {
    final cleanName = name.trim();
    final expiryStr = expiryDate?.toIso8601String().split('T').first;

    if (_isSupabaseReady) {
      try {
        final inserted = await DbHelper.instance.insertPantryItem({
          'name': cleanName,
          'category': category.name,
          'quantity': quantity,
          'unit': unit,
          'expiry_date': expiryStr,
          'storage_location': storageLocation.name,
        });
        final item = PantryItem.fromMap(inserted);
        _locallyAddedIds.add(item.id);
        _items.add(item);
        notifyListeners();
        return;
      } catch (_) {
        final rows = await DbHelper.instance.fetchPantryItems();
        final matches = rows.map((r) => PantryItem.fromMap(r)).where((r) =>
            r.name.trim().toLowerCase() == cleanName.toLowerCase() &&
            r.quantity == quantity &&
            r.unit == unit);
        if (matches.isNotEmpty) {
          final existing = matches.last;
          if (!_items.any((i) => i.id == existing.id)) {
            _locallyAddedIds.add(existing.id);
            _items.add(existing);
            notifyListeners();
          }
          return;
        }
        rethrow;
      }
    }

    final item = PantryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      category: category,
      quantity: quantity,
      unit: unit,
      expiryDate: expiryDate,
      storageLocation: storageLocation,
    );
    _locallyAddedIds.add(item.id);
    _items.add(item);
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

  /// Comment 10: Only items expiring within 0–3 days count as urgent (not 6–7 day fresh items).
  PantryItem? get urgentItem {
    final urgent = _items.where((item) {
      final days = item.daysUntilExpiry;
      return days != null && days >= 0 && days <= 3;
    }).toList()
      ..sort((a, b) => a.daysUntilExpiry!.compareTo(b.daysUntilExpiry!));
    return urgent.isNotEmpty ? urgent.first : null;
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