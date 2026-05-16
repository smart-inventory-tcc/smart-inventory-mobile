class Item {
  final int id;
  final String barcode;
  final String name;
  final double price;
  final int stock;
  final int minStock;
  final String? imageUrl;

  Item({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    required this.minStock,
    this.imageUrl,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      minStock: json['min_stock'] as int,
      imageUrl: json['image_url'] as String?,
    );
  }
}
