import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/services/auth_service.dart';
import 'package:real_banking/models/user_model.dart';
import 'package:real_banking/screens/login_screen.dart';
import 'package:real_banking/screens/home_screen.dart';
import 'package:real_banking/screens/suspended_screen.dart';
import 'package:real_banking/screens/pending_screen.dart';
import 'package:real_banking/screens/onboarding_screen.dart';
import 'package:real_banking/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surfaceContainerLow,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Restore any saved PocketBase auth session from disk
  try {
    await PbService.create();
  } catch (e) {
    debugPrint('[PbService] create error: $e');
  }

  runApp(const RealBankingApp());
}

class RealBankingApp extends StatelessWidget {
  const RealBankingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryContainer,
          onPrimary: AppColors.onPrimaryFixed,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          error: AppColors.error,
          onError: AppColors.onError,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onSurface,
          titleTextStyle: TextStyle(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
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
            borderSide: const BorderSide(
                color: AppColors.primaryContainer, width: 2),
          ),
          labelStyle: TextStyle(
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
              fontSize: 14),
          hintStyle: TextStyle(
              color: AppColors.onSurfaceVariant.withOpacity(0.3),
              fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -2,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -1,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.surfaceContainerHigh,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceContainerHighest,
          contentTextStyle:
              const TextStyle(color: AppColors.onSurface, fontSize: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
      ),
      home: const AppRouter(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppRouter — checks onboarding, PocketBase auth, then account status
// ─────────────────────────────────────────────────────────────────────────────
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});
  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool? _onboardingDone;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _init();
    _pollMaintenanceMode();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
          () => _onboardingDone = prefs.getBool('onboarding_complete') ?? false);
    }
  }

  /// Poll the PocketBase systemConfig collection for maintenanceMode.
  /// We use a one-shot fetch; for true real-time you can subscribe.
  Future<void> _pollMaintenanceMode() async {
    try {
      final record = await PbService.instance.pb
          .collection('systemConfig')
          .getFirstListItem('id != ""');
      if (!mounted) return;
      final m = record.data['maintenanceMode'] == true;
      if (m != _maintenanceMode) setState(() => _maintenanceMode = m);
    } catch (_) {
      // Collection may not exist — ignore silently
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) return const _SplashScreen();

    if (!_onboardingDone!) {
      return OnboardingScreen(onComplete: () {
        setState(() => _onboardingDone = true);
      });
    }

    final isLoggedIn = PbService.instance.isLoggedIn;

    if (!isLoggedIn) return const LoginScreen();

    if (_maintenanceMode) return const _MaintenanceScreen();

    final userId = PbService.instance.currentUserId!;
    return BiometricGate(child: AccountStatusGate(userId: userId));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Maintenance Screen
// ─────────────────────────────────────────────────────────────────────────────
class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primaryContainer, AppColors.primary]),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(Icons.build_rounded,
                      size: 44, color: AppColors.onPrimaryFixed),
                ),
                const SizedBox(height: 32),
                const Text('Under Maintenance',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface)),
                const SizedBox(height: 14),
                Text("We'll be back shortly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant.withOpacity(0.6),
                        height: 1.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash Screen
// ─────────────────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'NEXUS',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryContainer,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'DIGITAL BANKING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primaryContainer,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Biometric Gate — prompts fingerprint/face if biometric_enabled is true
// ─────────────────────────────────────────────────────────────────────────────
class BiometricGate extends StatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;
  int _failedAttempts = 0;
  static const int _maxAttempts = 3;
  bool _showPasswordFallback = false;
  DateTime? _backgroundedAt;
  static const _kLockAfter = Duration(minutes: 5);

  // Password fallback controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _fallbackLoading = false;
  String? _fallbackError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometric();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isAuthenticated && !_isAuthenticating) {
        _backgroundedAt = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed && _biometricEnabled) {
      final bg = _backgroundedAt;
      if (bg != null &&
          DateTime.now().difference(bg) >= _kLockAfter &&
          !_isAuthenticating) {
        setState(() {
          _isAuthenticated = false;
          _failedAttempts = 0;
          _showPasswordFallback = false;
        });
        _promptBiometric();
      }
      _backgroundedAt = null;
    }
  }

  Future<void> _checkBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
    if (enabled) {
      await _promptBiometric();
    } else {
      setState(() => _isAuthenticated = true);
    }
  }

  Future<void> _promptBiometric() async {
    if (_isAuthenticating || _showPasswordFallback) return;
    try {
      final available =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!available) {
        setState(() => _isAuthenticated = true);
        return;
      }
      setState(() => _isAuthenticating = true);
      final authenticated = await _auth.authenticate(
        localizedReason: 'Touch the sensor to access Nexus Digital Banking',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (authenticated) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
          _failedAttempts = 0;
        });
      } else {
        setState(() {
          _isAuthenticating = false;
          _failedAttempts++;
          if (_failedAttempts >= _maxAttempts) _showPasswordFallback = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _failedAttempts++;
        if (_failedAttempts >= _maxAttempts) _showPasswordFallback = true;
      });
    }
  }

  Future<void> _loginWithPassword() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _fallbackError = 'Enter your email and password.');
      return;
    }
    setState(() {
      _fallbackLoading = true;
      _fallbackError = null;
    });
    try {
      await PbService.instance.pb
          .collection('users')
          .authWithPassword(email, pass);
      if (!mounted) return;
      setState(() {
        _isAuthenticated = true;
        _fallbackLoading = false;
        _failedAttempts = 0;
        _showPasswordFallback = false;
      });
    } on ClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _fallbackLoading = false;
        _fallbackError = e.response['message'] as String? ??
            'Incorrect email or password.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fallbackLoading = false;
        _fallbackError = 'Incorrect email or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: _showPasswordFallback
                ? _buildPasswordFallback()
                : _buildBiometricPrompt(),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricPrompt() {
    final attemptsLeft = _maxAttempts - _failedAttempts;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primaryContainer, AppColors.primary]),
            borderRadius: BorderRadius.circular(24),
          ),
          child:
              const Icon(Icons.fingerprint_rounded, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 28),
        const Text('Biometric Lock',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface)),
        const SizedBox(height: 10),
        Text(
          _failedAttempts == 0
              ? 'Touch the fingerprint sensor to unlock'
              : 'Fingerprint not recognised. $attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} remaining.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _failedAttempts > 0
                ? AppColors.error
                : AppColors.onSurfaceVariant.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: _isAuthenticating ? null : _promptBiometric,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.primary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAuthenticating)
                  const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                else
                  const Icon(Icons.fingerprint_rounded,
                      color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text('Authenticate',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFallback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_outline_rounded,
              size: 36, color: AppColors.error),
        ),
        const Text('Too Many Attempts',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Biometric failed $_maxAttempts times.\nPlease sign in with your password.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant.withOpacity(0.6),
              height: 1.5),
        ),
        const SizedBox(height: 32),
        if (_fallbackError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_fallbackError!,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration:
              const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded)),
          onSubmitted: (_) => _loginWithPassword(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _fallbackLoading ? null : _loginWithPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _fallbackLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Sign In',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _failedAttempts = 0;
            _showPasswordFallback = false;
          }),
          child: const Text('Try biometric again',
              style: TextStyle(color: AppColors.primaryContainer)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Status Gate — fetches the user record from PocketBase and routes
// ─────────────────────────────────────────────────────────────────────────────
class AccountStatusGate extends StatefulWidget {
  final String userId;

  const AccountStatusGate({super.key, required this.userId});

  @override
  State<AccountStatusGate> createState() => _AccountStatusGateState();
}

class _AccountStatusGateState extends State<AccountStatusGate> {
  UserModel? _userModel;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _subscribeToUser();
  }

  Future<void> _loadUser() async {
    try {
      final record = await PbService.instance.pb
          .collection('users')
          .getOne(widget.userId);
      if (!mounted) return;
      setState(() {
        _userModel = UserModel.fromRecord(record);
        _loading = false;
      });
    } catch (e) {
      debugPrint('[AccountStatusGate] load error: $e');
      if (!mounted) return;
      // If the record genuinely doesn't exist, sign out
      if (e is ClientException && e.statusCode == 404) {
        await PbService.instance.signOut();
      } else {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _subscribeToUser() {
    PbService.instance.pb
        .collection('users')
        .subscribe(widget.userId, (event) {
      if (!mounted) return;
      if (event.record != null) {
        setState(() => _userModel = UserModel.fromRecord(event.record!));
      }
    });
  }

  @override
  void dispose() {
    PbService.instance.pb.collection('users').unsubscribe(widget.userId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();

    if (_error || _userModel == null) {
      return _SetupScreen(onSignOut: () => PbService.instance.signOut());
    }

    final user = _userModel!;

    if (user.isSuspended) return const SuspendedScreen();
    if (user.isClosed) return _ClosedAccountScreen(onSignOut: () => PbService.instance.signOut());
    if (user.isPending) return const PendingScreen();
    // Frozen: user can see home but canTransact is false (set by admin)
    return HomeScreen(userModel: user);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setup Screen (while creating / loading PocketBase record)
// ─────────────────────────────────────────────────────────────────────────────
class _SetupScreen extends StatelessWidget {
  final VoidCallback? onSignOut;
  const _SetupScreen({this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryContainer, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      size: 36, color: AppColors.onPrimaryFixed),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Setting up your vault...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryContainer,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: onSignOut,
                  child: Text(
                    'Sign out and try again',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// Closed Account Screen
// ─────────────────────────────────────────────────────────────────────────────
class _ClosedAccountScreen extends StatelessWidget {
  final VoidCallback? onSignOut;
  const _ClosedAccountScreen({this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded,
                      size: 40, color: AppColors.error),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Account Closed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account has been permanently closed.\nContact support for assistance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                GestureDetector(
                  onTap: onSignOut,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
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
