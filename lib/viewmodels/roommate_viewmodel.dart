import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/roommate_profile.dart';
import '../repositories/roommate_repository.dart';

class RoommateViewModel extends ChangeNotifier {
  final RoommateRepository _repository;

  RoommateViewModel(this._repository);

  // Candidates

  List<RoommateCandidate> _candidates = [];
  int _currentIndex = 0;
  bool _isLoadingCandidates = false;
  String? _candidatesError;

  List<RoommateCandidate> get candidates => _candidates;
  int get currentIndex => _currentIndex;
  bool get isLoadingCandidates => _isLoadingCandidates;
  String? get candidatesError => _candidatesError;
  bool get hasCandidates => _currentIndex < _candidates.length;
  RoommateCandidate? get currentCandidate =>
      hasCandidates ? _candidates[_currentIndex] : null;

  // Matches

  List<RoommateMatch> _matches = [];
  bool _isLoadingMatches = false;
  String? _matchesError;

  List<RoommateMatch> get matches => _matches;
  bool get isLoadingMatches => _isLoadingMatches;
  String? get matchesError => _matchesError;

  // Profile

  RoommateProfile? _myProfile;
  bool _isLoadingProfile = false;
  bool _isSavingProfile = false;
  String? _profileError;
  bool _profileSaved = false;

  RoommateProfile? get myProfile => _myProfile;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isSavingProfile => _isSavingProfile;
  String? get profileError => _profileError;
  bool get profileSaved => _profileSaved;
  bool get hasProfile => _myProfile != null;

  // Swipe state

  bool _isSwiping = false;
  bool? _lastMatchResult;

  bool get isSwiping => _isSwiping;
  bool? get lastMatchResult => _lastMatchResult;

  // Actions

  Future<void> loadCandidates() async {
    _isLoadingCandidates = true;
    _candidatesError = null;
    _currentIndex = 0;
    notifyListeners();
    try {
      _candidates = await _repository.getCandidates();
    } on DioException catch (e) {
      _candidatesError = _parseError(e);
    } catch (e) {
      _candidatesError = e.toString();
    } finally {
      _isLoadingCandidates = false;
      notifyListeners();
    }
  }

  Future<void> swipe(String direction) async {
    final candidate = currentCandidate;
    if (candidate == null || _isSwiping) return;

    _isSwiping = true;
    _lastMatchResult = null;
    notifyListeners();

    try {
      await _repository.swipe(
        swipedUserId: candidate.userId,
        direction: direction,
      );
      if (direction == 'RIGHT') {
        final prevCount = _matches.length;
        await loadMatches();
        _lastMatchResult = _matches.length > prevCount;
      }
    } on DioException catch (e) {
      _candidatesError = _parseError(e);
    } catch (e) {
      _candidatesError = e.toString();
    } finally {
      _currentIndex++;
      _isSwiping = false;
      notifyListeners();
    }
  }

  Future<void> loadMatches() async {
    _isLoadingMatches = true;
    _matchesError = null;
    notifyListeners();
    try {
      _matches = await _repository.getMatches();
    } on DioException catch (e) {
      _matchesError = _parseError(e);
    } catch (e) {
      _matchesError = e.toString();
    } finally {
      _isLoadingMatches = false;
      notifyListeners();
    }
  }

  Future<void> loadMyProfile() async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();
    try {
      _myProfile = await _repository.getMyProfile();
    } on DioException catch (e) {
      _profileError = _parseError(e);
    } catch (e) {
      _profileError = e.toString();
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(RoommateProfile profile) async {
    _isSavingProfile = true;
    _profileError = null;
    _profileSaved = false;
    notifyListeners();
    try {
      _myProfile = await _repository.upsertProfile(profile);
      _profileSaved = true;
    } on DioException catch (e) {
      _profileError = _parseError(e);
    } catch (e) {
      _profileError = e.toString();
    } finally {
      _isSavingProfile = false;
      notifyListeners();
    }
  }

  void clearProfileSaved() {
    _profileSaved = false;
  }

  void clearLastMatch() {
    _lastMatchResult = null;
  }

  // Helpers

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] is String ? data['message'] as String : null) ??
          (data['error'] is String ? data['error'] as String : null) ??
          e.message ??
          'Unknown error';
    }
    return e.message ?? 'Unknown error';
  }
}
