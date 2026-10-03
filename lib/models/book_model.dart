class BookModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final bool isExchangeOnly;
  final String imageUrl;
  final String ownerId;
  final String ownerName;

  BookModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.isExchangeOnly = false,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
  });

  factory BookModel.fromJson(Map<String, dynamic> json, String documentId) {
    return BookModel(
      id: documentId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      isExchangeOnly: json['isExchangeOnly'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'isExchangeOnly': isExchangeOnly,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
    };
  }
}
