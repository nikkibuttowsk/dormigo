import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/db_helper.dart';
import '../database/seed_data.dart';
import '../models/pantry_item.dart';

class PantryProvider extends ChangeNotifier {
  final List<PantryItem> _items = [];
  final Set<String> _selectedEquipment = {'Rice Cooker', 'Kettle'};
  final Set<String> _locallyAddedIds = {};

  Future<void>? _activeLoadFuture;

  Future<void> get whenLoaded => _activeLoadFuture ?? Future<void>.value();

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

  /// Match normalized names exactly (not substrings) and exclude expired items.
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

  bool get _hasAuthenticatedUser {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user != null && !user.isAnonymous;
    } catch (_) {
      return false;
    }
  }

  /// Clears stale items, restores default equipment, and invalidates any in-flight queries.
  void resetForNewSession() {
    _loadGeneration++;
    _activeLoadFuture = null;
    _items.clear();
    _locallyAddedIds.clear();
    _savedRecipeTitles.clear();
    _shoppingList.clear();
    _selectedEquipment
      ..clear()
      ..addAll({'Rice Cooker', 'Kettle'});
    notifyListeners();
  }

  /// Snapshot current in-memory items before signing in so they can migrate.
  List<PantryItem> snapshotItems() => List<PantryItem>.from(_items);

  /// Loads saved pantry items and equipment for the active session.
  /// - Guests (no authenticated user) receive starter items strictly in memory.
  /// - Authenticated users load their own rows from Supabase and seed starter
  ///   items once per account (`pantry_seeded` metadata flag).
  Future<void> loadFromSupabase({
    bool allowAnonymous = false,
    List<PantryItem> guestItemsToMigrate = const [],
  }) {
    final future = _runLoadFromSupabase(
      allowAnonymous: allowAnonymous,
      guestItemsToMigrate: guestItemsToMigrate,
    );
    _activeLoadFuture = future;
    return future;
  }

  Future<void> _runLoadFromSupabase({
    bool allowAnonymous = false,
    List<PantryItem> guestItemsToMigrate = const [],
  }) async {
    final generation = ++_loadGeneration;

    if (!_hasAuthenticatedUser) {
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
      final currentUser = client.auth.currentUser;
      if (currentUser == null || currentUser.isAnonymous) return;

      // Migrate guest items into the authenticated user's Supabase pantry
      if (guestItemsToMigrate.isNotEmpty) {
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

      final alreadySeeded =
          currentUser.userMetadata?['pantry_seeded'] == true;

      if (rows.isEmpty && !alreadySeeded) {
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

          // Mark account as seeded so clearing the pantry later won't re-seed
          await client.auth.updateUser(
            UserAttributes(data: {'pantry_seeded': true}),
          );
          if (generation != _loadGeneration) return;

          _items
            ..clear()
            ..addAll(seeded);
        } finally {
          _isSeeding = false;
        }
      } else {
        if (!alreadySeeded) {
          // Existing user already has items; mark seeded so future empty states stay empty
          unawaited(
            client.auth.updateUser(
              UserAttributes(data: {'pantry_seeded': true}),
            ),
          );
        }

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

  final Map<String, String> _localImageByItemId = {};
  final Map<String, String> _batchNotesByItemId = {};

  String? imageForItem(PantryItem item) =>
      item.imagePath ?? _localImageByItemId[item.id];

  String? batchNotesForItem(PantryItem item) =>
      item.batchNotes ?? _batchNotesByItemId[item.id];

  String _formatDateLabel(DateTime? d) {
    if (d == null) return 'no expiry';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'exp ${months[d.month - 1]} ${d.day}';
  }

  String _qtyLabel(double q, String unit) =>
      '${q % 1 == 0 ? q.toInt() : q} $unit';

  Future<void> addNewItem({
    required String name,
    required FoodCategory category,
    required double quantity,
    required String unit,
    DateTime? expiryDate,
    required StorageLocation storageLocation,
    String? imagePath,
  }) async {
    final generation = _loadGeneration;
    final cleanName = name.trim();
    final normNew = _normalizeIngredient(cleanName);

    // Check if an active item with the same ingredient name & unit already exists
    final existingIdx = _items.indexWhere(
      (i) =>
          _normalizeIngredient(i.name) == normNew &&
          i.unit.toLowerCase() == unit.toLowerCase(),
    );

    if (existingIdx != -1) {
      final existing = _items[existingIdx];
      final combinedQty = existing.quantity + quantity;

      // Pick the earliest (soonest) expiry date so alerts fire accurately
      DateTime? mergedExpiry;
      if (existing.expiryDate == null) {
        mergedExpiry = expiryDate;
      } else if (expiryDate == null) {
        mergedExpiry = existing.expiryDate;
      } else {
        mergedExpiry = existing.expiryDate!.isBefore(expiryDate)
            ? existing.expiryDate
            : expiryDate;
      }

      // Build graceful batch summary if the two entries have different expiry dates
      final existingDay = existing.expiryDate?.toIso8601String().split('T').first;
      final newDay = expiryDate?.toIso8601String().split('T').first;
      String? updatedNotes = batchNotesForItem(existing);

      if (existingDay != newDay) {
        final prevSummary = updatedNotes ??
            '${_qtyLabel(existing.quantity, existing.unit)} (${_formatDateLabel(existing.expiryDate)})';
        final addedSummary =
            '${_qtyLabel(quantity, unit)} (${_formatDateLabel(expiryDate)})';
        updatedNotes = '$prevSummary · $addedSummary';
      }

      final resolvedImage = imagePath ?? imageForItem(existing);

      await updateItem(
        id: existing.id,
        name: existing.name,
        category: existing.category,
        quantity: combinedQty,
        unit: existing.unit,
        expiryDate: mergedExpiry,
        clearExpiry: mergedExpiry == null,
        storageLocation: existing.storageLocation,
      );

      final refreshedIdx = _items.indexWhere((i) => i.id == existing.id);
      if (refreshedIdx != -1) {
        if (resolvedImage != null) {
          _localImageByItemId[existing.id] = resolvedImage;
        }
        if (updatedNotes != null) {
          _batchNotesByItemId[existing.id] = updatedNotes;
        }
        _items[refreshedIdx] = _items[refreshedIdx].copyWith(
          imagePath: resolvedImage,
          batchNotes: updatedNotes,
        );
        notifyListeners();
      }
      return;
    }

    final expiryStr = expiryDate?.toIso8601String().split('T').first;

    if (_hasAuthenticatedUser) {
      try {
        final inserted = await DbHelper.instance.insertPantryItem({
          'name': cleanName,
          'category': category.name,
          'quantity': quantity,
          'unit': unit,
          'expiry_date': expiryStr,
          'storage_location': storageLocation.name,
        });
        if (generation != _loadGeneration) return;
        final item = PantryItem.fromMap(inserted).copyWith(
          imagePath: imagePath,
        );
        if (imagePath != null) {
          _localImageByItemId[item.id] = imagePath;
        }
        _locallyAddedIds.add(item.id);
        _items.add(item);
      } catch (_) {
        if (generation != _loadGeneration) return;
        final rows = await DbHelper.instance.fetchPantryItems();
        if (generation != _loadGeneration) return;
        final matches = rows.map((r) => PantryItem.fromMap(r)).where((r) =>
            r.name.trim().toLowerCase() == cleanName.toLowerCase() &&
            r.quantity == quantity &&
            r.unit == unit);
        if (matches.isNotEmpty) {
          final existing = matches.last.copyWith(imagePath: imagePath);
          if (imagePath != null) {
            _localImageByItemId[existing.id] = imagePath;
          }
          if (!_items.any((i) => i.id == existing.id)) {
            _locallyAddedIds.add(existing.id);
            _items.add(existing);
            notifyListeners();
          }
          return;
        }
        rethrow;
      }
    } else {
      final localItem = PantryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: cleanName,
        category: category,
        quantity: quantity,
        unit: unit,
        expiryDate: expiryDate,
        storageLocation: storageLocation,
        imagePath: imagePath,
      );
      if (imagePath != null) {
        _localImageByItemId[localItem.id] = imagePath;
      }
      _locallyAddedIds.add(localItem.id);
      _items.add(localItem);
    }
    notifyListeners();
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required FoodCategory category,
    required double quantity,
    required String unit,
    DateTime? expiryDate,
    bool clearExpiry = false,
    required StorageLocation storageLocation,
  }) async {
    final generation = _loadGeneration;
    final cleanName = name.trim();
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final updatedLocal = _items[index].copyWith(
      name: cleanName,
      category: category,
      quantity: quantity,
      unit: unit,
      expiryDate: expiryDate,
      clearExpiry: clearExpiry,
      storageLocation: storageLocation,
    );

    if (_hasAuthenticatedUser) {
      final expiryStr = clearExpiry
          ? null
          : updatedLocal.expiryDate?.toIso8601String().split('T').first;
      final row = await DbHelper.instance.updatePantryItem(id, {
        'name': cleanName,
        'category': category.name,
        'quantity': quantity,
        'unit': unit,
        'expiry_date': expiryStr,
        'storage_location': storageLocation.name,
      });
      if (generation != _loadGeneration) return;
      final refreshedIndex = _items.indexWhere((i) => i.id == id);
      if (refreshedIndex != -1) {
        _items[refreshedIndex] = PantryItem.fromMap(row);
      }
    } else {
      _items[index] = updatedLocal;
    }
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final generation = _loadGeneration;
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final removed = _items.removeAt(index);
    _locallyAddedIds.remove(id);
    notifyListeners();

    if (_hasAuthenticatedUser) {
      try {
        await DbHelper.instance.deletePantryItem(id);
      } catch (e) {
        if (generation == _loadGeneration) {
          _items.insert(index.clamp(0, _items.length), removed);
          notifyListeners();
        }
        rethrow;
      }
    }
  }

  Future<void> resolveItemStatus(String id, String status) async {
    final generation = _loadGeneration;
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final removed = _items.removeAt(index);
    _locallyAddedIds.remove(id);
    notifyListeners();

    if (_hasAuthenticatedUser) {
      try {
        await DbHelper.instance.updateItemStatus(id, status);
      } catch (e) {
        if (generation == _loadGeneration) {
          _items.insert(index.clamp(0, _items.length), removed);
          notifyListeners();
        }
        rethrow;
      }
    }
  }

  Future<void> updateEquipment(Set<String> equipment) async {
    final generation = _loadGeneration;
    if (_hasAuthenticatedUser) {
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