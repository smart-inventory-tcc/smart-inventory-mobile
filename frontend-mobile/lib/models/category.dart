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
}
