import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../utils/app_theme.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  bool _lookingForRoommate = false;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preference saved: ${_lookingForRoommate ? 'Yes' : 'No'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              LucideIcons.chevron_left,
              color: AppColors.dustyTaupe,
              size: 30.0,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Personal Information',
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
                LucideIcons.check,
                color: AppColors.dustyTaupe,
                size: 30.0,
              ),
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: AppShadows.card,
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: const Text(
                  'Looking for a roommate',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                subtitle: const Text(
                  'Show your profile to others seeking roommates',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                value: _lookingForRoommate,
                activeColor: AppColors.primary,
                onChanged: (value) =>
                    setState(() => _lookingForRoommate = value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
