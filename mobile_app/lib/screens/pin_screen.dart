import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:real_banking/theme/app_colors.dart';

class PinScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final String? title;

  const PinScreen({super.key, required this.onSuccess, this.title});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  static const String _pinKey = 'transaction_pin_hash';
  static const int _pinLength = 6;
  static const int _maxAttempts = 3;
  static const int _lockoutSeconds = 30;

  String _enteredPin = '';
  String _newPin = '';
  bool _hasPin = false;
  bool _isSettingPin = false;
  bool _isConfirmingPin = false;
  int _wrongAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutRemaining = 0;
  Timer? _lockoutTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(_shakeController);
    _checkExistingPin();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingPin() async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (mounted) {
      setState(() {
        _hasPin = storedHash != null && storedHash.isNotEmpty;
        _isSettingPin = !_hasPin;
      });
    }
  }

  String _hashPin(String pin) {
    return pin.codeUnits.fold(0, (a, b) => a + b).toString();
  }

  Future<bool> _verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    return stored == _hashPin(pin);
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hashPin(pin));
  }

  void _onKeyTap(String key) {
    if (_isLockedOut) return;

    if (key == 'backspace') {
      if (_enteredPin.isNotEmpty) {
        setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
      }
      return;
    }

    if (key == 'clear') {
      setState(() => _enteredPin = '');
      return;
    }

    if (_enteredPin.length >= _pinLength) return;

    setState(() => _enteredPin += key);

    if (_enteredPin.length == _pinLength) {
      _onPinComplete();
    }
  }

  Future<void> _onPinComplete() async {
    if (_isSettingPin && !_isConfirmingPin) {
      // First entry of new PIN
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _newPin = _enteredPin;
        _enteredPin = '';
        _isConfirmingPin = true;
      });
      return;
    }

    if (_isSettingPin && _isConfirmingPin) {
      // Confirm new PIN
      if (_enteredPin == _newPin) {
        await _savePin(_enteredPin);
        if (mounted) {
          _showSnackBar('PIN set successfully!', color: AppColors.success);
          await Future.delayed(const Duration(milliseconds: 300));
          widget.onSuccess();
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 150));
        _shakeController.forward(from: 0);
        if (mounted) {
          setState(() {
            _enteredPin = '';
            _newPin = '';
            _isConfirmingPin = false;
          });
          _showSnackBar('PINs do not match. Try again.', color: AppColors.error);
        }
      }
      return;
    }

    // Verify existing PIN
    final isCorrect = await _verifyPin(_enteredPin);
    if (isCorrect) {
      if (mounted) {
        widget.onSuccess();
      }
    } else {
      _shakeController.forward(from: 0);
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _wrongAttempts++;
        });
        if (_wrongAttempts >= _maxAttempts) {
          _startLockout();
        } else {
          _showSnackBar(
            'Incorrect PIN. ${_maxAttempts - _wrongAttempts} attempt(s) remaining.',
            color: AppColors.error,
          );
        }
      }
    }
  }

  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      _lockoutRemaining = _lockoutSeconds;
      _enteredPin = '';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockoutRemaining--;
        if (_lockoutRemaining <= 0) {
          _isLockedOut = false;
          _wrongAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _tryBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        if (mounted) {
          _showSnackBar('Biometrics not available on this device.',
              color: AppColors.warning);
        }
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to confirm transaction',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (authenticated && mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Biometric authentication failed.', color: AppColors.error);
      }
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color ?? AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String get _screenTitle {
    if (_isSettingPin) {
      return _isConfirmingPin ? 'Confirm New PIN' : 'Set Transaction PIN';
    }
    return widget.title ?? 'Enter Transaction PIN';
  }

  String get _screenSubtitle {
    if (_isSettingPin) {
      return _isConfirmingPin
          ? 'Re-enter your new 6-digit PIN to confirm'
          : 'Choose a 6-digit PIN for transactions';
    }
    return 'Enter your 6-digit transaction PIN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Icon ─────────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.primaryContainer,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────────────────────
              Text(
                _screenTitle,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isLockedOut
                    ? 'Too many attempts. Try again in $_lockoutRemaining seconds'
                    : _screenSubtitle,
                style: TextStyle(
                  color: _isLockedOut ? AppColors.error : AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // ── PIN Dots ─────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? AppColors.primaryContainer
                            : Colors.transparent,
                        border: Border.all(
                          color: isFilled
                              ? AppColors.primaryContainer
                              : AppColors.outlineVariant,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(),

              // ── Lockout overlay or keypad ─────────────────────────────
              if (_isLockedOut)
                Column(
                  children: [
                    const Icon(Icons.lock_clock_rounded,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Too many attempts.\nTry again in $_lockoutRemaining seconds',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                )
              else
                _buildKeypad(),

              const SizedBox(height: 16),

              // ── Biometric button ──────────────────────────────────────
              if (!_isSettingPin)
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint_rounded,
                      color: AppColors.primary, size: 20),
                  label: const Text(
                    'Use Biometric instead',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildKeyRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildKeyRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildKeyRow(['clear', '0', 'backspace']),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    Widget label;
    if (key == 'backspace') {
      label = const Icon(Icons.backspace_rounded,
          color: AppColors.onSurface, size: 22);
    } else if (key == 'clear') {
      label = const Text(
        'CLR',
        style: TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      label = Text(
        key,
        style: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onKeyTap(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 80,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(child: label),
      ),
    );
  }
}
