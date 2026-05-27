class Order {
  final String id;
  final List<dynamic> items;
  final double total;
  final String? location;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.total,
    this.location,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: json['items'] ?? [],
      total: (json['total'] ?? 0).toDouble(),
      location: json['location'],
      status: json['status'] ?? 'completed',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}