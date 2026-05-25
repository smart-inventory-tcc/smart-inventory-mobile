class Category {
  final int id;
  final String categoryName;
  final String? description;

  const Category({
    required this.id,
    required this.categoryName,
    this.description,
  });

  /// Parsing dari GET /categories response element:
  /// { "id": 1, "categoryName": "string", "description": "string", "createdAt": "..." }
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      categoryName: json['categoryName']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  factory Category.fromFirestore(Map<String, dynamic> data, String docId) {
    return Category(
      id: data['id'] as int? ?? 0,
      categoryName: data['categoryName']?.toString() ?? '',
      description: data['description']?.toString(),
    );
  }
}
