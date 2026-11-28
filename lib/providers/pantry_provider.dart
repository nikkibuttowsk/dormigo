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
  final Map<String, String> _localImageByItemId = {};
  final Map<String, int> _itemMutationVersion = {};

  Future<void> _mutationChain = Future<void>.value();
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
    if (s.endsWith('ies') && s.length > 4) {
      return '${s.substring(0, s.length - 3)}y';
    }
    if (s.endsWith('es') && s.length > 4) {
      if (s.endsWith('shes') ||
          s.endsWith('ches') ||
          s.endsWith('xes') ||
          s.endsWith('sses') ||
          s.endsWith('zes') ||
          s.endsWith('oes')) {
        return s.substring(0, s.length - 2);
      }
      // Regular silent-e plural: grapes -> grape, apples -> apple
      return s.substring(0, s.length - 1);
    }
    if (s.endsWith('s') && !s.endsWith('ss') && s.length > 3) {
      return s.substring(0, s.length - 1);
    }
    return s;
  }

  String? _dateKey(DateTime? d) => d?.toIso8601String().split('T').first;

  bool _isSameBatch({
    required PantryItem item,
    required String normalizedName,
    required String unit,
    required StorageLocation storageLocation,
    required DateTime? expiryDate,
  }) {
    return _normalizeIngredient(item.name) == normalizedName &&
        item.unit.toLowerCase() == unit.toLowerCase() &&
        item.storageLocation == storageLocation &&
        _dateKey(item.expiryDate) == _dateKey(expiryDate);
  }

  String? imageForItem(PantryItem item) =>
      item.imagePath ?? _localImageByItemId[item.id];

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

  /// Serializes pantry mutations so concurrent adds/updates cannot race.
  Future<T> _enqueueMutation<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _mutationChain = _mutationChain.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// Clears stale items, restores default equipment, and invalidates in-flight queries.
  void resetForNewSession() {
    _loadGeneration++;
    _activeLoadFuture = null;
    _items.clear();
    _locallyAddedIds.clear();
    _localImageByItemId.clear();
    _itemMutationVersion.clear();
    _savedRecipeTitles.clear();
    _shoppingList.clear();
    _selectedEquipment
      ..clear()
      ..addAll({'Rice Cooker', 'Kettle'});
    notifyListeners();
  }

  /// Snapshot current in-memory items before signing in so they can migrate.
  List<PantryItem> snapshotItems() => List<PantryItem>.from(_items);

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

      if (guestItemsToMigrate.isNotEmpty) {
        for (final item in guestItemsToMigrate) {
          if (generation != _loadGeneration) return;
          await DbHelper.instance.insertPantryItem({
            'name': item.name,
            'category': item.category.name,
            'quantity': item.quantity,
            'unit': item.unit,
            'expiry_date': _dateKey(item.expiryDate),
            'storage_location': item.storageLocation.name,
            if (item.imagePath != null) 'image_url': item.imagePath,
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
              'expiry_date': _dateKey(seed.expiryDate),
              'storage_location': seed.storageLocation.name,
            });
            seeded.add(PantryItem.fromMap(inserted));
          }
          if (generation != _loadGeneration) return;

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
          unawaited(
            client.auth.updateUser(
              UserAttributes(data: {'pantry_seeded': true}),
            ),
          );
        }

        final fetched = rows.map((r) {
          final parsed = PantryItem.fromMap(r);
          final cachedImg = _localImageByItemId[parsed.id];
          return parsed.imagePath == null && cachedImg != null
              ? parsed.copyWith(imagePath: cachedImg)
              : parsed;
        }).toList();

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

  Future<void> addNewItem({
    required String name,
    required FoodCategory category,
    required double quantity,
    required String unit,
    DateTime? expiryDate,
    required StorageLocation storageLocation,
    String? imagePath,
  }) {
    return _enqueueMutation(() async {
      final startGeneration = _loadGeneration;
      final cleanName = name.trim();
      final normNew = _normalizeIngredient(cleanName);
      final expiryStr = _dateKey(expiryDate);

      if (_hasAuthenticatedUser) {
        final remoteRows = await DbHelper.instance.fetchPantryItems();
        if (startGeneration != _loadGeneration) {
          unawaited(loadFromSupabase());
          return;
        }

        final remoteItems = remoteRows.map((r) => PantryItem.fromMap(r)).toList();
        final match = remoteItems.cast<PantryItem?>().firstWhere(
              (item) =>
                  item != null &&
                  _isSameBatch(
                    item: item,
                    normalizedName: normNew,
                    unit: unit,
                    storageLocation: storageLocation,
                    expiryDate: expiryDate,
                  ),
              orElse: () => null,
            );

        if (match != null) {
          final mergedQty = match.quantity + quantity;
          final resolvedImg = imagePath ?? imageForItem(match);
          final updatedRow = await DbHelper.instance.updatePantryItem(
            match.id,
            {
              'quantity': mergedQty,
              'image_url': ?resolvedImg,
            },
          );
          final updatedItem = PantryItem.fromMap(updatedRow).copyWith(
            imagePath: resolvedImg,
          );
          if (resolvedImg != null) {
            _localImageByItemId[updatedItem.id] = resolvedImg;
          }
          final idx = _items.indexWhere((i) => i.id == updatedItem.id);
          if (idx != -1) {
            _items[idx] = updatedItem;
          } else {
            _items.add(updatedItem);
          }
          notifyListeners();
          if (startGeneration != _loadGeneration) {
            unawaited(loadFromSupabase());
          }
          return;
        }

        final inserted = await DbHelper.instance.insertPantryItem({
          'name': cleanName,
          'category': category.name,
          'quantity': quantity,
          'unit': unit,
          'expiry_date': expiryStr,
          'storage_location': storageLocation.name,
          'image_url': ?imagePath,
        });

        final item = PantryItem.fromMap(inserted).copyWith(
          imagePath: imagePath,
        );
        if (imagePath != null) {
          _localImageByItemId[item.id] = imagePath;
        }
        _locallyAddedIds.add(item.id);
        final existingIdx = _items.indexWhere((i) => i.id == item.id);
        if (existingIdx != -1) {
          _items[existingIdx] = item;
        } else {
          _items.add(item);
        }
        notifyListeners();

        if (startGeneration != _loadGeneration) {
          unawaited(loadFromSupabase());
        }
      } else {
        final existingIdx = _items.indexWhere(
          (i) => _isSameBatch(
            item: i,
            normalizedName: normNew,
            unit: unit,
            storageLocation: storageLocation,
            expiryDate: expiryDate,
          ),
        );

        if (existingIdx != -1) {
          final existing = _items[existingIdx];
          final resolvedImg = imagePath ?? imageForItem(existing);
          if (resolvedImg != null) {
            _localImageByItemId[existing.id] = resolvedImg;
          }
          _items[existingIdx] = existing.copyWith(
            quantity: existing.quantity + quantity,
            imagePath: resolvedImg,
          );
        } else {
          final localItem = PantryItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
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
    });
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
    String? imagePath,
  }) {
    return _enqueueMutation(() async {
      final startGeneration = _loadGeneration;
      final version = (_itemMutationVersion[id] ?? 0) + 1;
      _itemMutationVersion[id] = version;

      final cleanName = name.trim();
      final normNew = _normalizeIngredient(cleanName);
      final targetExpiry = clearExpiry ? null : expiryDate;

      final index = _items.indexWhere((i) => i.id == id);
      if (index == -1) return;

      final current = _items[index];
      final resolvedImg = imagePath ?? imageForItem(current);

      // Check if another active item already matches this edited batch identity
      final duplicateIdx = _items.indexWhere(
        (i) =>
            i.id != id &&
            _isSameBatch(
              item: i,
              normalizedName: normNew,
              unit: unit,
              storageLocation: storageLocation,
              expiryDate: targetExpiry,
            ),
      );

      if (duplicateIdx != -1) {
        final target = _items[duplicateIdx];
        final mergedQty = target.quantity + quantity;
        final mergedImg = resolvedImg ?? imageForItem(target);

        if (_hasAuthenticatedUser) {
          final updatedRow = await DbHelper.instance.updatePantryItem(
            target.id,
            {
              'quantity': mergedQty,
              'image_url': ?mergedImg,
            },
          );
          await DbHelper.instance.deletePantryItem(id);
          if (_itemMutationVersion[id] != version) return;

          final updatedTarget = PantryItem.fromMap(updatedRow).copyWith(
            imagePath: mergedImg,
          );
          if (mergedImg != null) {
            _localImageByItemId[target.id] = mergedImg;
          }
          _localImageByItemId.remove(id);
          _locallyAddedIds.remove(id);
          _items.removeWhere((i) => i.id == id);
          final targetRefreshedIdx =
              _items.indexWhere((i) => i.id == target.id);
          if (targetRefreshedIdx != -1) {
            _items[targetRefreshedIdx] = updatedTarget;
          }
          notifyListeners();
          if (startGeneration != _loadGeneration) {
            unawaited(loadFromSupabase());
          }
        } else {
          if (mergedImg != null) {
            _localImageByItemId[target.id] = mergedImg;
          }
          _localImageByItemId.remove(id);
          _locallyAddedIds.remove(id);
          _items[duplicateIdx] = target.copyWith(
            quantity: mergedQty,
            imagePath: mergedImg,
          );
          _items.removeWhere((i) => i.id == id);
          notifyListeners();
        }
        return;
      }

      final updatedLocal = current.copyWith(
        name: cleanName,
        category: category,
        quantity: quantity,
        unit: unit,
        expiryDate: targetExpiry,
        clearExpiry: clearExpiry,
        storageLocation: storageLocation,
        imagePath: resolvedImg,
      );

      if (_hasAuthenticatedUser) {
        final row = await DbHelper.instance.updatePantryItem(id, {
          'name': cleanName,
          'category': category.name,
          'quantity': quantity,
          'unit': unit,
          'expiry_date': _dateKey(targetExpiry),
          'storage_location': storageLocation.name,
          'image_url': ?resolvedImg,
        });
        if (_itemMutationVersion[id] != version) return;

        final serverItem = PantryItem.fromMap(row).copyWith(
          imagePath: resolvedImg,
        );
        if (resolvedImg != null) {
          _localImageByItemId[id] = resolvedImg;
        }
        final refreshedIndex = _items.indexWhere((i) => i.id == id);
        if (refreshedIndex != -1) {
          _items[refreshedIndex] = serverItem;
        } else {
          _items.add(serverItem);
        }
        notifyListeners();
        if (startGeneration != _loadGeneration) {
          unawaited(loadFromSupabase());
        }
      } else {
        if (resolvedImg != null) {
          _localImageByItemId[id] = resolvedImg;
        }
        _items[index] = updatedLocal;
        notifyListeners();
      }
    });
  }

  Future<void> deleteItem(String id) {
    return _enqueueMutation(() async {
      final generation = _loadGeneration;
      final index = _items.indexWhere((i) => i.id == id);
      if (index == -1) return;

      final removed = _items.removeAt(index);
      final removedImg = _localImageByItemId.remove(id);
      _locallyAddedIds.remove(id);
      notifyListeners();

      if (_hasAuthenticatedUser) {
        try {
          await DbHelper.instance.deletePantryItem(id);
        } catch (e) {
          // Reconcile against server state before restoring to avoid phantom items
          // when the delete actually committed before a timeout/network drop.
          try {
            final serverRows = await DbHelper.instance.fetchPantryItems();
            final stillActive = serverRows.any((r) => r['id'].toString() == id);
            if (!stillActive) return;
          } catch (_) {
            // If reconciliation itself fails offline, restore optimistically.
          }

          if (generation == _loadGeneration &&
              !_items.any((i) => i.id == id)) {
            final safeIndex = index.clamp(0, _items.length).toInt();
            _items.insert(safeIndex, removed);
            if (removedImg != null) {
              _localImageByItemId[id] = removedImg;
            }
            notifyListeners();
          }
          rethrow;
        }
      }
    });
  }

  Future<void> resolveItemStatus(String id, String status) {
    return _enqueueMutation(() async {
      final generation = _loadGeneration;
      final index = _items.indexWhere((i) => i.id == id);
      if (index == -1) return;

      final removed = _items.removeAt(index);
      final removedImg = _localImageByItemId.remove(id);
      _locallyAddedIds.remove(id);
      notifyListeners();

      if (_hasAuthenticatedUser) {
        try {
          await DbHelper.instance.updateItemStatus(id, status);
        } catch (e) {
          try {
            final serverRows = await DbHelper.instance.fetchPantryItems();
            final stillActive = serverRows.any((r) => r['id'].toString() == id);
            if (!stillActive) return;
          } catch (_) {}

          if (generation == _loadGeneration &&
              !_items.any((i) => i.id == id)) {
            final safeIndex = index.clamp(0, _items.length).toInt();
            _items.insert(safeIndex, removed);
            if (removedImg != null) {
              _localImageByItemId[id] = removedImg;
            }
            notifyListeners();
          }
          rethrow;
        }
      }
    });
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
    if (RegExp(r'\beggs?\b').hasMatch(name) && !name.contains('eggplant')) {
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