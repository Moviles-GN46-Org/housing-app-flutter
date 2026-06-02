import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../models/roommate_profile.dart';
import '../services/offline_queue_service.dart';
import '../utils/app_theme.dart';
import '../viewmodels/roommate_viewmodel.dart';

// Dating app-like swiping interface to match with roommates

// Preference chip helpers

class _Pref {
  final IconData icon;
  final String label;
  const _Pref(this.icon, this.label);
}

_Pref _sleepPref(String v) => switch (v) {
  'NIGHT_OWL' => const _Pref(LucideIcons.moon_star, 'Night Owl'),
  'EARLY_BIRD' => const _Pref(LucideIcons.sun_medium, 'Early Bird'),
  _ => const _Pref(LucideIcons.sun_moon, 'Flexible'),
};

_Pref _cleanPref(String v) => switch (v) {
  'VERY_TIDY' => const _Pref(LucideIcons.bubbles, 'Very Tidy'),
  'RELAXED' => const _Pref(LucideIcons.tool_case, 'Relaxed'),
  _ => const _Pref(LucideIcons.brush_cleaning, 'Moderate'),
};

_Pref _noisePref(String v) => switch (v) {
  'QUIET' => const _Pref(LucideIcons.volume_off, 'Quiet'),
  'LIVELY' => const _Pref(LucideIcons.volume_2, 'Lively'),
  _ => const _Pref(LucideIcons.volume_1, 'Moderate'),
};

List<_Pref> _candidatePrefs(RoommateProfile p) => [
  _sleepPref(p.sleepSchedule),
  _cleanPref(p.cleanlinessLevel),
  _noisePref(p.noisePreference),
  if (p.smokes)
    const _Pref(LucideIcons.cigarette, 'Smoker')
  else
    const _Pref(LucideIcons.cigarette_off, 'Non-Smoker'),
  if (p.hasPets)
    const _Pref(LucideIcons.paw_print, 'Pet Lover')
  else
    const _Pref(LucideIcons.fish_off, 'Pet-Free'),
];

// Screen

class RoomiesScreen extends StatefulWidget {
  const RoomiesScreen({super.key});

  @override
  State<RoomiesScreen> createState() => _RoomiesScreenState();
}

