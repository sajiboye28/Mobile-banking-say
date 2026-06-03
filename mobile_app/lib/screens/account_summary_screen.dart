import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:real_banking/models/transaction_model.dart';
import 'package:real_banking/models/user_model.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Period enum
// ─────────────────────────────────────────────────────────────────────────────
enum _StatementPeriod {
  thisMonth('This Month'),
  last3Months('Last 3 Months'),
  last6Months('Last 6 Months'),
  allTime('All Time');

  final String label;
  const _StatementPeriod(this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Summary Screen
// ─────────────────────────────────────────────────────────────────────────────
class AccountSummaryScreen extends StatefulWidget {
  final String uid;
  const AccountSummaryScreen({super.key, required this.uid});

  @override
  State<AccountSummaryScreen> createState() =>
      _AccountSummaryScreenState();
}

class _AccountSummaryScreenState extends State<AccountSummaryScreen> {
  _StatementPeriod _period = _StatementPeriod.thisMonth;

  final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // ── Period filtering ──────────────────────────────────────────────────────
  DateTime? get _periodStart {
    final now = DateTime.now();
    switch (_period) {
      case _StatementPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case _StatementPeriod.last3Months:
        return DateTime(now.year, now.month - 2, 1);
      case _StatementPeriod.last6Months:
        return DateTime(now.year, now.month - 5, 1);
      case _StatementPeriod.allTime:
        return null;
    }
  }

  List<TransactionModel> _filterByPeriod(List<TransactionModel> all) {
    final start = _periodStart;
    if (start == null) return all;
    return all.where((tx) {
      final dt = tx.dateTime;
      if (dt == null) return false;
      return dt.isAfter(start.subtract(const Duration(seconds: 1)));
    }).toList();
  }

  // ── Snackbars ─────────────────────────────────────────────────────────────
  void _showSnack(String msg, {IconData? icon, Color? iconColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.success, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnack(
      '$label copied to clipboard',
      icon: Icons.copy_rounded,
      iconColor: AppColors.primaryContainer,
    );
  }

  void _exportStatement(
    UserModel? user,
    List<TransactionModel> transactions,
    double credits,
    double debits,
  ) {
    final buf = StringBuffer();
    buf.writeln('==============================================');
    buf.writeln('       STCU — STATEMENT');
    buf.writeln('==============================================');
    buf.writeln('Account Holder : ${user?.fullName ?? '—'}');
    buf.writeln(
        'Account Number : ${user?.accountNumber ?? '—'}');
    buf.writeln('Routing Number : ${UserModel.routingNumber}');
    buf.writeln('Account Type   : CHECKING');
    buf.writeln('Period         : ${_period.label}');
    buf.writeln(
        'Generated      : ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buf.writeln('----------------------------------------------');
    buf.writeln(
        'Current Balance  : ${_currency.format(user?.balance ?? 0)}');
    buf.writeln('Total Credits    : ${_currency.format(credits)}');
    buf.writeln('Total Debits     : ${_currency.format(debits)}');
    buf.writeln(
        'Net Change       : ${_currency.format(credits - debits)}');
    buf.writeln('==============================================');
    buf.writeln('TRANSACTIONS');
    buf.writeln('----------------------------------------------');
    for (final tx in transactions) {
      final date = tx.dateTime != null
          ? DateFormat('MMM d').format(tx.dateTime!)
          : '—';
      final sign = tx.isCredit ? '+' : '-';
      buf.writeln(
          '$date  ${tx.description.padRight(28)}  $sign${_currency.format(tx.amount)}');
    }
    buf.writeln('==============================================');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    _showSnack(
      'Statement exported to PDF (demo) — copied to clipboard',
      icon: Icons.picture_as_pdf_rounded,
      iconColor: AppColors.error,
    );
  }

  // ── Transaction icon ──────────────────────────────────────────────────────
  IconData _txIcon(String type) {
    switch (type.toLowerCase()) {
      case 'credit':
        return Icons.arrow_downward_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'deposit':
        return Icons.account_balance_rounded;
      default:
        return Icons.arrow_upward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pb = PbService.instance.pb;
    return FutureBuilder<_AccountData>(
      future: Future.wait([
        pb.collection('users').getOne(widget.uid),
        pb.collection('transactions').getFullList(
          filter: 'userId="${widget.uid}"',
          sort: '-created',
        ),
      ]).then((results) => _AccountData(
            user: results[0] as RecordModel,
            txRecords: results[1] as List<RecordModel>,
          )),
      builder: (context, snap) {
        UserModel? user;
        List<RecordModel> txRecords = [];
        if (snap.hasData) {
          user = UserModel.fromRecord(snap.data!.user);
          txRecords = snap.data!.txRecords;
        }
        final balance = user?.balance ?? 0.0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            title: const Text(
              'Account Statement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              // Share / download icon in app bar
              IconButton(
                onPressed: () {
                  // Triggers the export with current data (simplified here)
                  _showSnack(
                    'Statement exported to PDF (demo)',
                    icon: Icons.picture_as_pdf_rounded,
                    iconColor: AppColors.error,
                  );
                },
                icon: const Icon(Icons.share_rounded,
                    color: AppColors.onSurface, size: 22),
                tooltip: 'Export Statement',
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              // Loading state
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryContainer),
                );
              }

              // Parse all transactions, sort client-side
              final allTxs = txRecords
                  .map((d) => TransactionModel.fromRecord(d))
                  .toList()
                ..sort((a, b) {
                  final at = a.timestamp?.millisecondsSinceEpoch ?? 0;
                  final bt = b.timestamp?.millisecondsSinceEpoch ?? 0;
                  return bt.compareTo(at); // descending
                });

              // Apply period filter
              final transactions = _filterByPeriod(allTxs);

              final totalCredits = transactions
                  .where((t) => t.isCredit)
                  .fold<double>(0.0, (s, t) => s + t.amount);
              final totalDebits = transactions
                  .where((t) => t.isDebit)
                  .fold<double>(0.0, (s, t) => s + t.amount);
              final netChange = totalCredits - totalDebits;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Account header card ───────────────────────────
                    _AccountHeaderCard(
                      user: user,
                      balance: balance,
                      currency: _currency,
                    ),
                    const SizedBox(height: 20),

                    // ── Period selector ───────────────────────────────
                    _sectionLabel('STATEMENT PERIOD'),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _StatementPeriod.values
                            .map((p) => _PeriodChip(
                                  period: p,
                                  selected: _period == p,
                                  onTap: () =>
                                      setState(() => _period = p),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Summary cards ─────────────────────────────────
                    _sectionLabel('PERIOD SUMMARY'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Total Credits',
                            value: _currency.format(totalCredits),
                            icon: Icons.arrow_downward_rounded,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Total Debits',
                            value: _currency.format(totalDebits),
                            icon: Icons.arrow_upward_rounded,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Net Change',
                            value: _currency.format(netChange),
                            icon: netChange >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: netChange >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Account details ───────────────────────────────
                    _sectionLabel('ACCOUNT DETAILS'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _AccountDetailRow(
                            label: 'Account Holder',
                            value: user?.fullName ?? '—',
                            onCopy: null,
                          ),
                          _detailDivider(),
                          _AccountDetailRow(
                            label: 'Account Number',
                            value: user?.accountNumber != null && user!.accountNumber!.length >= 4
                                ? '•••• •••• ${user.accountNumber!.substring(user.accountNumber!.length - 4)}'
                                : '—',
                            fullValue: user?.accountNumber,
                            onCopy: () => _copyToClipboard(
                              user?.accountNumber ?? '',
                              'Account number',
                            ),
                          ),
                          _detailDivider(),
                          _AccountDetailRow(
                            label: 'Routing Number',
                            value: UserModel.routingNumber,
                            onCopy: () => _copyToClipboard(
                              UserModel.routingNumber,
                              'Routing number',
                            ),
                          ),
                          _detailDivider(),
                          const _AccountDetailRow(
                            label: 'Account Type',
                            value: 'Checking',
                            onCopy: null,
                          ),
                          _detailDivider(),
                          _AccountDetailRow(
                            label: 'Account Status',
                            value: user?.accountStatus.toUpperCase() ??
                                'ACTIVE',
                            onCopy: null,
                            statusColor: user?.isActive == true
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Transaction list ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel('TRANSACTIONS'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${transactions.length} total',
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Empty state
                    if (transactions.isEmpty)
                      _buildEmptyTransactions()
                    else
                      ...transactions.map(
                        (tx) => _TransactionRow(
                            tx: tx,
                            currency: _currency,
                            iconForType: _txIcon),
                      ),

                    const SizedBox(height: 24),

                    // ── Export button ─────────────────────────────────
                    GestureDetector(
                      onTap: () => _exportStatement(
                          user, transactions, totalCredits, totalDebits),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.electricGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Export Statement (PDF)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Download / share secondary button ─────────────
                    GestureDetector(
                      onTap: () => _showSnack(
                        'Downloading statement…',
                        icon: Icons.download_rounded,
                        iconColor: AppColors.primaryContainer,
                      ),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                AppColors.outlineVariant.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_rounded,
                                color: AppColors.onSurfaceVariant,
                                size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Download Statement',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _detailDivider() => Divider(
        height: 20,
        thickness: 1,
        color: AppColors.outlineVariant.withOpacity(0.1),
      );

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.onSurfaceVariant, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            'No transactions',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No activity found for ${_period.label.toLowerCase()}.',
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account header card
// ─────────────────────────────────────────────────────────────────────────────
class _AccountHeaderCard extends StatelessWidget {
  final UserModel? user;
  final double balance;
  final NumberFormat currency;

  const _AccountHeaderCard({
    required this.user,
    required this.balance,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer.withOpacity(0.9),
            AppColors.primary.withOpacity(0.5),
            AppColors.secondaryContainer.withOpacity(0.4),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account type + bank icon row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CHECKING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.account_balance_rounded,
                  color: Colors.white54, size: 20),
              const SizedBox(width: 6),
              const Text(
                'STCU',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Account holder name
          Text(
            user?.fullName ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Masked account number
          Text(
            user?.accountNumber != null && user!.accountNumber!.length >= 4
                ? '•••• •••• ${user!.accountNumber!.substring(user!.accountNumber!.length - 4)}'
                : '•••• •••• ——',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),

          // Balance
          const Text(
            'Current Balance',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            currency.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available: ${currency.format(balance)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period chip
// ─────────────────────────────────────────────────────────────────────────────
class _PeriodChip extends StatelessWidget {
  final _StatementPeriod period;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.period,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.primaryContainer
                : AppColors.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          period.label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card (credits / debits / net)
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account detail row
// ─────────────────────────────────────────────────────────────────────────────
class _AccountDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? fullValue;
  final VoidCallback? onCopy;
  final Color? statusColor;

  const _AccountDetailRow({
    required this.label,
    required this.value,
    this.fullValue,
    required this.onCopy,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: statusColor ?? AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryContainer.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded,
                      color: AppColors.primaryContainer, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Copy',
                    style: TextStyle(
                      color: AppColors.primaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction row
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  final TransactionModel tx;
  final NumberFormat currency;
  final IconData Function(String type) iconForType;

  const _TransactionRow({
    required this.tx,
    required this.currency,
    required this.iconForType,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    final color = isCredit ? AppColors.success : AppColors.error;
    final icon = iconForType(tx.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),

          // Description + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : tx.type,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tx.dateTime != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM d, yyyy · h:mm a')
                        .format(tx.dateTime!),
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (tx.relatedUserName != null &&
                    tx.relatedUserName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 11,
                          color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        tx.relatedUserName!,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${currency.format(tx.amount)}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tx.isSuccess
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tx.status,
                  style: TextStyle(
                    color: tx.isSuccess
                        ? AppColors.success
                        : AppColors.warning,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountData {
  final RecordModel user;
  final List<RecordModel> txRecords;
  _AccountData({required this.user, required this.txRecords});
}
