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
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Sin título',
      address: json['address'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      // Forzamos la conversión a double de forma segura
      monthlyRent: double.tryParse(json['monthlyRent']?.toString() ?? '0') ?? 0.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
    );
  }
}