class _RoomiesScreenState extends State<RoomiesScreen> {
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _syncConnectivity();
    _listenConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _syncConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (!mounted) return;
    setState(() => _isOffline = offline);
  }

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = _isOffline;
      final offline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (!mounted || _isOffline == offline) return;
      setState(() => _isOffline = offline);

      if (wasOffline && !offline) {
        unawaited(_reloadRoomiesDataAfterReconnect());
      }
    });
  }

  Future<void> _reloadRoomiesDataAfterReconnect() async {
    final vm = context.read<RoommateViewModel>();
    await vm.loadMyProfile();
    if (!mounted) return;

    if (vm.hasProfile) {
      await vm.loadCandidates();
    }
  }

  Future<void> _init() async {
    final vm = context.read<RoommateViewModel>();
    await vm.loadMyProfile();
    if (vm.hasProfile && mounted) {
      await vm.loadCandidates();
    }
  }

  Future<void> _swipe(String direction) async {
    final vm = context.read<RoommateViewModel>();
    await vm.swipe(direction);
    if (!mounted) return;
    if (vm.lastMatchResult == true) {
      vm.clearLastMatch();
      _showMatchDialog();
    }
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "It's a match! 🎉",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.deepMocha,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'You and this person liked each other!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.ashBrown,
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Awesome',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.lightBronze,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMatchesSheet() {
    final vm = context.read<RoommateViewModel>();
    if (!_isOffline) {
      vm.loadMatches();
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.linen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _MatchesSheet(initialOffline: _isOffline),
      ),
    );
  }

  void _showProfileSheet() {
    final vm = context.read<RoommateViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.linen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _ProfileFormSheet(
          existing: vm.myProfile,
          onSaved: () {
            Navigator.of(context).pop();
            context.read<RoommateViewModel>().loadCandidates();
          },
        ),
      ),
    );
  }

  void _handleProfileButtonPressed() {
    if (_isOffline) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No internet connection. Connect to the internet to modify your public profile.',
            ),
          ),
        );
      return;
    }
    _showProfileSheet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linen,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7E6D5),
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'Find your ideal roomie',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            color: AppColors.deepMocha,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: Opacity(
            opacity: _isOffline ? 0.45 : 1,
            child: const Icon(
              LucideIcons.user_round_cog,
              color: AppColors.dustyTaupe,
              size: 26,
            ),
          ),
          onPressed: _handleProfileButtonPressed,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                LucideIcons.folder_heart,
                color: AppColors.dustyTaupe,
                size: 26,
              ),
              onPressed: _showMatchesSheet,
            ),
          ),
        ],
      ),
      body: Consumer<RoommateViewModel>(
        builder: (context, vm, _) {
          if (_isOffline) {
            return const _OfflineRoomiesPrompt();
          }

          if (vm.isLoadingProfile || vm.isLoadingCandidates) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.lightBronze),
            );
          }

          if (!vm.hasProfile) {
            return _NoProfilePrompt(onSetUp: _showProfileSheet);
          }

          if (vm.candidatesError != null) {
            return _ErrorPrompt(
              message: vm.candidatesError!,
              onRetry: () => vm.loadCandidates(),
            );
          }

          if (!vm.hasCandidates) {
            return _EmptyPrompt(onRefresh: () => vm.loadCandidates());
          }

          final candidate = vm.currentCandidate!;
          return SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: _RoomieCard(candidate: candidate),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CircleActionButton(
                      icon: Icons.close_rounded,
                      backgroundColor: const Color(0xFF5C4033),
                      iconColor: AppColors.white,
                      onTap: vm.isSwiping ? null : () => _swipe('LEFT'),
                    ),
                    const SizedBox(width: 24),
                    _CircleActionButton(
                      icon: Icons.favorite_rounded,
                      backgroundColor: AppColors.lightBronze,
                      iconColor: AppColors.white,
                      onTap: vm.isSwiping ? null : () => _swipe('RIGHT'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Empty/error states

class _NoProfilePrompt extends StatelessWidget {
  const _NoProfilePrompt({required this.onSetUp});
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.user_round_plus,
              size: 64,
              color: AppColors.dustyTaupe,
            ),
            const SizedBox(height: 20),
            const Text(
              'Set up your roomie profile',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.deepMocha,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Tell others about your lifestyle so we can find you the perfect match.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: AppColors.dustyTaupe,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onSetUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightBronze,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Set Up Profile',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineRoomiesPrompt extends StatelessWidget {
  const _OfflineRoomiesPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.wifi_off, size: 64, color: AppColors.dustyTaupe),
            SizedBox(height: 20),
            Text(
              'No internet connection',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.deepMocha,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Connect to the internet to see roomie cards and continue swiping.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: AppColors.dustyTaupe,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.users_round,
              size: 64,
              color: AppColors.dustyTaupe,
            ),
            const SizedBox(height: 20),
            const Text(
              'No more candidates',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.deepMocha,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "You've gone through everyone for now. Check back later!",
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: AppColors.dustyTaupe,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRefresh,
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.lightBronze,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPrompt extends StatelessWidget {
  const _ErrorPrompt({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.wifi_off,
              size: 48,
              color: AppColors.dustyTaupe,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: AppColors.dustyTaupe,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Try again',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.lightBronze,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card

class _RoomieCard extends StatelessWidget {
  const _RoomieCard({required this.candidate});
  final RoommateCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final prefs = _candidatePrefs(candidate.profile);
    final budget =
        '${_formatCurrency(candidate.profile.budgetMin)}–${_formatCurrency(candidate.profile.budgetMax)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Photo
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  candidate.profilePictureUrl != null
                      ? Image.network(
                          candidate.profilePictureUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const ColoredBox(color: Color(0xFFEADDD5));
                          },
                          errorBuilder: (_, _, _) => const _AvatarPlaceholder(),
                        )
                      : const _AvatarPlaceholder(),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 130,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xAA000000)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Text(
                      candidate.age > 0
                          ? '${candidate.fullName}, ${candidate.age}'
                          : candidate.fullName,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBronze,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${candidate.compatibilityScore}% MATCH',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (candidate.profile.job.isNotEmpty)
                              _InfoRow(
                                icon: LucideIcons.briefcase,
                                text: candidate.profile.job,
                              ),
                            if (candidate.profile.university.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _InfoRow(
                                icon: LucideIcons.graduation_cap,
                                text: candidate.profile.university,
                              ),
                            ],
                            if (candidate.profile.preferredArea.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _InfoRow(
                                icon: LucideIcons.map_pin,
                                text: candidate.profile.preferredArea,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            budget,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightBronze,
                            ),
                          ),
                          const Text(
                            'budget',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: AppColors.dustyTaupe,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Habits & Preferences',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepMocha,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: prefs
                        .map((p) => _PrefChip(icon: p.icon, label: p.label))
                        .toList(),
                  ),

                  if (candidate.profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepMocha,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      candidate.profile.bio,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: AppColors.dustyTaupe,
                        height: 1.55,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFD9CEC8),
      child: Center(
        child: Icon(LucideIcons.user, size: 64, color: AppColors.dustyTaupe),
      ),
    );
  }
}

String _formatCurrency(int amount) {
  if (amount >= 1000000) {
    return '\$${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return '\$${(amount / 1000).toStringAsFixed(0)}K';
  }
  return '\$$amount';
}

// Matches sheet

class _MatchesSheet extends StatefulWidget {
  const _MatchesSheet({required this.initialOffline});

  final bool initialOffline;

  @override
  State<_MatchesSheet> createState() => _MatchesSheetState();
}

class _MatchesSheetState extends State<_MatchesSheet> {
  late bool _isOffline;
  bool _isRefreshingAfterReconnect = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.initialOffline;
    _syncConnectivity();
    _listenConnectivity();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _syncConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (!mounted) return;
    setState(() => _isOffline = offline);
  }

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = _isOffline;
      final offline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (!mounted || _isOffline == offline) return;
      setState(() => _isOffline = offline);

      if (wasOffline && !offline) {
        setState(() => _isRefreshingAfterReconnect = true);
        unawaited(
          context.read<RoommateViewModel>().loadMatches().whenComplete(() {
            if (!mounted) return;
            setState(() => _isRefreshingAfterReconnect = false);
          }),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoommateViewModel>(
      builder: (_, vm, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Your Matches',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepMocha,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      color: AppColors.dustyTaupe,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isOffline)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No internet connection. Connect to the internet to see the list of your past matches.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.dustyTaupe,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_isRefreshingAfterReconnect || vm.isLoadingMatches)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: AppColors.lightBronze,
                    ),
                  ),
                )
              else if (vm.matchesError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vm.matchesError!,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.dustyTaupe,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: vm.loadMatches,
                          child: const Text(
                            'Try again',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.lightBronze,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (vm.matches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No matches yet',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.dustyTaupe,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: vm.matches.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Color(0xFFEADDD5), height: 1),
                    itemBuilder: (_, i) {
                      final m = vm.matches[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFEADDD5),
                          backgroundImage: m.profilePictureUrl != null
                              ? NetworkImage(m.profilePictureUrl!)
                              : null,
                          child: m.profilePictureUrl == null
                              ? const Icon(
                                  LucideIcons.user,
                                  color: AppColors.dustyTaupe,
                                  size: 20,
                                )
                              : null,
                        ),
                        title: Text(
                          m.fullName,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w400,
                            color: AppColors.deepMocha,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Profile form sheet

class _ProfileFormSheet extends StatefulWidget {
  const _ProfileFormSheet({this.existing, required this.onSaved});
  final RoommateProfile? existing;
  final VoidCallback onSaved;

  @override
  State<_ProfileFormSheet> createState() => _ProfileFormSheetState();
}

class _ProfileFormSheetState extends State<_ProfileFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _sleepSchedule;
  late String _cleanlinessLevel;
  late String _noisePreference;
  late bool _smokes;
  late bool _hasPets;
  late bool _isActive;

  final _bioCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _sleepSchedule = e?.sleepSchedule ?? 'FLEXIBLE';
    _cleanlinessLevel = e?.cleanlinessLevel ?? 'MODERATE';
    _noisePreference = e?.noisePreference ?? 'MODERATE';
    _smokes = e?.smokes ?? false;
    _hasPets = e?.hasPets ?? false;
    _isActive = e?.isActive ?? true;
    _bioCtrl.text = e?.bio ?? '';
    _jobCtrl.text = e?.job ?? '';
    _uniCtrl.text = e?.university ?? '';
    _areaCtrl.text = e?.preferredArea ?? '';
    _budgetMinCtrl.text = e != null && e.budgetMin > 0
        ? e.budgetMin.toString()
        : '';
    _budgetMaxCtrl.text = e != null && e.budgetMax > 0
        ? e.budgetMax.toString()
        : '';
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _uniCtrl.dispose();
    _areaCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = RoommateProfile(
      sleepSchedule: _sleepSchedule,
      cleanlinessLevel: _cleanlinessLevel,
      noisePreference: _noisePreference,
      smokes: _smokes,
      hasPets: _hasPets,
      budgetMin: int.tryParse(_budgetMinCtrl.text.trim()) ?? 0,
      budgetMax: int.tryParse(_budgetMaxCtrl.text.trim()) ?? 0,
      preferredArea: _areaCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      birthDate: widget.existing?.birthDate ?? '',
      job: _jobCtrl.text.trim(),
      university: _uniCtrl.text.trim(),
      isActive: _isActive,
    );

    final connectivity = await Connectivity().checkConnectivity();
    final isOffline =
        connectivity.isEmpty ||
        connectivity.every((r) => r == ConnectivityResult.none);

    if (isOffline) {
      await _queueProfileUpdate(profile);
      return;
    }

    await context.read<RoommateViewModel>().saveProfile(profile);
    if (!mounted) return;
    final vm = context.read<RoommateViewModel>();
    if (vm.profileError == null) {
      widget.onSaved();
    } else if (_looksLikeOfflineError(vm.profileError!)) {
      await _queueProfileUpdate(profile);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.profileError!)));
    }
  }

  bool _looksLikeOfflineError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('internet') ||
        normalized.contains('connection') ||
        normalized.contains('socket');
  }

  Future<void> _queueProfileUpdate(RoommateProfile profile) async {
    final queue = context.read<OfflineQueueService>();
    await queue.enqueueRoommateProfileUpdate(profile: profile);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'No internet connection. Your public profile will be updated when the connection is restored.',
          ),
        ),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9CEC8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.existing == null
                      ? 'Set Up Your Profile'
                      : 'Edit Your Profile',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepMocha,
                  ),
                ),
                const SizedBox(height: 24),

                _FormField(
                  label: 'Job / Occupation',
                  controller: _jobCtrl,
                  hint: 'e.g. Software Engineering Student',
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                _FormField(
                  label: 'University',
                  controller: _uniCtrl,
                  hint: 'e.g. Universidad Nacional',
                  maxLength: 120,
                ),
                const SizedBox(height: 16),

                _FormField(
                  label: 'Preferred Area',
                  controller: _areaCtrl,
                  hint: 'e.g. Chapinero, Usaquén',
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        label: 'Budget Min (COP)',
                        controller: _budgetMinCtrl,
                        hint: '500000',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Enter a number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormField(
                        label: 'Budget Max (COP)',
                        controller: _budgetMaxCtrl,
                        hint: '900000',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Enter a number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _DropdownField<String>(
                  label: 'Sleep Schedule',
                  value: _sleepSchedule,
                  items: const [
                    DropdownMenuItem(
                      value: 'EARLY_BIRD',
                      child: Text('Early Bird'),
                    ),
                    DropdownMenuItem(
                      value: 'NIGHT_OWL',
                      child: Text('Night Owl'),
                    ),
                    DropdownMenuItem(
                      value: 'FLEXIBLE',
                      child: Text('Flexible'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sleepSchedule = v!),
                ),
                const SizedBox(height: 16),

                _DropdownField<String>(
                  label: 'Cleanliness Level',
                  value: _cleanlinessLevel,
                  items: const [
                    DropdownMenuItem(
                      value: 'VERY_TIDY',
                      child: Text('Very Tidy'),
                    ),
                    DropdownMenuItem(
                      value: 'MODERATE',
                      child: Text('Moderate'),
                    ),
                    DropdownMenuItem(value: 'RELAXED', child: Text('Relaxed')),
                  ],
                  onChanged: (v) => setState(() => _cleanlinessLevel = v!),
                ),
                const SizedBox(height: 16),

                _DropdownField<String>(
                  label: 'Noise Preference',
                  value: _noisePreference,
                  items: const [
                    DropdownMenuItem(value: 'QUIET', child: Text('Quiet')),
                    DropdownMenuItem(
                      value: 'MODERATE',
                      child: Text('Moderate'),
                    ),
                    DropdownMenuItem(value: 'LIVELY', child: Text('Lively')),
                  ],
                  onChanged: (v) => setState(() => _noisePreference = v!),
                ),
                const SizedBox(height: 16),

                _ToggleTile(
                  label: 'I smoke',
                  value: _smokes,
                  onChanged: (v) => setState(() => _smokes = v),
                ),
                const SizedBox(height: 8),
                _ToggleTile(
                  label: 'I have pets',
                  value: _hasPets,
                  onChanged: (v) => setState(() => _hasPets = v),
                ),
                const SizedBox(height: 8),
                _ToggleTile(
                  label: 'Show my profile to others',
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 16),

                _FormField(
                  label: 'About You',
                  controller: _bioCtrl,
                  hint: 'Tell potential roommates about yourself...',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                Consumer<RoommateViewModel>(
                  builder: (_, vm, _) => ElevatedButton(
                    onPressed: vm.isSavingProfile ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBronze,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: vm.isSavingProfile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Sub widgets

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ashBrown,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.deepMocha,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: AppColors.dustyTaupe,
            ),
            filled: true,
            fillColor: AppColors.white,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8D9CB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8D9CB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.lightBronze,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ashBrown,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8D9CB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: AppColors.deepMocha,
              ),
              dropdownColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D9CB)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.deepMocha,
          ),
        ),
        value: value,
        activeColor: AppColors.lightBronze,
        onChanged: onChanged,
        dense: true,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.dustyTaupe),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: AppColors.ashBrown,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PrefChip extends StatelessWidget {
  const _PrefChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E0CA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.dustyTaupe),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.dustyTaupe,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: AppShadows.card,
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 28)),
        ),
      ),
    );
  }
}
