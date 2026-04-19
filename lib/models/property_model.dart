class Property {
  final String id;
  final String title;
  final String address;
  final String neighborhood;
  final double monthlyRent;
  final double latitude;
  final double longitude;
  final int bedrooms;
  final int bathrooms;
  final String imageUrl;
  final double? averageRating;

  Property({
    required this.id,
    required this.title,
    required this.address,
    required this.neighborhood,
    required this.monthlyRent,
    required this.latitude,
    required this.longitude,
    required this.bedrooms,
    required this.bathrooms,
    required this.imageUrl,
    this.averageRating,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Extraemos la primera imagen si existe, de lo contrario usamos un placeholder
    String firstImage = 'https://via.placeholder.com/400x300.png?text=No+Image';
    if (json['imageUrls'] != null && (json['imageUrls'] as List).isNotEmpty) {
      firstImage = json['imageUrls'][0];
    }

    return Property(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      address: json['address'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      monthlyRent:
          double.tryParse(json['monthlyRent']?.toString() ?? '0') ?? 0.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      imageUrl: firstImage,
      averageRating: json['averageRating'] != null
          ? double.tryParse(json['averageRating'].toString())
          : null,
    );
  }
}
