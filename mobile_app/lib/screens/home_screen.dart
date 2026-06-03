import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/models/user_model.dart';
import 'package:real_banking/models/transaction_model.dart';
import 'package:real_banking/services/auth_service.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:real_banking/screens/send_money_screen.dart';
import 'package:real_banking/screens/transactions_screen.dart';
import 'package:real_banking/screens/transaction_detail_screen.dart';
import 'package:real_banking/screens/profile_screen.dart';
import 'package:real_banking/screens/request_money_screen.dart';
import 'package:real_banking/screens/bill_pay_screen.dart';
import 'package:real_banking/screens/savings_goals_screen.dart';
import 'package:real_banking/screens/card_management_screen.dart';
import 'package:real_banking/screens/currency_converter_screen.dart';
import 'package:real_banking/screens/account_summary_screen.dart';
import 'package:real_banking/screens/atm_locator_screen.dart';
import 'package:real_banking/screens/notifications_screen.dart';
import 'package:real_banking/screens/qr_generate_screen.dart';
import 'package:real_banking/screens/qr_scan_screen.dart';
import 'package:real_banking/screens/security_hub_screen.dart';
import 'package:real_banking/screens/insights_screen.dart';
import 'package:real_banking/screens/identity_verification_screen.dart';
import 'package:real_banking/screens/add_money_screen.dart';
import 'package:real_banking/screens/settings_screen.dart';
import 'package:real_banking/screens/loan_screen.dart';
import 'package:real_banking/screens/referral_screen.dart';
import 'package:real_banking/screens/investments_screen.dart';
import 'package:real_banking/screens/scheduled_payments_screen.dart';
import 'package:real_banking/screens/crypto_screen.dart';
import 'package:real_banking/screens/split_bill_screen.dart';
import 'package:real_banking/screens/financial_news_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final UserModel userModel;

  const HomeScreen({super.key, required this.userModel});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.userModel;
    // Subscribe to live user record changes from PocketBase
    PbService.instance.pb
        .collection('users')
        .subscribe(_currentUser.id, (event) {
      if (!mounted) return;
      if (event.record != null) {
        setState(() => _currentUser = UserModel.fromRecord(event.record!));
      }
    });
  }

  @override
  void dispose() {
    PbService.instance.pb
        .collection('users')
        .unsubscribe(_currentUser.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _HomeContent(currentUser: _currentUser, authService: _authService),
      CardManagementScreen(uid: _currentUser.id, userName: _currentUser.fullName),
      TransactionsScreen(uid: _currentUser.id),
      ProfileScreen(uid: _currentUser.id),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: _SovereignBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sovereign Vault Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SovereignBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SovereignBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            top: 8,
            left: 8,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withOpacity(0.85),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.credit_card_rounded,
                  label: 'Cards',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1)),
              _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'History',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2)),
              _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : AppColors.onSurface.withOpacity(0.45),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : AppColors.onSurface.withOpacity(0.45),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Home Content
// ─────────────────────────────────────────────────────────────────────────────
class _HomeContent extends StatefulWidget {
  final UserModel currentUser;
  final AuthService authService;

