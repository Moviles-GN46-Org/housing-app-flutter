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
  final String? description;
  final bool includesUtilities;
  final bool hasWifi;
  final bool hasParking;
  final bool hasLaundry;
  final bool furnished;

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
    this.description,
    this.includesUtilities = false,
    this.hasWifi = false,
    this.hasParking = false,
    this.hasLaundry = false,
    this.furnished = false,
  });

  static const String _noImagePlaceholder =
      'https://static.vecteezy.com/system/resources/previews/056/506/951/non_2x/this-is-a-simple-illustration-of-a-house-vector.jpg';

  bool get hasImage => imageUrl != _noImagePlaceholder;
  Map<String, dynamic> toJson() {
    // Mirrors the backend shape so cached blobs round-trip cleanly through
    // Property.fromJson. imageUrls is a list because fromJson reads the first.
    return {
      'id': id,
      'title': title,
      'address': address,
      'neighborhood': neighborhood,
      'monthlyRent': monthlyRent,
      'latitude': latitude,
      'longitude': longitude,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'imageUrls': [imageUrl],
      'averageRating': averageRating,
      'description': description,
      'includesUtilities': includesUtilities,
      'hasWifi': hasWifi,
      'hasParking': hasParking,
      'hasLaundry': hasLaundry,
      'furnished': furnished,
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    // Extraemos la primera imagen si existe, de lo contrario usamos un placeholder
    String firstImage = Property._noImagePlaceholder;
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
      description: json['description']?.toString(),
      includesUtilities: json['includesUtilities'] as bool? ?? false,
      hasWifi: json['hasWifi'] as bool? ?? false,
      hasParking: json['hasParking'] as bool? ?? false,
      hasLaundry: json['hasLaundry'] as bool? ?? false,
      furnished: json['furnished'] as bool? ?? false,
    );
  }
}
