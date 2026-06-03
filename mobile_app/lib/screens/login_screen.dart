import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/screens/register_screen.dart';
import 'package:real_banking/screens/forgot_password_screen.dart';
import 'package:real_banking/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      if (mounted) setState(() => _biometricAvailable = available);
    } catch (_) {}
  }

  Future<void> _tryBiometricLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('biometric_enabled') ?? false;
      if (!enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Enable biometric login in Security settings first'),
          ),
        );
        return;
      }

      // If a valid PocketBase session already exists we just unlock
      if (PbService.instance.isLoggedIn) {
        // BiometricGate in main.dart handles actual biometric prompting;
        // here we just verify identity and return to the normal flow.
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Sign in to STCU Digital Banking',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        if (authenticated && mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }

      // No active session — biometric can verify identity but a password is
      // still needed to obtain a fresh PocketBase token.
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to STCU Digital Banking',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (!authenticated || !mounted) return;

      final savedEmail = prefs.getString('saved_email') ?? '';
      if (savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Identity verified  Your session expired — enter your password once to continue.',
          ),
          backgroundColor: Color(0xFFE65100),
          duration: Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Biometric error: $e')));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await PbService.instance.pb.collection('users').authWithPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );

      // Save email for biometric recovery
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', _emailController.text.trim());

      // Navigate back to AppRouter which will now see isLoggedIn == true
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } on ClientException catch (e) {
      final msg = e.response['message'] as String? ?? '';
      setState(() => _errorMessage = _getErrorMessage(msg));
    } catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('invalid credentials') ||
        lower.contains('failed to authenticate')) {
      return 'Invalid email or password.';
    }
    if (lower.contains('not found')) return 'No account found with this email.';
    if (lower.contains('network') || lower.contains('connect')) {
      return 'Network error. Check your connection.';
    }
    if (lower.contains('too many')) return 'Too many attempts. Try again later.';
    return 'Login failed. Please check your credentials.';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Background ambient glows
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.05),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 60),

                        // Brand mark
                        Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryContainer,
                                    AppColors.primary
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.account_balance_rounded,
                                size: 34,
                                color: AppColors.onPrimaryFixed,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'STCU',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryContainer,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SOVEREIGN DIGITAL BANKING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant
                                    .withOpacity(0.5),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 44),

                        // Form card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Access your vault',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant
                                        .withOpacity(0.55),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Error banner
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.error
                                              .withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.error,
                                            size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(_errorMessage!,
                                              style: const TextStyle(
                                                  color: AppColors.error,
                                                  fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Email
                                _buildInput(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'you@example.com',
                                  icon: Icons.alternate_email_rounded,
                                  type: TextInputType.emailAddress,
                                  enabled: !_isLoading,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                                const SizedBox(height: 14),

                                // Password
                                _buildInput(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  enabled: !_isLoading,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.onSurfaceVariant
                                          .withOpacity(0.5),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 10),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ForgotPasswordScreen()),
                                            ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: AppColors.primaryContainer,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Sign In CTA
                                _buildGradientButton(
                                  label: 'Sign In',
                                  isLoading: _isLoading,
                                  onTap: _isLoading ? null : _handleLogin,
                                ),

                                // Biometric option
                                if (_biometricAvailable) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color:
                                              AppColors.surfaceContainerHigh,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        child: Text(
                                          'or',
                                          style: TextStyle(
                                            color: AppColors.onSurfaceVariant
                                                .withOpacity(0.4),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color:
                                              AppColors.surfaceContainerHigh,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : _tryBiometricLogin,
                                      icon: const Icon(
                                          Icons.fingerprint_rounded,
                                          size: 22),
                                      label: const Text(
                                        'Sign in with Fingerprint',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.primaryContainer,
                                        side: BorderSide(
                                          color: AppColors.primaryContainer
                                              .withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?  ",
                              style: TextStyle(
                                color:
                                    AppColors.onSurfaceVariant.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen()),
                                      ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? type,
    bool obscure = false,
    bool enabled = true,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      enabled: enabled,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon,
            color: AppColors.onSurfaceVariant.withOpacity(0.5), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: AppColors.outlineVariant.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
      ),
      validator: validator,
    );
  }

  Widget _buildGradientButton({
    required String label,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryContainer, AppColors.primary],
                )
              : null,
          color: onTap == null ? AppColors.surfaceContainerHigh : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.onPrimaryFixed),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimaryFixed,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
