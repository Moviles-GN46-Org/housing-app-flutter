import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import 'home_screen.dart';
import 'personal_information_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: const Text(
          'You will need to sign in again to access your account.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.ashBrown,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Log out',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await context.read<AuthViewModel>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final displayName = user != null
        ? '${user.firstName} ${user.lastName}'.trim()
        : '';
    final unreadNotifications = context
        .watch<HomeViewModel>()
        .unreadNotifications;

    return Scaffold(
      backgroundColor: AppColors.linen,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7E6D5),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleSpacing: 0.0,
        leadingWidth: 56.0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: PopupMenuButton<void>(
            padding: EdgeInsets.zero,
            color: Colors.transparent,
            elevation: 0,
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<void>>[
                PopupMenuItem<void>(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: NotificationsDropdown(
                    notifications: unreadNotifications,
                  ),
                ),
              ];
            },
            icon: Badge.count(
              count: unreadNotifications.length,
              backgroundColor: AppColors.lightBronze,
              isLabelVisible: unreadNotifications.isNotEmpty,
              offset: const Offset(10, -6),
              padding: const EdgeInsets.all(2.0),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                fontFamily: AppTextStyles.fontFamily,
              ),
              child: const Icon(
                LucideIcons.bell,
                color: AppColors.dustyTaupe,
                size: 30.0,
              ),
            ),
          ),
        ),
        title: const Text(
          'Profile and settings',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.deepMocha,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                LucideIcons.log_out,
                color: AppColors.dustyTaupe,
                size: 30.0,
              ),
              onPressed: () => _handleLogout(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.cardBackground,
              child: const Icon(
                LucideIcons.user,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            if (displayName.isNotEmpty)
              Text(
                displayName,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 28),

            _ProfileMenuItem(
              icon: LucideIcons.circle_user_round,
              title: 'Personal Information',
              subtitle: 'Edit your basic account details',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PersonalInformationScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _ProfileMenuItem(
              icon: LucideIcons.handshake,
              title: 'Roomie Matching Profile',
              subtitle: 'Edit your public profile for roomie matching',
            ),
            const SizedBox(height: 12),
            _ProfileMenuItem(
              icon: LucideIcons.house,
              title: 'Housing Preferences',
              subtitle: 'Choose default budget, location, etc.',
            ),
            const SizedBox(height: 12),
            _ProfileMenuItem(
              icon: LucideIcons.house_heart,
              title: 'Saved Listings',
              subtitle: "View apartments you've bookmarked",
            ),
            const SizedBox(height: 12),
            _ProfileMenuItem(
              icon: LucideIcons.cog,
              title: 'Account Settings',
              subtitle: 'Password, login, and account controls',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: AppShadows.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.0),
        onTap:
            onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
