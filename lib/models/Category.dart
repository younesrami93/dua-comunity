class Category {
  final int id;
  final String name; // Contains the Emoji like "🌙 Ramadan"
  final String slug;
  final String? iconUrl;

  Category({required this.id, required this.name, required this.slug, this.iconUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      iconUrl: json['icon_url'],
    );
  }
}