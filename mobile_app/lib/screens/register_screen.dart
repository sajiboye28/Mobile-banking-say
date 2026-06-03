import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/services/auth_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  String? _errorMessage;

  // Password strength (0–4)
  int _passwordStrength = 0;

  // Email availability: null=unchecked, true=available, false=taken
  bool? _emailAvailable;
  Timer? _emailDebounce;
  bool _emailChecking = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _passwordController.addListener(_onPasswordChanged);
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _animController.dispose();
    _emailDebounce?.cancel();
    super.dispose();
  }

  bool get _anyLoading => _isLoading;

  // ── Password strength ────────────────────────────────────────────────────
  void _onPasswordChanged() {
    final p = _passwordController.text;
    int strength = 0;
    if (p.length >= 8) strength++;
    if (p.contains(RegExp(r'[A-Z]'))) strength++;
    if (p.contains(RegExp(r'[0-9]'))) strength++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  // ── Email availability debounce ──────────────────────────────────────────
  void _onEmailChanged() {
    _emailDebounce?.cancel();
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailAvailable = null;
        _emailChecking = false;
      });
      return;
    }
    setState(() {
      _emailChecking = true;
      _emailAvailable = null;
    });
    _emailDebounce = Timer(const Duration(milliseconds: 900), () async {
      try {
        // PocketBase: check if any user record has this email
        final result = await PbService.instance.pb
            .collection('users')
            .getList(
              page: 1,
              perPage: 1,
              filter: 'email = "$email"',
            );
        if (mounted) {
          setState(() {
            _emailAvailable = result.items.isEmpty;
            _emailChecking = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _emailChecking = false);
      }
    });
  }

  // ── Registration ─────────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      setState(() =>
          _errorMessage = 'Please accept the Terms & Conditions to continue.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final record = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );

      // Save referral code if provided (best-effort update)
      final ref = _referralController.text.trim();
      if (ref.isNotEmpty) {
        try {
          await PbService.instance.pb
              .collection('users')
              .update(record.id, body: {'referredBy': ref});
        } catch (_) {}
      }

      if (mounted) Navigator.pop(context);
    } on ClientException catch (e) {
      setState(() {
        final data = e.response['data'] as Map<String, dynamic>? ?? {};
        final emailErr =
            (data['email']?['message'] as String?) ?? '';
        final passErr =
            (data['password']?['message'] as String?) ?? '';
        final msg =
            e.response['message'] as String? ?? '';

        if (emailErr.toLowerCase().contains('unique') ||
            msg.toLowerCase().contains('unique') ||
            msg.toLowerCase().contains('already')) {
          _errorMessage = 'An account already exists with this email.';
        } else if (passErr.isNotEmpty) {
          _errorMessage = 'Password is too weak. Use at least 8 characters.';
        } else if (msg.isNotEmpty) {
          _errorMessage = msg;
        } else {
          _errorMessage = 'Registration failed. Please try again.';
        }
      });
    } catch (_) {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Terms bottom sheet ───────────────────────────────────────────────────
  void _showTerms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Terms & Conditions',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Last updated: March 2026',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant.withOpacity(0.5)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _termsSection('1. Acceptance of Terms',
                        'By creating an account on STCU Digital Banking, you agree to be bound by these Terms and Conditions. If you do not agree, please do not register.'),
                    _termsSection('2. Eligibility',
                        'You must be at least 18 years of age and a legal resident of a supported jurisdiction to open an account.'),
                    _termsSection('3. Account Security',
                        'You are responsible for maintaining the confidentiality of your login credentials. You must notify us immediately of any unauthorized access to your account.'),
                    _termsSection('4. Transactions',
                        'All transactions are final once confirmed. STCU Digital Banking reserves the right to reverse or freeze transactions suspected of fraud or policy violations.'),
                    _termsSection('5. Privacy',
                        'Your personal data is handled in accordance with our Privacy Policy. We do not sell your data to third parties.'),
                    _termsSection('6. Fees',
                        'Standard transfers are free. Certain premium services may carry fees which will be clearly disclosed before confirmation.'),
                    _termsSection('7. Termination',
                        'We reserve the right to suspend or terminate accounts that violate these terms, engage in fraudulent activity, or misuse the platform.'),
                    _termsSection('8. Governing Law',
                        'These terms are governed by applicable financial regulations. Any disputes shall be handled through our internal resolution process before legal proceedings.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _termsSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withOpacity(0.7),
                  height: 1.55)),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error message
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(_errorMessage!,
                                        style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            enabled: !_anyLoading,
                            style: const TextStyle(
                                color: AppColors.onSurface),
                            decoration: _inputDeco(
                                label: 'Full Name',
                                hint: 'John Doe',
                                icon: Icons.person_outlined),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Please enter your full name'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Email + availability indicator
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_anyLoading,
                            style: const TextStyle(
                                color: AppColors.onSurface),
                            decoration: _inputDeco(
                              label: 'Email Address',
                              hint: 'you@example.com',
                              icon: Icons.email_outlined,
                            ).copyWith(suffixIcon: _emailSuffixIcon()),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Please enter your email'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !_anyLoading,
                            style: const TextStyle(
                                color: AppColors.onSurface),
                            decoration: _inputDeco(
                              label: 'Password',
                              hint: 'Min. 8 characters',
                              icon: Icons.lock_outlined,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 8)
                                ? 'Password must be at least 8 characters'
                                : null,
                          ),

                          // Password strength bars
                          if (_passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildPasswordStrengthIndicator(),
                          ],
                          const SizedBox(height: 14),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            enabled: !_anyLoading,
                            style: const TextStyle(
                                color: AppColors.onSurface),
                            decoration: _inputDeco(
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              icon: Icons.lock_outlined,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                            ),
                            validator: (v) =>
                                v != _passwordController.text
                                    ? 'Passwords do not match'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Referral Code (optional)
                          TextFormField(
                            controller: _referralController,
                            enabled: !_anyLoading,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                                color: AppColors.onSurface),
                            decoration: _inputDeco(
                              label: 'Referral Code (optional)',
                              hint: 'e.g. NXS-A1B2C3',
                              icon: Icons.card_giftcard_rounded,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Terms & Conditions checkbox
                          _buildTermsCheckbox(),
                          const SizedBox(height: 20),

                          // Create Account button
                          GestureDetector(
                            onTap: _anyLoading ? null : _handleRegister,
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: AppColors.electricGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryContainer
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Admin approval notice
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    color: AppColors.success, size: 16),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "You're all set! We'll send you an email confirmation shortly. Welcome aboard!",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sign in link
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 14)),
                      GestureDetector(
                        onTap:
                            _anyLoading ? null : () => Navigator.pop(context),
                        child: const Text('Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Password strength indicator ───────────────────────────────────────────
  Widget _buildPasswordStrengthIndicator() {
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final barColors = [
      AppColors.error,
      AppColors.warning,
      AppColors.warningDim,
      AppColors.success,
    ];

    String label = '';
    Color labelColor = AppColors.error;
    if (_passwordStrength > 0) {
      label = labels[_passwordStrength - 1];
      labelColor = barColors[_passwordStrength - 1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < _passwordStrength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: filled
                      ? barColors[_passwordStrength - 1]
                      : AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelColor),
          ),
        ],
      ],
    );
  }

  // ── Email suffix icon ─────────────────────────────────────────────────────
  Widget? _emailSuffixIcon() {
    if (_emailChecking) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.onSurfaceVariant),
        ),
      );
    }
    if (_emailAvailable == true) {
      return const Icon(Icons.check_circle_rounded,
          color: AppColors.success, size: 20);
    }
    if (_emailAvailable == false) {
      return const Icon(Icons.cancel_rounded,
          color: AppColors.error, size: 20);
    }
    return null;
  }

  // ── Terms checkbox ────────────────────────────────────────────────────────
  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _termsAccepted = !_termsAccepted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _termsAccepted
                  ? AppColors.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _termsAccepted
                    ? AppColors.primaryContainer
                    : AppColors.outlineVariant.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: _termsAccepted
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  'I agree to the ',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant.withOpacity(0.7)),
                ),
                GestureDetector(
                  onTap: _showTerms,
                  child: const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.onSurface, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.electricGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'STCU',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryContainer,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create your vault account',
              style: TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
    );
  }
}
