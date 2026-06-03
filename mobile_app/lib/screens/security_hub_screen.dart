import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:real_banking/screens/two_factor_screen.dart';

class SecurityHubScreen extends StatefulWidget {
  final String uid;

  const SecurityHubScreen({super.key, required this.uid});

  @override
  State<SecurityHubScreen> createState() => _SecurityHubScreenState();
}

class _SecurityHubScreenState extends State<SecurityHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  bool _biometricEnabled = false;
  bool _twoFaEnabled = false;
  bool _loginAlertsEnabled = false;
  bool _dataSharing = false;
  bool _ghostMode = false;

  // Active sessions — index 0 is always "this device"
  late List<_SessionEntry> _sessions;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );
    _sessions = [
      _SessionEntry(
        id: 'current',
        title: 'This device (current)',
        subtitle: 'Active now',
        icon: Icons.smartphone_rounded,
        badgeLabel: 'CURRENT',
        badgeColor: AppColors.primary,
        isCurrent: true,
      ),
      _SessionEntry(
        id: 'chrome_windows',
        title: 'Chrome on Windows',
        subtitle: '2 hours ago',
        icon: Icons.laptop_rounded,
        badgeLabel: '2h ago',
        badgeColor: AppColors.onSurfaceVariant,
        isCurrent: false,
      ),
      _SessionEntry(
        id: 'safari_iphone',
        title: 'Safari on iPhone',
        subtitle: '1 day ago',
        icon: Icons.phone_iphone_rounded,
        badgeLabel: '1d ago',
        badgeColor: AppColors.onSurfaceVariant,
        isCurrent: false,
      ),
    ];
    _loadPreferences();
    _scoreController.forward();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        _loginAlertsEnabled = prefs.getBool('login_alerts_enabled') ?? false;
        _dataSharing = prefs.getBool('data_sharing') ?? false;
        _ghostMode = prefs.getBool('ghost_mode') ?? false;
      });
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  int _calculateScore(Map<String, dynamic> userData) {
    int score = 0;
    if (userData['accountStatus'] == 'active') score += 25;
    if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
      score += 25;
    }
    if (userData['profilePicUrl'] != null &&
        userData['profilePicUrl'].toString().isNotEmpty) score += 10;
    if (_biometricEnabled) score += 40;
    return score;
  }

  void _showSnackBar(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Two-FA toggle + explanation sheet ──────────────────────────────────

  Future<void> _toggle2FA(bool value) async {
    if (value && mounted) {
      // Navigate to TwoFactorScreen setup flow; Firestore update happens inside on success
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TwoFactorScreen(
            isSetup: true,
            onSuccess: () {
              if (mounted) setState(() => _twoFaEnabled = true);
            },
          ),
        ),
      );
    } else {
      await PbService.instance.pb
          .collection('users')
          .update(widget.uid, body: {'two_fa_enabled': false});
      setState(() => _twoFaEnabled = false);
      if (mounted) {
        _showSnackBar('Two-Factor Authentication disabled');
      }
    }
  }

  // ─── Terminate session ───────────────────────────────────────────────────

  void _terminateSession(String sessionId) {
    setState(() {
      _sessions.removeWhere((s) => s.id == sessionId);
    });
    _showSnackBar('Session terminated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<RecordModel>(
        future: PbService.instance.pb.collection('users').getOne(widget.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryContainer,
                strokeWidth: 2.5,
              ),
            );
          }

          final userData = snapshot.data!.data;
          final score = _calculateScore(userData);
          // Sync 2FA from PocketBase on every rebuild
          final firestoreTwoFa = userData['two_fa_enabled'] as bool? ?? false;
          if (firestoreTwoFa != _twoFaEnabled) {
            // Use post-frame to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _twoFaEnabled = firestoreTwoFa);
            });
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Security Hub',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Vault status card
                      _buildVaultStatusCard(score),
                      const SizedBox(height: 28),

                      // ── Access & Identity ─────────────────────────────
                      _buildSectionLabel('Access & Identity'),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        icon: Icons.fingerprint_rounded,
                        title: 'Face ID / Touch ID',
                        subtitle: _biometricEnabled
                            ? 'ACTIVE PROTECTION'
                            : 'DISABLED',
                        value: _biometricEnabled,
                        onChanged: (val) {
                          setState(() => _biometricEnabled = val);
                          _savePref('biometric_enabled', val);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildToggleRow(
                        icon: Icons.security_rounded,
                        title: 'Two-Factor Authentication',
                        subtitle: _twoFaEnabled
                            ? 'EMAIL OTP ENABLED'
                            : 'DISABLED',
                        value: _twoFaEnabled,
                        onChanged: _toggle2FA,
                      ),
                      const SizedBox(height: 8),
                      _buildToggleRow(
                        icon: Icons.notifications_active_rounded,
                        title: 'Login Alerts',
                        subtitle: _loginAlertsEnabled
                            ? 'REAL-TIME ALERTS'
                            : 'DISABLED',
                        value: _loginAlertsEnabled,
                        onChanged: (val) {
                          setState(() => _loginAlertsEnabled = val);
                          _savePref('login_alerts_enabled', val);
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Active Sessions ────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel('Active Sessions'),
                          Text(
                            '${_sessions.length} ACTIVE',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildActiveSessionsList(),
                      const SizedBox(height: 28),

                      // ── Privacy ────────────────────────────────────────
                      _buildSectionLabel('Privacy Architecture'),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        icon: Icons.share_rounded,
                        title: 'Data Sharing',
                        subtitle: 'ANALYTICS WITH NEXUS',
                        value: _dataSharing,
                        onChanged: (val) {
                          setState(() => _dataSharing = val);
                          _savePref('data_sharing', val);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildToggleRow(
                        icon: Icons.visibility_off_rounded,
                        title: 'Ghost Mode',
                        subtitle: 'HIDE BALANCE ON HOME',
                        value: _ghostMode,
                        onChanged: (val) {
                          setState(() => _ghostMode = val);
                          _savePref('ghost_mode', val);
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Security Actions ───────────────────────────────
                      _buildSectionLabel('Security Actions'),
                      const SizedBox(height: 12),
                      _buildActionRow(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.error,
                        title: 'Terminate All Sessions',
                        subtitle: 'Sign out from all other devices',
                        onTap: () => _showTerminateDialog(),
                        isDanger: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Active Sessions List ────────────────────────────────────────────────

  Widget _buildActiveSessionsList() {
    if (_sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'No active sessions',
            style:
                TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: _sessions.asMap().entries.map((entry) {
          final idx = entry.key;
          final session = entry.value;
          final isFirst = idx == 0;
          final isLast = idx == _sessions.length - 1;
          return _buildSessionRow(session, isFirst, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildSessionRow(
      _SessionEntry session, bool isFirst, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : const Border(
                top: BorderSide(
                    color: AppColors.outlineVariant, width: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(session.icon,
                color: AppColors.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    )),
                const SizedBox(height: 2),
                Text(session.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    )),
              ],
            ),
          ),
          if (session.isCurrent)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.badgeLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: session.badgeColor,
                  letterSpacing: 1,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _terminateSession(session.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Terminate',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Vault Status Card ───────────────────────────────────────────────────

  Widget _buildVaultStatusCard(int score) {
    final isSecure = score >= 70;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withOpacity(0.4),
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryContainer.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withOpacity(0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Icon(
                  isSecure
                      ? Icons.verified_user_rounded
                      : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, _) {
                  return Text(
                    isSecure ? 'Your Vault is Secure' : 'Needs Attention',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Security score: $score / 100 • Last audit: just now',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 2,
      ),
    );
  }

  // ─── Toggle Row ───────────────────────────────────────────────────────────

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    )),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1,
                    )),
              ],
            ),
          ),
          _buildToggleSwitch(value, onChanged),
        ],
      ),
    );
  }

  // ─── Action Row ───────────────────────────────────────────────────────────

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDanger
              ? AppColors.error.withOpacity(0.06)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: isDanger
              ? Border.all(
                  color: AppColors.error.withOpacity(0.15), width: 0.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDanger ? AppColors.error : AppColors.onSurface,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTerminateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Terminate Sessions?',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface)),
          ],
        ),
        content: const Text(
          'This will sign you out on all devices. You will need to sign in again.',
          style:
              TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await PbService.instance.signOut();
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Error: $e', color: AppColors.error);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Terminate All',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _SessionEntry {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeLabel;
  final Color badgeColor;
  final bool isCurrent;

  const _SessionEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeLabel,
    required this.badgeColor,
    required this.isCurrent,
  });
}
