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
  final List<String> imageUrls;
  final double? averageRating;
  final int? reviewCount;
  final String? description;
  final bool includesUtilities;
  final bool hasWifi;
  final bool hasParking;
  final bool hasLaundry;
  final bool furnished;
  final double? deposit;
  final int? contractMonths;
  final String? moveInDate;
  final bool isVerified;

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
    required this.imageUrls,
    this.averageRating,
    this.reviewCount,
    this.description,
    this.includesUtilities = false,
    this.hasWifi = false,
    this.hasParking = false,
    this.hasLaundry = false,
    this.furnished = false,
    this.deposit,
    this.contractMonths,
    this.moveInDate,
    this.isVerified = false,
  });

  static const String _noImagePlaceholder =
      'https://static.vecteezy.com/system/resources/previews/056/506/951/non_2x/this-is-a-simple-illustration-of-a-house-vector.jpg';

  String get imageUrl =>
      imageUrls.isNotEmpty ? imageUrls[0] : _noImagePlaceholder;

  bool get hasImage =>
      imageUrls.isNotEmpty && imageUrls[0] != _noImagePlaceholder;

  Map<String, dynamic> toJson() {
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
      'imageUrls': imageUrls,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'description': description,
      'includesUtilities': includesUtilities,
      'hasWifi': hasWifi,
      'hasParking': hasParking,
      'hasLaundry': hasLaundry,
      'furnished': furnished,
      'deposit': deposit,
      'contractMonths': contractMonths,
      'moveInDate': moveInDate,
      'isVerified': isVerified,
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['imageUrls'] as List? ?? [];
    final List<String> imageUrls = rawUrls
        .map((e) => e.toString())
        .where((url) => url.isNotEmpty)
        .toList();
    if (imageUrls.isEmpty) imageUrls.add(Property._noImagePlaceholder);

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
      imageUrls: imageUrls,
      averageRating: json['averageRating'] != null
          ? double.tryParse(json['averageRating'].toString())
          : null,
      reviewCount: json['reviewCount'] as int?,
      description: json['description']?.toString(),
      includesUtilities: json['includesUtilities'] as bool? ?? false,
      hasWifi: json['hasWifi'] as bool? ?? false,
      hasParking: json['hasParking'] as bool? ?? false,
      hasLaundry: json['hasLaundry'] as bool? ?? false,
      furnished: json['furnished'] as bool? ?? false,
      deposit: json['deposit'] != null
          ? double.tryParse(json['deposit'].toString())
          : null,
      contractMonths: json['contractMonths'] as int?,
      moveInDate: json['moveInDate']?.toString(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}
