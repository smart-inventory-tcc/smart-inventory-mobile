class Item {
  final int id;
  final String barcode;
  final String name;
  final double price;
  final int stock;
  final int minStock;
  final int? categoryId;
  final int? supplierId;
  final String? imageUrl;
  final bool isActive;

  const Item({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    required this.minStock,
    this.categoryId,
    this.supplierId,
    this.imageUrl,
    this.isActive = true,
  });

  /// Inventory Service kadang mengembalikan angka sebagai String.
  /// Helper ini menangani keduanya (num & String) dengan aman.
  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Mendukung tiga bentuk response dari Inventory Service:
  /// 1. GET /items       : list element langsung { id, barcode, ... }
  /// 2. GET /items/...   : { data: { id, barcode, ... } }
  /// 3. Direct object    : { id, barcode, ... }
  factory Item.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return Item(
      id: _toInt(map['id']),
      barcode: map['barcode']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: _toDouble(map['price']),
      stock: _toInt(map['stock']),
      minStock: _toInt(map['minStock'] ?? map['min_stock']),
      categoryId: map['categoryId'] != null ? _toInt(map['categoryId']) : null,
      supplierId: map['supplierId'] != null ? _toInt(map['supplierId']) : null,
      imageUrl: (map['imageUrl'] ?? map['image_url'])?.toString(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
