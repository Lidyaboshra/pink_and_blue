class Drink {
  final String id;
  final String name;
  final String category;
  final String? description;
  final String? imageUrl;
  final double? priceSmall;
  final double? priceMedium;
  final double? priceLarge;
  final bool isNew;

  Drink({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.imageUrl,
    this.priceSmall,
    this.priceMedium,
    this.priceLarge,
    this.isNew = false,
  });

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'],
      name: json['name'],
      category: json['categories']?['name'] ?? 'Uncategorized',
      description: json['description'],
      imageUrl: json['image_url'],
      priceSmall: json['price_small']?.toDouble(),
      priceMedium: json['price_medium']?.toDouble(),
      priceLarge: json['price_large']?.toDouble(),
      isNew: json['is_new'] ?? false,
    );
  }
}