  const _HomeContent({required this.currentUser, required this.authService});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  bool _balanceVisible = true;
  Timer? _inactivityTimer;
  static const int _kInactivityMinutes = 5;
  bool _showWhatsNew = false;

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: _kInactivityMinutes), _signOutDueToInactivity);
  }

  Future<void> _signOutDueToInactivity() async {
    if (!mounted) return;
    await PbService.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    _resetTimer();
    _loadWhatsNew();
  }

  Future<void> _loadWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('whats_new_v1_1_dismissed') ?? false;
    if (!dismissed && mounted) setState(() => _showWhatsNew = true);
  }

  Future<void> _dismissWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('whats_new_v1_1_dismissed', true);
    if (mounted) setState(() => _showWhatsNew = false);
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetTimer,
      onPanDown: (_) => _resetTimer(),
      child: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primaryContainer,
        backgroundColor: AppColors.surfaceContainerLow,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding:
              const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            if (_showWhatsNew) ...[
              _WhatsNewBanner(onDismiss: _dismissWhatsNew),
              const SizedBox(height: 16),
            ],
            _buildTopBar(context),
            const SizedBox(height: 24),
            _buildHeroBalanceCard(context, currencyFormat),
            const SizedBox(height: 16),
            _buildMonthlyStatsCard(context),
            const SizedBox(height: 20),
            _buildQuickActionsSection(context),
            const SizedBox(height: 28),
            _buildQuickSendSection(context),
            const SizedBox(height: 28),
            _buildRecentActivitySection(context, currencyFormat),
            const SizedBox(height: 16),
            _buildAccountDetailsCard(context),
          ],
        ),
      ),
    ),
    );
  }

  // ─── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    final user = widget.currentUser;
    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid)),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryContainer.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: user.profilePicUrl.isNotEmpty
                  ? Image.network(
                      user.profilePicUrl,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(user),
                    )
                  : _avatarFallback(user),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Brand name + greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                user.fullName.split(' ').first,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Brand logo
        const Text(
          'STCU',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryContainer,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 14),

        // Notification bell with live unread count
        _PbNotifBell(userId: widget.currentUser.id),
      ],
    );
  }

  Widget _avatarFallback(UserModel user) {
    return Container(
      width: 42,
      height: 42,
      color: AppColors.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ─── Hero Balance Card ────────────────────────────────────────────────────
  Widget _buildHeroBalanceCard(
      BuildContext context, NumberFormat currencyFormat) {
    final user = widget.currentUser;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003ACC),
            Color(0xFF0052FF),
            Color(0xFF1A65FF),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.45),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 80,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL BALANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.65),
                        letterSpacing: 2.5,
                      ),
                    ),
                    Row(
                      children: [
                        _buildAccountStatusBadge(user),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(
                              () => _balanceVisible = !_balanceVisible),
                          child: Icon(
                            _balanceVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 18,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Balance
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _balanceVisible
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          key: const ValueKey('shown'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '\$',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withOpacity(0.75),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                _formatBalance(user.balance),
                                key: const ValueKey('balance'),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                  height: 1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('hidden'),
                          children: [
                            Text(
                              '••••••',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withOpacity(0.4),
                                letterSpacing: 6,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CHECKING',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Acct ${user.maskedAccount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Spending summary chips ─────────────────────────────
                _buildSpendingChipsRow(context),
                const SizedBox(height: 16),

                // CTA buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddMoneyScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: AppColors.primaryContainer, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Add Money',
                                style: TextStyle(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!user.canTransact) {
                            _showTransactionDisabledSnack(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SendMoneyScreen(
                                  senderUid: user.uid),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Send',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Insights chips ─────────────────────────────────────
                _buildInsightsChipsRow(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Spending chips ───────────────────────────────────────────────────────
  Widget _buildSpendingChipsRow(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return FutureBuilder<List<RecordModel>>(
      future: widget.authService
          .getTransactions(widget.currentUser.id, perPage: 200),
      builder: (context, snap) {
        double spent = 0;
        double received = 0;

        if (snap.hasData) {
          for (final record in snap.data!) {
            final tx = TransactionModel.fromRecord(record);
            if (tx.status == 'Failed') continue;
            final dt = tx.dateTime;
            if (dt == null || dt.isBefore(monthStart)) continue;
            if (tx.isCredit) {
              received += tx.amount;
            } else {
              spent += tx.amount;
            }
          }
        }

        final fmt = NumberFormat.compact(locale: 'en_US');

        return Row(
          children: [
            _buildSpendingChip(
              label: _balanceVisible
                  ? '↓ \$${fmt.format(spent)} spent'
                  : '↓ •••• spent',
              color: const Color(0xFFFF6B6B),
              bgColor: Colors.white.withOpacity(0.12),
            ),
            const SizedBox(width: 8),
            _buildSpendingChip(
              label: _balanceVisible
                  ? '↑ \$${fmt.format(received)} received'
                  : '↑ •••• received',
              color: const Color(0xFF4ADE80),
              bgColor: Colors.white.withOpacity(0.10),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpendingChip({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ─── Insights chips ───────────────────────────────────────────────────────
  Widget _buildInsightsChipsRow(BuildContext context) {
    final user = widget.currentUser;
    // Notifications unread count via PocketBase FutureBuilder
    return FutureBuilder<ResultList<RecordModel>>(
      future: PbService.instance.pb.collection('notifications').getList(
            page: 1,
            perPage: 1,
            filter: 'userId = "${user.id}" && isRead = false',
          ),
      builder: (context, notifSnap) {
        final unreadCount = notifSnap.data?.totalItems ?? 0;
        return Row(
          children: [
            _buildInsightChip(
              label: '🔔 ${unreadCount > 0 ? '$unreadCount alerts' : 'Alerts'}',
              bgColor: Colors.white.withOpacity(0.10),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NotificationsScreen(uid: user.id)),
              ),
            ),
            const SizedBox(width: 8),
            _buildInsightChip(
              label: '📊 Insights',
              bgColor: Colors.white.withOpacity(0.10),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => InsightsScreen(uid: user.id)),
              ),
            ),
            const SizedBox(width: 8),
            _buildInsightChip(
              label: '🏦 Account',
              bgColor: Colors.white.withOpacity(0.10),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AccountSummaryScreen(uid: user.id)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightChip({
    required String label,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: Colors.white.withOpacity(0.15), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _formatBalance(double balance) {
    final formatted = NumberFormat('#,##0.00').format(balance);
    return formatted;
  }

  Widget _buildAccountStatusBadge(UserModel user) {
    Color dotColor;
    String label;
    switch (user.accountStatus) {
      case 'active':
        dotColor = AppColors.success;
        label = 'Active';
        break;
      case 'suspended':
        dotColor = AppColors.error;
        label = 'Suspended';
        break;
      case 'pending':
        dotColor = AppColors.warning;
        label = 'Pending';
        break;
      default:
        dotColor = Colors.white.withOpacity(0.4);
        label = 'Closed';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Monthly Stats ────────────────────────────────────────────────────────
  Widget _buildMonthlyStatsCard(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return FutureBuilder<List<RecordModel>>(
      future: widget.authService
          .getTransactions(widget.currentUser.id, perPage: 200),
      builder: (context, snap) {
        double income = 0;
        double spent = 0;
        int txCount = 0;

        if (snap.hasData) {
          for (final record in snap.data!) {
            final tx = TransactionModel.fromRecord(record);
            if (tx.status == 'Failed') continue;
            final dt = tx.dateTime;
            if (dt == null || dt.isBefore(monthStart)) continue;
            txCount++;
            if (tx.isCredit) {
              income += tx.amount;
            } else {
              spent += tx.amount;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'THIS MONTH',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '$txCount transactions',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant.withOpacity(0.45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatPill(
                      label: 'Income',
                      value: currencyFormat.format(income),
                      icon: Icons.south_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatPill(
                      label: 'Spent',
                      value: currencyFormat.format(spent),
                      icon: Icons.north_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatPill(
                      label: 'Net',
                      value: '${income >= spent ? '+' : '-'}${currencyFormat.format((income - spent).abs())}',
                      icon: Icons.swap_vert_rounded,
                      color: income >= spent
                          ? AppColors.primaryContainer
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.85),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions Bento ──────────────────────────────────────────────────
  Widget _buildQuickActionsSection(BuildContext context) {
    final user = widget.currentUser;
    final actions = <_ActionData>[
      _ActionData(
        icon: Icons.call_received_rounded,
        label: 'Request',
        color: AppColors.success,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => RequestMoneyScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scan & Pay',
        color: AppColors.primary,
        onTap: () => _showQrBottomSheet(context, user),
      ),
      _ActionData(
        icon: Icons.receipt_rounded,
        label: 'Pay Bills',
        color: AppColors.error,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => BillPayScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.savings_rounded,
        label: 'Savings',
        color: AppColors.success,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SavingsGoalsScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.currency_exchange_rounded,
        label: 'Convert',
        color: AppColors.warning,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CurrencyConverterScreen())),
      ),
      _ActionData(
        icon: Icons.insights_rounded,
        label: 'Insights',
        color: AppColors.primary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => InsightsScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.shield_rounded,
        label: 'Security',
        color: AppColors.success,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SecurityHubScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.verified_user_rounded,
        label: 'KYC',
        color: AppColors.warning,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => IdentityVerificationScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.account_balance_rounded,
        label: 'Loans',
        color: AppColors.warning,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => LoanScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.card_giftcard_rounded,
        label: 'Referral',
        color: AppColors.success,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ReferralScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.trending_up_rounded,
        label: 'Invest',
        color: AppColors.primary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => InvestmentsScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.location_on_rounded,
        label: 'ATMs',
        color: AppColors.error,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AtmLocatorScreen())),
      ),
      _ActionData(
        icon: Icons.description_rounded,
        label: 'Statement',
        color: AppColors.primaryContainer,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => AccountSummaryScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.schedule_rounded,
        label: 'Scheduled',
        color: AppColors.primaryContainer,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => ScheduledPaymentsScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.currency_bitcoin,
        label: 'Crypto',
        color: const Color(0xFFFF9500),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CryptoScreen())),
      ),
      _ActionData(
        icon: Icons.group_rounded,
        label: 'Split',
        color: AppColors.secondary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => SplitBillScreen(uid: user.uid))),
      ),
      _ActionData(
        icon: Icons.newspaper_rounded,
        label: 'News',
        color: AppColors.primary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FinancialNewsScreen())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) =>
              _buildActionTile(actions[index]),
        ),
      ],
    );
  }

  Widget _buildActionTile(_ActionData data) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.color.withOpacity(0.22),
                    data.color.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: data.color.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(height: 9),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Recent Activity ──────────────────────────────────────────────────────
  Widget _buildRecentActivitySection(
      BuildContext context, NumberFormat currencyFormat) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        TransactionsScreen(uid: widget.currentUser.uid)),
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<RecordModel>>(
          future: widget.authService
              .getTransactions(widget.currentUser.id, perPage: 5),
          builder: (context, txSnapshot) {
            if (txSnapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryContainer,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }

            if (!txSnapshot.hasData || txSnapshot.data!.isEmpty) {
              return _buildEmptyTransactions();
            }

            final transactions = txSnapshot.data!
                .map((r) => TransactionModel.fromRecord(r))
                .toList();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: transactions
                    .asMap()
                    .entries
                    .map((e) => _buildTransactionRow(
                        context, e.value, currencyFormat,
                        isLast: e.key == transactions.length - 1))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: AppColors.onSurfaceVariant.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your activity will appear here',
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category icon / color helper ────────────────────────────────────────
  static ({IconData icon, Color color}) _txCategory(TransactionModel tx) {
    if (tx.status == 'Failed') return (icon: Icons.error_outline_rounded, color: AppColors.error);
    final d = tx.description.toLowerCase();
    if (d.contains('bill') || d.contains('utility') || d.contains('electric') || d.contains('water'))
      return (icon: Icons.receipt_rounded, color: const Color(0xFFE67E22));
    if (d.contains('food') || d.contains('restaurant') || d.contains('coffee') || d.contains('eat'))
      return (icon: Icons.restaurant_rounded, color: const Color(0xFFE74C3C));
    if (d.contains('shop') || d.contains('store') || d.contains('amazon') || d.contains('purchase'))
      return (icon: Icons.shopping_bag_rounded, color: const Color(0xFF9B59B6));
    if (d.contains('transfer from') || d.contains('received') || tx.isCredit)
      return (icon: Icons.call_received_rounded, color: AppColors.success);
    if (d.contains('transfer to') || d.contains('send'))
      return (icon: Icons.send_rounded, color: AppColors.primaryContainer);
    if (d.contains('saving') || d.contains('invest'))
      return (icon: Icons.savings_rounded, color: const Color(0xFF1ABC9C));
    if (d.contains('salary') || d.contains('payroll') || d.contains('income'))
      return (icon: Icons.account_balance_wallet_rounded, color: AppColors.success);
    return tx.isCredit
        ? (icon: Icons.south_rounded, color: AppColors.success)
        : (icon: Icons.north_rounded, color: AppColors.primaryContainer);
  }

  Widget _buildTransactionRow(BuildContext context, TransactionModel tx,
      NumberFormat currencyFormat,
      {bool isLast = false}) {
    final isCredit = tx.isCredit;
    final isFailed = tx.status == 'Failed';
    final category = _txCategory(tx);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: tx)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(20))
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 14),
            // Description + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.onSurface,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        tx.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isFailed
                              ? AppColors.error
                              : AppColors.onSurfaceVariant.withOpacity(0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isFailed
                              ? AppColors.error
                              : tx.status == 'Pending'
                                  ? AppColors.warning
                                  : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (tx.dateTime != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d, h:mm a').format(tx.dateTime!),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : isFailed ? '' : '-'}${currencyFormat.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isFailed
                        ? AppColors.onSurfaceVariant.withOpacity(0.35)
                        : isCredit
                            ? AppColors.success
                            : AppColors.onSurface,
                    decoration: isFailed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (tx.relatedUserName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tx.relatedUserName!.split(' ').first,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.onSurfaceVariant.withOpacity(0.45),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Send / Recent Recipients ──────────────────────────────────────
  Widget _buildQuickSendSection(BuildContext context) {
    final user = widget.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Send',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (!user.canTransact) {
                  _showTransactionDisabledSnack(context);
                  return;
                }
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SendMoneyScreen(senderUid: user.uid)));
              },
              child: Text(
                'Send New',
                style: TextStyle(
                  color: AppColors.primaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<RecordModel>>(
          future: widget.authService.getTransactions(user.id, perPage: 20),
          builder: (context, snap) {
            // Extract unique recent recipients from debit transactions
            final recipients = <String, String>{};
            if (snap.hasData) {
              for (final record in snap.data!) {
                final tx = TransactionModel.fromRecord(record);
                if (tx.isDebit && tx.isSuccess && tx.relatedUserName != null && tx.relatedUserId != null) {
                  recipients.putIfAbsent(tx.relatedUserId!, () => tx.relatedUserName!);
                  if (recipients.length >= 5) break;
                }
              }
            }

            if (recipients.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: AppColors.primaryContainer, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Send to someone new',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface)),
                          Text('Your recent contacts will appear here',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant.withOpacity(0.5))),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!user.canTransact) {
                          _showTransactionDisabledSnack(context);
                          return;
                        }
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => SendMoneyScreen(senderUid: user.uid)));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.primaryContainer, AppColors.primary]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Send',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recipients.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  if (i == recipients.length) {
                    // "+" add new button
                    return GestureDetector(
                      onTap: () {
                        if (!user.canTransact) {
                          _showTransactionDisabledSnack(context);
                          return;
                        }
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => SendMoneyScreen(senderUid: user.uid)));
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryContainer.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(Icons.add_rounded,
                                color: AppColors.primaryContainer, size: 22),
                          ),
                          const SizedBox(height: 6),
                          const Text('New', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }
                  final entry = recipients.entries.elementAt(i);
                  final name = entry.value;
                  final initials = name.trim().split(' ')
                      .take(2)
                      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                      .join();
                  final colors = [
                    AppColors.primaryContainer, AppColors.success,
                    AppColors.error, const Color(0xFF9C27B0), AppColors.warning
                  ];
                  final color = colors[i % colors.length];
                  return GestureDetector(
                    onTap: () {
                      if (!user.canTransact) {
                        _showTransactionDisabledSnack(context);
                        return;
                      }
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => SendMoneyScreen(senderUid: user.uid)));
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                          ),
                          child: Center(
                            child: Text(initials,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: color)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 56,
                          child: Text(
                            name.split(' ').first,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Account Details Card ─────────────────────────────────────────────────
  Widget _buildAccountDetailsCard(BuildContext context) {
    final user = widget.currentUser;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryContainer.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Details',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PERSONAL CHECKING',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Account Number', user.accountNumberDisplay),
          const SizedBox(height: 10),
          _buildDetailRow('Routing Number', UserModel.routingNumber),
          const SizedBox(height: 10),
          _buildDetailRow('Account Holder', user.fullName),
          const SizedBox(height: 10),
          _buildDetailRow('Bank', 'STCU Digital Banking'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant.withOpacity(0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$label copied'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          },
          child: Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.copy_rounded,
                  size: 13,
                  color: AppColors.onSurfaceVariant.withOpacity(0.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── QR Bottom Sheet ──────────────────────────────────────────────────────
  void _showQrBottomSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'QR Payment',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Generate or scan a payment code',
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => QrGenerateScreen(
                                  uid: user.uid,
                                  userName: user.fullName)));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.qr_code_rounded,
                                color: AppColors.primaryContainer, size: 26),
                          ),
                          const SizedBox(height: 12),
                          const Text('My QR Code',
                              style: TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('Receive payment',
                              style: TextStyle(
                                  color: AppColors.onSurfaceVariant
                                      .withOpacity(0.5),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  QrScanScreen(senderUid: user.uid)));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded,
                                color: AppColors.primary, size: 26),
                          ),
                          const SizedBox(height: 12),
                          const Text('Scan to Pay',
                              style: TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('Send payment',
                              style: TextStyle(
                                  color: AppColors.onSurfaceVariant
                                      .withOpacity(0.5),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDisabledSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Transactions are currently disabled on your account.'),
        backgroundColor: AppColors.errorContainer,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action data class
// ─────────────────────────────────────────────────────────────────────────────
class _ActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// What's New Banner (v1.1) — dismissible, shown once via SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────
class _WhatsNewBanner extends StatefulWidget {
  final VoidCallback onDismiss;

  const _WhatsNewBanner({required this.onDismiss});

  @override
  State<_WhatsNewBanner> createState() => _WhatsNewBannerState();
}

class _WhatsNewBannerState extends State<_WhatsNewBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2A6C), Color(0xFF2B5876)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A2A6C).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {}, // reserved for future navigation
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✨ What\'s New in v1.1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: const [
                              _WhatsNewChip(label: 'Loans & Investments'),
                              _WhatsNewChip(label: 'Crypto Portfolio'),
                              _WhatsNewChip(label: 'Scheduled Payments'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Dismiss button
                    GestureDetector(
                      onTap: _handleDismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PocketBase notification bell — fetches unread count via FutureBuilder
// ─────────────────────────────────────────────────────────────────────────────
class _PbNotifBell extends StatelessWidget {
  final String userId;
  const _PbNotifBell({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResultList<RecordModel>>(
      future: PbService.instance.pb.collection('notifications').getList(
            page: 1,
            perPage: 1,
            filter: 'userId = "$userId" && isRead = false',
          ),
      builder: (context, snap) {
        final unreadCount = snap.data?.totalItems ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationsScreen(uid: userId),
            ),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.onSurface.withOpacity(0.65),
                  size: 22,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.surfaceContainerHigh,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WhatsNewChip extends StatelessWidget {
  final String label;

  const _WhatsNewChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
