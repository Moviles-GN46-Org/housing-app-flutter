class ReviewAuthor {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;

  const ReviewAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ReviewAuthor.fromJson(Map<String, dynamic> json) {
    return ReviewAuthor(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profilePictureUrl: json['profilePictureUrl']?.toString(),
    );
  }
}

class Review {
  final String id;
  final String propertyId;
  final int rating;
  final String comment;
  final ReviewAuthor author;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.propertyId,
    required this.rating,
    required this.comment,
    required this.author,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      propertyId: json['propertyId']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      author: ReviewAuthor.fromJson(
        json['author'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
