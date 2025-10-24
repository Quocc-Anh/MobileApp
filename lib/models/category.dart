class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'name': name};

  factory Category.fromJson(String id, Map<String, dynamic> json) {
    return Category(id: id, name: json['name'] as String);
  }
}