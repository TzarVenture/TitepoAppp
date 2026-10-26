class CollectionModel {
  final String id;
  final String title;
  final String handle;
  final String? description;
  final String? image;
  final int productsCount;

  CollectionModel({
    required this.id,
    required this.title,
    required this.handle,
    this.description,
    this.image,
    this.productsCount = 0,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    String? imgUrl;
    if (json['image'] != null) {
      if (json['image'] is Map && json['image']['src'] != null) {
        imgUrl = json['image']['src'].toString();
      } else if (json['image'] is String) {
        imgUrl = json['image'];
      }
    }

    return CollectionModel(
      id: json['id']?.toString() ?? json['handle'] ?? '',
      title: json['title']?.toString() ?? 'Category',
      handle: json['handle']?.toString() ?? '',
      description: json['body_html']?.toString() ?? json['description']?.toString(),
      image: imgUrl,
      productsCount: json['products_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'handle': handle,
        'description': description,
        'image': image,
        'productsCount': productsCount,
      };
}
