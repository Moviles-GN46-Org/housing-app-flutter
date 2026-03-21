import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/casandes_logo.dart';
import 'success_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _resendEnabled = true;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final code = _code;
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the full 6-digit code'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    await context.read<AuthViewModel>().verifyEmail(code: code);

    if (mounted) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVM.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } else if (authVM.currentUser?.isVerified == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_resendEnabled) return;

    setState(() => _resendEnabled = false);

    await context.read<AuthViewModel>().resendCode();

    if (mounted) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVM.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        setState(() => _resendEnabled = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new code has been sent to your email'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Cooldown 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) setState(() => _resendEnabled = true);
        });
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-submit when all 6 digits are entered
    if (_code.length == 6) {
      _handleVerify();
    }
  }

  void _onKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CasandesLogo(width: 160),
                const SizedBox(height: 40),

                Text(
                  'Verify your email',
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit code to',
                  style: AppTextStyles.bodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // 6-digit code input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 48,
                      height: 56,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                      ),
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) => _onKeyPress(index, event),
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onDigitChanged(index, value),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Verify button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authVM.isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withAlpha(150),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: authVM.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Resend code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive it? ",
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resendEnabled && !authVM.isLoading
                          ? _handleResend
                          : null,
                      child: Text(
                        'Resend code',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _resendEnabled
                              ? AppColors.primary
                              : AppColors.textMuted.withAlpha(120),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Back to login
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ),
                    child: Text(
                      'Back to login',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
