import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/casandes_logo.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header illustration
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Image.asset(
                    'assets/images/login_illustration.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.home_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title with logo
                    Text(
                      'Welcome to',
                      style: AppTextStyles.heading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const CasandesLogo(width: 180),
                    const SizedBox(height: 12),
                    Text(
                      "Let's get your account set up in\njust a few steps",
                      style: AppTextStyles.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What brings you here today?',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Student card
                    _RoleCard(
                      imagePath: 'assets/images/role-student.jpg',
                      title: "I'm a student",
                      subtitle: 'Browse rooms,\napartments, and find\nroommates',
                      icon: Icons.school_rounded,
                      enabled: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Landlord card (disabled)
                    _RoleCard(
                      imagePath: 'assets/images/role-landlord.jpg',
                      title: "I'm a landlord",
                      subtitle: 'Easily list your\nproperty and find\nreliable tenants',
                      icon: Icons.home_work_rounded,
                      enabled: false,
                      onTap: null,
                    ),
                    const SizedBox(height: 28),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Image on the left
              SizedBox(
                width: 130,
                height: 130,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.primary.withAlpha(30),
                    child: Icon(icon, size: 48, color: AppColors.primary),
                  ),
                ),
              ),

              // Text content on the right
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Icon(
                            icon,
                            size: 24,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                      if (!enabled) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Coming soon',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
