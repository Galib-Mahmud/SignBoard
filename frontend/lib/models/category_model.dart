class CategoryFieldSchema {
  final String id;
  final String label;
  final String type; // 'text', 'number', 'select'
  final List<String> options;
  final bool required;
  final String placeholder;

  CategoryFieldSchema({
    required this.id,
    required this.label,
    required this.type,
    this.options = const [],
    this.required = true,
    this.placeholder = '',
  });

  factory CategoryFieldSchema.fromJson(Map<String, dynamic> json) {
    return CategoryFieldSchema(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      required: json['required'] ?? true,
      placeholder: json['placeholder'] ?? '',
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int order;
  final List<CategoryFieldSchema> fieldsSchema;
  final int postsCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
    this.fieldsSchema = const [],
    this.postsCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    var rawFields = json['fields_schema'] as List<dynamic>? ?? [];
    List<CategoryFieldSchema> fields = rawFields
        .map((f) => CategoryFieldSchema.fromJson(f as Map<String, dynamic>))
        .toList();

    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'category',
      order: json['order'] ?? 0,
      fieldsSchema: fields,
      postsCount: json['posts_count'] ?? 0,
    );
  }
}
