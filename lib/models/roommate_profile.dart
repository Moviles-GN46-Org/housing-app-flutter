class RoommateProfile {
  final String sleepSchedule;
  final String cleanlinessLevel;
  final String noisePreference;
  final bool smokes;
  final bool hasPets;
  final int budgetMin;
  final int budgetMax;
  final String preferredArea;
  final String bio;
  final String birthDate;
  final String job;
  final String university;
  final bool isActive;

  const RoommateProfile({
    required this.sleepSchedule,
    required this.cleanlinessLevel,
    required this.noisePreference,
    required this.smokes,
    required this.hasPets,
    required this.budgetMin,
    required this.budgetMax,
    required this.preferredArea,
    required this.bio,
    required this.birthDate,
    required this.job,
    required this.university,
    required this.isActive,
  });

  factory RoommateProfile.fromJson(Map<String, dynamic> json) {
    return RoommateProfile(
      sleepSchedule: json['sleepSchedule'] as String? ?? 'FLEXIBLE',
      cleanlinessLevel: json['cleanlinessLevel'] as String? ?? 'MODERATE',
      noisePreference: json['noisePreference'] as String? ?? 'MODERATE',
      smokes: json['smokes'] as bool? ?? false,
      hasPets: json['hasPets'] as bool? ?? false,
      budgetMin: (json['budgetMin'] as num?)?.toInt() ?? 0,
      budgetMax: (json['budgetMax'] as num?)?.toInt() ?? 0,
      preferredArea: json['preferredArea'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      job: json['job'] as String? ?? '',
      university: json['university'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sleepSchedule': sleepSchedule,
      'cleanlinessLevel': cleanlinessLevel,
      'noisePreference': noisePreference,
      'smokes': smokes,
      'hasPets': hasPets,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'preferredArea': preferredArea,
      'bio': bio,
      'birthDate': birthDate,
      'job': job,
      'university': university,
      'isActive': isActive,
    };
  }
}

class RoommateCandidate {
  final String userId;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final int compatibilityScore;
  final List<String> matchReasons;
  final RoommateProfile profile;
  final int age;

  const RoommateCandidate({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    required this.compatibilityScore,
    required this.matchReasons,
    required this.profile,
    required this.age,
  });

  String get fullName => '$firstName $lastName';

  factory RoommateCandidate.fromJson(Map<String, dynamic> json) {
    // The backend returns profile fields flat on the candidate object.
    // Fall back to the top-level json when there is no nested 'profile' key.
    final profileJson = json['profile'] as Map<String, dynamic>? ?? json;

    // Prefer the age sent directly by the backend; fall back to computing
    // it from birthDate when available.
    int resolvedAge = (json['age'] as num?)?.toInt() ?? 0;
    if (resolvedAge == 0) {
      final birth = DateTime.tryParse(
        profileJson['birthDate'] as String? ?? '',
      );
      if (birth != null) {
        final now = DateTime.now();
        resolvedAge = now.year - birth.year;
        if (now.month < birth.month ||
            (now.month == birth.month && now.day < birth.day)) {
          resolvedAge--;
        }
      }
    }

    return RoommateCandidate(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String?,
      compatibilityScore: (json['compatibilityScore'] as num?)?.toInt() ?? 0,
      matchReasons:
          (json['matchReasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      profile: RoommateProfile.fromJson(profileJson),
      age: resolvedAge,
    );
  }
}

class RoommateMatch {
  final String matchId;
  final String userId;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final String? chatId;
  final RoommateProfile profile;

  const RoommateMatch({
    required this.matchId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    this.chatId,
    required this.profile,
  });

  String get fullName => '$firstName $lastName';

  factory RoommateMatch.fromJson(Map<String, dynamic> json) {
    final matchedUser = json['matchedUser'] as Map<String, dynamic>?;

    final profileJson = json['profile'] as Map<String, dynamic>? ?? json;
    return RoommateMatch(
      matchId: json['matchId'] as String? ?? json['id'] as String? ?? '',
      userId:
          json['userId'] as String? ??
          json['matchedUserId'] as String? ??
          matchedUser?['id'] as String? ??
          '',
      firstName:
          json['firstName'] as String? ??
          matchedUser?['firstName'] as String? ??
          '',
      lastName:
          json['lastName'] as String? ??
          matchedUser?['lastName'] as String? ??
          '',
      profilePictureUrl:
          json['profilePictureUrl'] as String? ??
          matchedUser?['profilePictureUrl'] as String?,
      chatId: json['chatId'] as String?,
      profile: RoommateProfile.fromJson(profileJson),
    );
  }
}
