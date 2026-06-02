import 'package:flutter/foundation.dart';

import '../models/roommate_profile.dart';
import '../services/api_client.dart';

class RoommateRepository {
  final ApiClient _api;

  RoommateRepository(this._api);

  Future<RoommateProfile?> getMyProfile() async {
    final response = await _api.get('/roommate/profile');
    final data = response.data['data'];
    if (data == null) return null;
    return RoommateProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<RoommateProfile> upsertProfile(RoommateProfile profile) async {
    final response = await _api.post(
      '/roommate/profile',
      data: profile.toJson(),
    );
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      return RoommateProfile.fromJson(data);
    }
    return profile;
  }

  Future<List<RoommateCandidate>> getCandidates() async {
    final response = await _api.get('/roommate/candidates');
    if (kDebugMode) {
      debugPrint('GET /roommate/candidates response: ${response.data}');
    }
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => RoommateCandidate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> swipe({
    required String swipedUserId,
    required String direction,
  }) async {
    await _api.post(
      '/roommate/swipe',
      data: {'swipedUserId': swipedUserId, 'direction': direction},
    );
  }

  Future<List<RoommateMatch>> getMatches() async {
    final response = await _api.get('/roommate/matches');
    if (kDebugMode) {
      debugPrint('GET /roommate/matches status: ${response.statusCode}');
      debugPrint('GET /roommate/matches raw response: ${response.data}');
    }
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => RoommateMatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
