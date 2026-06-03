import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_banking/screens/profile_screen.dart';
import 'package:real_banking/screens/pin_screen.dart';
import 'package:real_banking/services/notification_service.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final String uid;
  const SettingsScreen({super.key, required this.uid});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _pushNotifications = true;
  bool _transactionAlerts = true;
  String _selectedCurrency = 'USD';
  String _selectedLanguage = 'English';

  static const String _appVersion = '1.0.0 (Build 1)';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _transactionAlerts = prefs.getBool('transaction_alerts') ?? true;
        _selectedCurrency = prefs.getString('preferred_currency') ?? 'USD';
        _selectedLanguage = prefs.getString('language') ?? 'English';
      });
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color ?? AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Change Password ──────────────────────────────────────────────────────

  void _showChangePasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Re-authenticate then set your new password.',
                    style: TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  // Current password
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    style: const TextStyle(
                        color: AppColors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // New password
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style: const TextStyle(
                        color: AppColors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Confirm password
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    style: const TextStyle(
                        color: AppColors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.electricGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final currentPw =
                                    currentPasswordController.text.trim();
                                final newPw = newPasswordController.text.trim();
                                final confirmPw =
                                    confirmPasswordController.text.trim();

                                if (currentPw.isEmpty ||
                                    newPw.isEmpty ||
                                    confirmPw.isEmpty) {
                                  _showSnackBar('Please fill in all fields.',
                                      color: AppColors.error);
                                  return;
                                }
                                if (newPw != confirmPw) {
                                  _showSnackBar(
                                      'New passwords do not match.',
                                      color: AppColors.error);
                                  return;
                                }
                                if (newPw.length < 6) {
                                  _showSnackBar(
                                      'Password must be at least 6 characters.',
                                      color: AppColors.error);
                                  return;
                                }

                                setSheetState(() => isLoading = true);
                                try {
                                  final pb = PbService.instance.pb;
                                  final uid = PbService.instance.currentUserId ?? widget.uid;
                                  final email = PbService.instance.currentUser?.data['email'] as String? ?? '';
                                  // Re-authenticate by signing in again
                                  await pb.collection('users').authWithPassword(email, currentPw);
                                  // Update password
                                  await pb.collection('users').update(uid, body: {
                                    'password': newPw,
                                    'passwordConfirm': newPw,
                                    'oldPassword': currentPw,
                                  });
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    _showSnackBar(
                                        'Password updated successfully!');
                                  }
                                } on ClientException catch (e) {
                                  String msg = 'Error updating password.';
                                  if (e.response['message']?.toString().contains('password') == true) {
                                    msg = 'Current password is incorrect.';
                                  }
                                  _showSnackBar(msg, color: AppColors.error);
                                } catch (e) {
                                  _showSnackBar('Error: $e',
                                      color: AppColors.error);
                                } finally {
                                  if (ctx.mounted) {
                                    setSheetState(() => isLoading = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Update Password',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Currency Picker ─────────────────────────────────────────────────────

  void _showCurrencyPicker() {
    final currencies = ['USD', 'EUR', 'GBP', 'NGN', 'CAD', 'AUD', 'JPY'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...currencies.map((c) => ListTile(
                  title: Text(c,
                      style: const TextStyle(
                          color: AppColors.onSurface, fontSize: 14)),
                  trailing: _selectedCurrency == c
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    setState(() => _selectedCurrency = c);
                    _saveString('preferred_currency', c);
                    Navigator.pop(ctx);
                    _showSnackBar('Currency changed to $c');
                  },
                )),
          ],
        ),
      ),
    );
  }

  // ─── Language Picker ─────────────────────────────────────────────────────

  void _showLanguagePicker() {
    final languages = [
      {'name': 'English', 'flag': '🇺🇸'},
      {'name': 'Spanish', 'flag': '🇪🇸'},
      {'name': 'French', 'flag': '🇫🇷'},
      {'name': 'German', 'flag': '🇩🇪'},
      {'name': 'Portuguese', 'flag': '🇧🇷'},
      {'name': 'Arabic', 'flag': '🇸🇦'},
      {'name': 'Chinese', 'flag': '🇨🇳'},
      {'name': 'Japanese', 'flag': '🇯🇵'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Language',
                style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('App language will update on next restart',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 16),
            ...languages.map((lang) => ListTile(
                  leading:
                      Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text(lang['name']!,
                      style: const TextStyle(
                          color: AppColors.onSurface, fontSize: 14)),
                  trailing: _selectedLanguage == lang['name']
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    setState(() => _selectedLanguage = lang['name']!);
                    _saveString('language', lang['name']!);
                    Navigator.pop(ctx);
                    _showSnackBar('Language changed to ${lang['name']}');
                  },
                )),
          ],
        ),
      ),
    );
  }

  // ─── Privacy Policy / Terms ───────────────────────────────────────────────

  void _showLegalSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Delete Account ───────────────────────────────────────────────────────

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text(
              'Delete Account',
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
          style: TextStyle(
              color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final uid = PbService.instance.currentUserId ?? widget.uid;
                await PbService.instance.pb.collection('users').delete(uid);
                await PbService.instance.signOut();
              } catch (e) {
                if (mounted) {
                  _showSnackBar(
                    'Could not delete account. Please re-login and try again.',
                    color: AppColors.error,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ─── TCC Code Dialog ──────────────────────────────────────────────────────

  void _showChangeTccDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change TCC Code',
            style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter a new 4–6 digit Transaction Confirmation Code.',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          GestureDetector(
            onTap: () async {
              final code = controller.text.trim();
              if (code.length < 4) return;
              await PbService.instance.pb
                  .collection('users')
                  .update(widget.uid, body: {'tccCode': code});
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) _showSnackBar('TCC code updated');
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: AppColors.electricGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Update',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            pinned: true,
            title: const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── ACCOUNT ──────────────────────────────────────────────
                _sectionLabel('ACCOUNT'),
                _tile(
                  icon: Icons.person_rounded,
                  color: AppColors.primaryContainer,
                  label: 'Edit Profile',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileScreen(uid: widget.uid))),
                ),
                _tile(
                  icon: Icons.lock_reset_rounded,
                  color: AppColors.warning,
                  label: 'Change Password',
                  onTap: _showChangePasswordSheet,
                ),
                const SizedBox(height: 24),

                // ── SECURITY ─────────────────────────────────────────────
                _sectionLabel('SECURITY'),
                _toggleTile(
                  icon: Icons.fingerprint_rounded,
                  color: AppColors.success,
                  label: 'Biometric Lock',
                  value: _biometricEnabled,
                  onChanged: (v) {
                    setState(() => _biometricEnabled = v);
                    _saveBool('biometric_enabled', v);
                  },
                ),
                _tile(
                  icon: Icons.pin_rounded,
                  color: AppColors.error,
                  label: 'Change TCC Code',
                  onTap: _showChangeTccDialog,
                ),
                _tile(
                  icon: Icons.pin_rounded,
                  color: AppColors.primaryContainer,
                  label: 'Transaction PIN',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PinScreen(
                        onSuccess: () => Navigator.pop(context),
                        title: 'Manage Transaction PIN',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── NOTIFICATIONS ─────────────────────────────────────────
                _sectionLabel('NOTIFICATIONS'),
                _toggleTile(
                  icon: Icons.notifications_rounded,
                  color: AppColors.secondary,
                  label: 'Push Notifications',
                  value: _pushNotifications,
                  onChanged: (v) async {
                    setState(() => _pushNotifications = v);
                    await _saveBool('push_notifications', v);
                    await NotificationService.setEnabled(v);
                  },
                ),
                _toggleTile(
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.secondary,
                  label: 'Transaction Alerts',
                  value: _transactionAlerts,
                  onChanged: (v) {
                    setState(() => _transactionAlerts = v);
                    _saveBool('transaction_alerts', v);
                  },
                ),
                // Dark mode toggle — always disabled
                _toggleTile(
                  icon: Icons.dark_mode_rounded,
                  color: AppColors.onSurfaceVariant,
                  label: 'Dark Mode',
                  value: true,
                  onChanged: (_) {
                    _showSnackBar('App is always in dark mode',
                        color: AppColors.primaryContainer);
                  },
                  disabled: true,
                ),
                const SizedBox(height: 24),

                // ── APP ────────────────────────────────────────────────────
                _sectionLabel('APP'),
                _tile(
                  icon: Icons.currency_exchange_rounded,
                  color: AppColors.warning,
                  label: 'Currency',
                  trailing: Text(_selectedCurrency,
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 14)),
                  onTap: _showCurrencyPicker,
                ),
                _tile(
                  icon: Icons.language_rounded,
                  color: AppColors.primaryContainer,
                  label: 'Language',
                  trailing: Text(_selectedLanguage,
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 14)),
                  onTap: _showLanguagePicker,
                ),
                const SizedBox(height: 24),

                // ── ABOUT ──────────────────────────────────────────────────
                _sectionLabel('ABOUT'),
                _tile(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.onSurfaceVariant,
                  label: 'App Version',
                  trailing: const Text(
                    _appVersion,
                    style: TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
                  // no onTap — version has no action
                ),
                _tile(
                  icon: Icons.description_rounded,
                  color: AppColors.onSurfaceVariant,
                  label: 'Terms of Service',
                  onTap: () => _showLegalSheet(
                    'Terms of Service',
                    'Welcome to Real Banking. By using our services, you agree to these terms.\n\n'
                        '1. Account Responsibility\nYou are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.\n\n'
                        '2. Prohibited Activities\nYou may not use our services for any illegal or unauthorized purpose, including but not limited to money laundering, fraud, or financing terrorism.\n\n'
                        '3. Fees and Charges\nWe may charge fees for certain services. All applicable fees will be disclosed before any transaction is completed.\n\n'
                        '4. Termination\nWe reserve the right to suspend or terminate your account at any time for violations of these terms.\n\n'
                        '5. Changes to Terms\nWe may update these terms from time to time. Continued use of our services after changes constitutes acceptance.\n\n'
                        'For questions, contact support@realbanking.com.',
                  ),
                ),
                _tile(
                  icon: Icons.privacy_tip_rounded,
                  color: AppColors.onSurfaceVariant,
                  label: 'Privacy Policy',
                  onTap: () => _showLegalSheet(
                    'Privacy Policy',
                    'Real Banking is committed to protecting your privacy.\n\n'
                        '1. Information We Collect\nWe collect information you provide when creating an account, making transactions, or contacting support. This includes name, email, phone number, and financial data.\n\n'
                        '2. How We Use Your Information\nWe use your data to provide banking services, prevent fraud, comply with legal obligations, and improve our products.\n\n'
                        '3. Data Sharing\nWe do not sell your personal data. We may share data with regulatory authorities when required by law.\n\n'
                        '4. Data Security\nWe use industry-standard encryption and security measures to protect your data.\n\n'
                        '5. Your Rights\nYou have the right to access, correct, or delete your personal data. Contact us at privacy@realbanking.com.\n\n'
                        '6. Cookies\nWe use cookies to improve your experience. You can manage cookie preferences in your device settings.',
                  ),
                ),
                _tile(
                  icon: Icons.article_rounded,
                  color: AppColors.onSurfaceVariant,
                  label: 'Licenses',
                  onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Real Banking',
                      applicationVersion: _appVersion),
                ),
                const SizedBox(height: 24),

                // ── DANGER ZONE ────────────────────────────────────────────
                _sectionLabel('ACCOUNT ACTIONS'),
                _tile(
                  icon: Icons.logout_rounded,
                  color: AppColors.warning,
                  label: 'Sign Out',
                  onTap: () async {
                    await PbService.instance.signOut();
                  },
                ),
                _tile(
                  icon: Icons.delete_forever_rounded,
                  color: AppColors.error,
                  label: 'Delete Account',
                  onTap: _showDeleteAccountDialog,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5)),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color color,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right_rounded,
                        color: AppColors.onSurfaceVariant, size: 18)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color color,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool disabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (disabled ? AppColors.onSurfaceVariant : color)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: disabled ? AppColors.onSurfaceVariant : color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: disabled
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          Opacity(
            opacity: disabled ? 0.4 : 1.0,
            child: _buildToggle(value, disabled ? (_) {} : onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
