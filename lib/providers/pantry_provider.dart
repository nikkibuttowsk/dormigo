import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/db_helper.dart';
import '../database/seed_data.dart';
import '../models/pantry_item.dart';

class PantryProvider extends ChangeNotifier {
  final List<PantryItem> _items = [];
  final Set<String> _selectedEquipment = {'Rice Cooker', 'Kettle'};

  int _loadGeneration = 0;
  bool _isSeeding = false;

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

  /// Clears stale items, restores default equipment, and invalidates any in-flight queries.
  void resetForNewSession() {
    _loadGeneration++;
    _items.clear();
    _selectedEquipment
      ..clear()
      ..addAll({'Rice Cooker', 'Kettle'});
    notifyListeners();
  }

  /// Snapshot current in-memory items before signing in so they can migrate.
  List<PantryItem> snapshotItems() => List<PantryItem>.from(_items);

  /// Loads saved pantry items and equipment for the active session.
  /// - [allowAnonymous]: if false, will NOT trigger an anonymous sign-in race.
  /// - [guestItemsToMigrate]: items captured from a guest session before signing in.
  Future<void> loadFromSupabase({
    bool allowAnonymous = false,
    List<PantryItem> guestItemsToMigrate = const [],
  }) async {
    final generation = ++_loadGeneration;

    if (!_isSupabaseReady) {
      if (generation != _loadGeneration) return;
      _items
        ..clear()
        ..addAll(
          guestItemsToMigrate.isNotEmpty
              ? guestItemsToMigrate
              : SeedData.starterPantryItems(),
        );
      notifyListeners();
      return;
    }

    try {
      final client = Supabase.instance.client;
      User? currentUser = client.auth.currentUser;

      // Do not create an anonymous session during an authenticated login/signup flow
      if (currentUser == null && !allowAnonymous) {
        return;
      }

      if (generation != _loadGeneration) return;

      // Migrate guest items into the authenticated user's Supabase pantry
      if (guestItemsToMigrate.isNotEmpty &&
          currentUser != null &&
          !currentUser.isAnonymous) {
        for (final item in guestItemsToMigrate) {
          if (generation != _loadGeneration) return;
          await DbHelper.instance.insertPantryItem({
            'name': item.name,
            'category': item.category.name,
            'quantity': item.quantity,
            'unit': item.unit,
            'expiry_date': item.expiryDate?.toIso8601String().split('T').first,
            'storage_location': item.storageLocation.name,
          });
        }
      }

      if (generation != _loadGeneration) return;

      final rows = await DbHelper.instance.fetchPantryItems();
      if (generation != _loadGeneration) return;

      if (rows.isEmpty) {
        // Prevent concurrent calls from inserting duplicate starter items
        if (_isSeeding) return;
        _isSeeding = true;
        try {
          final seeded = <PantryItem>[];
          for (final seed in SeedData.starterPantryItems()) {
            if (generation != _loadGeneration) return;
            final inserted = await DbHelper.instance.insertPantryItem({
              'name': seed.name,
              'category': seed.category.name,
              'quantity': seed.quantity,
              'unit': seed.unit,
              'expiry_date':
                  seed.expiryDate?.toIso8601String().split('T').first,
              'storage_location': seed.storageLocation.name,
            });
            seeded.add(PantryItem.fromMap(inserted));
          }
          if (generation != _loadGeneration) return;
          _items
            ..clear()
            ..addAll(seeded);
        } finally {
          _isSeeding = false;
        }
      } else {
        _items
          ..clear()
          ..addAll(rows.map((r) => PantryItem.fromMap(r)));
      }

      final equip = await DbHelper.instance.fetchUserEquipment();
      if (generation != _loadGeneration) return;

      _selectedEquipment
        ..clear()
        ..addAll(equip);
      notifyListeners();
    } catch (e) {
      debugPrint('Supabase load fallback to local seed: $e');
      if (generation != _loadGeneration) return;
      _items
        ..clear()
        ..addAll(
          guestItemsToMigrate.isNotEmpty
              ? guestItemsToMigrate
              : SeedData.starterPantryItems(),
        );
      notifyListeners();
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
    final generation = _loadGeneration;

    if (_isSupabaseReady && Supabase.instance.client.auth.currentUser != null) {
      final inserted = await DbHelper.instance.insertPantryItem({
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'unit': unit,
        'expiry_date': expiryDate?.toIso8601String().split('T').first,
        'storage_location': storageLocation.name,
      });
      if (generation != _loadGeneration) return;
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
    final generation = _loadGeneration;
    if (_isSupabaseReady && Supabase.instance.client.auth.currentUser != null) {
      await DbHelper.instance.saveUserEquipment(equipment.toList());
      if (generation != _loadGeneration) return;
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