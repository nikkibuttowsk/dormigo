enum FoodCategory { vegetables, protein, grains, dairy, other }

enum StorageLocation { shelf, fridge, freezer }

enum ExpiryStatus { expired, useFirst, expiringSoon, fresh, noDate }

class PantryItem {
  final String id;
  final String name;
  final FoodCategory category;
  final double quantity;
  final String unit; // 'pcs', 'g', 'kg', 'L'
  final DateTime? expiryDate;
  final StorageLocation storageLocation;
  final DateTime addedAt;
  final String? imagePath;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    this.storageLocation = StorageLocation.shelf,
    DateTime? addedAt,
    this.imagePath,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Calculates remaining days until expiration (negative if expired)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return exp.difference(today).inDays;
  }

  /// Determines badge color & priority matching your UI mockups
  ExpiryStatus get expiryStatus {
    final days = daysUntilExpiry;
    if (days == null) return ExpiryStatus.noDate;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 2) return ExpiryStatus.useFirst;
    if (days <= 5) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.fresh;
  }

  String get categoryLabel {
    switch (category) {
      case FoodCategory.vegetables:
        return 'Vegetables';
      case FoodCategory.protein:
        return 'Protein';
      case FoodCategory.grains:
        return 'Grains';
      case FoodCategory.dairy:
        return 'Dairy';
      case FoodCategory.other:
        return 'Other';
    }
  }

  String get storageLabel {
    switch (storageLocation) {
      case StorageLocation.shelf:
        return 'Shelf';
      case StorageLocation.fridge:
        return 'Fridge';
      case StorageLocation.freezer:
        return 'Freezer';
    }
  }

  PantryItem copyWith({
    String? name,
    FoodCategory? category,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    bool clearExpiry = false,
    StorageLocation? storageLocation,
    String? imagePath,
  }) {
    return PantryItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      storageLocation: storageLocation ?? this.storageLocation,
      addedAt: addedAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate?.toIso8601String(),
      'storage_location': storageLocation.name,
      'added_at': addedAt.toIso8601String(),
      if (imagePath != null) 'image_url': imagePath,
    };
  }

  factory PantryItem.fromMap(Map<String, dynamic> map) {
    return PantryItem(
      id: map['id'].toString(),
      name: map['name'],
      category: FoodCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => FoodCategory.other,
      ),
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] ?? 'pcs',
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : null,
      storageLocation: StorageLocation.values.firstWhere(
        (e) => e.name == map['storage_location'],
        orElse: () => StorageLocation.shelf,
      ),
      addedAt: map['added_at'] != null
          ? DateTime.parse(map['added_at'])
          : DateTime.now(),
      imagePath: map['image_url'] as String?,
    );
  }
}