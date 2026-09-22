import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/primary_button.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/secondary_button.dart';
import '../../common_widgets/voice_instruction_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    final authCtrl = context.read<AuthController>();
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.translate('login.error_empty_phone'),
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
      return;
    }
    final success = await authCtrl.loginWithPhone(phone);
    if (mounted) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/elderly_home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authCtrl.errorMessage ?? context.l10n.translate('login.error_failed'),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        );
      }
    }
  }

  void _handleQuickDemo() async {
    final authCtrl = context.read<AuthController>();
    final success = await authCtrl.loginWithPhone('9876543210');
    if (mounted) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/elderly_home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authCtrl = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('login.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
          tooltip: context.l10n.translate('common.button.back'),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DisclaimerBanner(),
                const SizedBox(height: 16),
                LargeText(
                  context.l10n.translate('login.title'),
                  type: LargeTextType.heading,
                  isHeader: true,
                ),
                const SizedBox(height: 8),
                LargeText(
                  context.l10n.translate('login.subtitle'),
                  type: LargeTextType.body,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VoiceInstructionButton(
                    textToSpeak: context.l10n.translate('login.audio_help'),
                  ),
                ),
                const SizedBox(height: 24),
                AccessibleCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LargeText(
                        context.l10n.translate('login.input_label'),
                        type: LargeTextType.title,
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: context.l10n.translate('login.input_label'),
                        textField: true,
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: context.l10n.translate('login.input_hint'),
                            hintStyle: TextStyle(
                              fontSize: 20,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            prefixIcon: const Icon(Icons.phone_rounded, size: 28),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                                width: 2.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF94A3B8),
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: authCtrl.isLoading
                      ? context.l10n.translate('auth.signing_in')
                      : context.l10n.translate('auth.login'),
                  icon: Icons.login_rounded,
                  onPressed: authCtrl.isLoading ? null : _handleSignIn,
                ),
                const SizedBox(height: 16),
                SecondaryButton(
                  label: context.l10n.translate('login.quick_elder_demo'),
                  icon: Icons.play_circle_outline_rounded,
                  onPressed: authCtrl.isLoading ? null : _handleQuickDemo,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
