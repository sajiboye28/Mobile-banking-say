import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class TwoFactorScreen extends StatefulWidget {
  final bool isSetup;
  final VoidCallback? onSuccess;

  const TwoFactorScreen({
    super.key,
    required this.isSetup,
    this.onSuccess,
  });

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  // Setup state
  bool _codeSent = false;
  bool _isSendingCode = false;

  // Verify state
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  String? _errorMessage;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  String? get _uid => PbService.instance.currentUserId;
  String? get _email => PbService.instance.pb.authStore.model?.data['email'] as String?;

  String get _maskedEmail {
    final email = _email ?? '';
    if (email.isEmpty) return '***@***.com';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 1) return '${name[0]}***@$domain';
    return '${name[0]}***@$domain';
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String _generateCode() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  Future<void> _sendCode() async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _isSendingCode = true);

    try {
      final code = _generateCode();
      final expiry = DateTime.now().add(const Duration(minutes: 10));

      await PbService.instance.pb.collection('users').update(uid, body: {
        'twoFACode': code,
        'twoFACodeExpiry': expiry.millisecondsSinceEpoch,
      });

      if (mounted) {
        setState(() {
          _isSendingCode = false;
          _codeSent = true;
          _errorMessage = null;
        });
        _startCooldown();
        _showSnack('Code sent to your email');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingCode = false);
        _showSnack('Error sending code: $e', isError: true);
      }
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  String get _enteredCode =>
      _otpControllers.map((c) => c.text).join();

  Future<void> _verifyCode() async {
    final code = _enteredCode;
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    final uid = _uid;
    if (uid == null) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final record = await PbService.instance.pb.collection('users').getOne(uid);
      final data = record.data;
      final storedCode = data['twoFACode']?.toString() ?? '';
      final expiryMs = data['twoFACodeExpiry'] as int? ?? 0;
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(expiryMs);

      if (DateTime.now().isAfter(expiry)) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Code has expired. Please request a new one.';
        });
        _clearOtp();
        return;
      }

      if (code != storedCode) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Incorrect code. Please try again.';
        });
        _clearOtp();
        return;
      }

      // Success
      await PbService.instance.pb.collection('users').update(uid, body: {
        'two_fa_enabled': true,
        'twoFACode': null,
        'twoFACodeExpiry': null,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('two_fa_enabled', true);

      if (mounted) {
        setState(() => _isVerifying = false);
        widget.onSuccess?.call();
        _showSnack('Two-Factor Authentication enabled successfully');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Verification error: $e';
        });
      }
    }
  }

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All 6 filled — auto-submit
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    }
  }

  void _onOtpBackspace(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.onSurface, size: 20),
                ),
              ),
              const SizedBox(height: 32),

              // Header icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.security_rounded,
                    color: AppColors.primaryContainer, size: 36),
              ),
              const SizedBox(height: 24),

              // Title & subtitle
              if (widget.isSetup && !_codeSent) ...[
                _buildSetupIntro(),
              ] else ...[
                _buildVerifySection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Two-Factor Authentication',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Add an extra layer of security to your account.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // How it works
        _buildInfoCard(
          icon: Icons.email_rounded,
          title: 'Email verification',
          description:
              'Each time you sign in, a one-time 6-digit code will be sent to your email address. You must enter it to complete login.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.lock_clock_rounded,
          title: 'Time-limited codes',
          description:
              'Codes expire after 10 minutes for your security. You can always request a new code if needed.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.shield_rounded,
          title: 'Even if your password leaks',
          description:
              'Nobody can access your account without also having access to your email inbox.',
        ),
        const SizedBox(height: 32),

        // Email display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      AppColors.primaryContainer.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.email_rounded,
                    color: AppColors.primaryContainer, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Code will be sent to',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _maskedEmail,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Enable button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingCode ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.primaryContainer.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSendingCode
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Enable 2FA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isSetup ? 'Verify your email' : 'Enter verification code',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
            children: [
              const TextSpan(
                  text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _maskedEmail,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const TextSpan(text: '. Enter it below.'),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // OTP input row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),
        const SizedBox(height: 16),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Verify button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isVerifying || _enteredCode.length < 6)
                ? null
                : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.primaryContainer.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Verify Code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Resend row
        Center(
          child: _resendCooldown > 0
              ? Text(
                  'Resend code in ${_resendCooldown}s',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              : GestureDetector(
                  onTap: _sendCode,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 32),

        // Info note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.onSurfaceVariant, size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Check your spam folder if you don\'t see the email. Codes expire in 10 minutes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_otpControllers[index].text.isEmpty) {
              _onOtpBackspace(index);
            }
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          maxLength: 1,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.primaryContainer, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (val) {
            setState(() {});
            _onOtpChanged(index, val);
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: AppColors.primaryContainer, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
