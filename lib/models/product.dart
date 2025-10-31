class Product {
  final String id; // id de la API (string) o "local-<timestamp>" si es offline
  final String name;
  final double price;
  final bool synced; // true si está sincronizado con la nube

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.synced = true,
  });

  // ----- JSON API -----
  Map<String, dynamic> toApiJson() => {
        "name": name,
        "data": {"price": price},
      };

  factory Product.fromApiJson(Map<String, dynamic> json) {
    final data = (json["data"] as Map<String, dynamic>?) ?? {};
    return Product(
      id: json["id"].toString(),
      name: (json["name"] ?? "") as String,
      price: (data["price"] is num) ? (data["price"] as num).toDouble() : 0.0,
      synced: true,
    );
  }

  // ----- SQLite -----
  Map<String, dynamic> toDbJson() => {
        "id": id,
        "name": name,
        "price": price,
        "synced": synced ? 1 : 0,
      };

  factory Product.fromDbJson(Map<String, dynamic> json) => Product(
        id: json["id"] as String,
        name: json["name"] as String,
        price: (json["price"] as num).toDouble(),
        synced: (json["synced"] as int) == 1,
      );

  Product copyWith({String? id, String? name, double? price, bool? synced}) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        synced: synced ?? this.synced,
      );
}
