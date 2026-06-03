import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/models/transaction_model.dart';
import 'package:real_banking/screens/transaction_detail_screen.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/services/export_service.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:intl/intl.dart';

// Sort modes cycle order
enum _SortMode { newestFirst, oldestFirst, highestAmount, lowestAmount }

extension _SortModeLabel on _SortMode {
  String get label {
    switch (this) {
      case _SortMode.newestFirst:
        return 'Newest First';
      case _SortMode.oldestFirst:
        return 'Oldest First';
      case _SortMode.highestAmount:
        return 'Highest Amount';
      case _SortMode.lowestAmount:
        return 'Lowest Amount';
    }
  }

  IconData get icon {
    switch (this) {
      case _SortMode.newestFirst:
        return Icons.arrow_downward_rounded;
      case _SortMode.oldestFirst:
        return Icons.arrow_upward_rounded;
      case _SortMode.highestAmount:
        return Icons.trending_up_rounded;
      case _SortMode.lowestAmount:
        return Icons.trending_down_rounded;
    }
  }

  _SortMode get next {
    final values = _SortMode.values;
    return values[(index + 1) % values.length];
  }
}

class TransactionsScreen extends StatefulWidget {
  final String uid;

  const TransactionsScreen({super.key, required this.uid});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  // ── Filter / search state ──────────────────────────────────────────────────
  String _filter = 'All';
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  // ── Date range state ───────────────────────────────────────────────────────
  DateTimeRange? _dateRange;

  // ── Sort state ─────────────────────────────────────────────────────────────
  _SortMode _sortMode = _SortMode.newestFirst;

  // ── Formatting ─────────────────────────────────────────────────────────────
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Date grouping ──────────────────────────────────────────────────────────
  String _getDateSection(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);
    if (txDate == today) return 'Today';
    if (txDate == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  // ── Filter + sort + search pipeline ───────────────────────────────────────
  List<TransactionModel> _applyFilter(List<TransactionModel> transactions) {
    var list = transactions;

    // Type filter
    if (_filter == 'Credits') {
      list = list.where((t) => t.isCredit && t.isSuccess).toList();
    } else if (_filter == 'Debits') {
      list = list.where((t) => t.isDebit && t.isSuccess).toList();
    } else if (_filter == 'Failed') {
      list = list.where((t) => t.status == 'Failed').toList();
    }

    // Date range filter
    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      list = list.where((t) {
        final dt = t.dateTime;
        if (dt == null) return false;
        return dt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
            dt.isBefore(end.add(const Duration(milliseconds: 1)));
      }).toList();
    }

    // Search filter — description, relatedUserName, or amount
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) {
        final matchDesc = t.description.toLowerCase().contains(q);
        final matchUser =
            t.relatedUserName?.toLowerCase().contains(q) ?? false;
        final matchAmount =
            t.amount.toStringAsFixed(2).contains(q);
        return matchDesc || matchUser || matchAmount;
      }).toList();
    }

    // Sort
    switch (_sortMode) {
      case _SortMode.newestFirst:
        list.sort((a, b) {
          final ta = a.dateTime?.millisecondsSinceEpoch ?? 0;
          final tb = b.dateTime?.millisecondsSinceEpoch ?? 0;
          return tb.compareTo(ta);
        });
        break;
      case _SortMode.oldestFirst:
        list.sort((a, b) {
          final ta = a.dateTime?.millisecondsSinceEpoch ?? 0;
          final tb = b.dateTime?.millisecondsSinceEpoch ?? 0;
          return ta.compareTo(tb);
        });
        break;
      case _SortMode.highestAmount:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _SortMode.lowestAmount:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return list;
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  // ── Date range picker ──────────────────────────────────────────────────────
  Future<void> _openDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryContainer,
              onPrimary: Colors.white,
              surface: AppColors.surfaceContainerLow,
              onSurface: AppColors.onSurface,
            ),
            dialogBackgroundColor: AppColors.surfaceContainerLow,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  // ── Export ─────────────────────────────────────────────────────────────────
  void _exportTransactions(List<TransactionModel> transactions) {
    final maps = transactions.map((tx) => {
          'date': tx.dateTime,
          'type': tx.type,
          'description': tx.description,
          'amount': tx.amount,
          'status': tx.status,
          'transactionId': tx.transactionId,
        }).toList();

    final csv = ExportService.generateCsv(maps);
    Clipboard.setData(ClipboardData(text: csv));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Text(
              'Statement copied to clipboard',
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FutureBuilder<List<RecordModel>>(
            future: PbService.instance.pb
                .collection('transactions')
                .getFullList(filter: 'userId="${widget.uid}"'),
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;
              final all = snapshot.hasData
                  ? snapshot.data!
                      .map((d) => TransactionModel.fromRecord(d))
                      .toList()
                  : <TransactionModel>[];
              final filtered = _applyFilter(all);

              return Column(
                children: [
                  // Header with export button
                  _buildHeader(filtered),
                  // Animated search bar (always rendered in tree)
                  _buildSearchBar(),
                  // Date range + sort controls
                  _buildControlsRow(),
                  // Filter chips (All / Credits / Debits / Failed)
                  _buildFilterRow(),
                  // Summary chips
                  if (!isLoading) _buildSummaryChips(filtered),
                  // Transaction list
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryContainer,
                              strokeWidth: 2.5,
                            ),
                          )
                        : _buildTransactionList(all, filtered),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(List<TransactionModel> filtered) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.onSurface,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Ledger',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Real-time synchronisation',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Sort button
          GestureDetector(
            onTap: () => setState(() => _sortMode = _sortMode.next),
            child: Tooltip(
              message: _sortMode.label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _sortMode != _SortMode.newestFirst
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _sortMode.icon,
                  color: _sortMode != _SortMode.newestFirst
                      ? Colors.white
                      : AppColors.onSurfaceVariant,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Export button
          GestureDetector(
            onTap: () => _exportTransactions(filtered),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.upload_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Search toggle
          GestureDetector(
            onTap: _toggleSearch,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _showSearch
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _showSearch
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: _showSearch
                    ? Colors.white
                    : AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      height: _showSearch ? 60 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _showSearch ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText:
                    'Search by description, name, or amount…',
                hintStyle: TextStyle(
                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim()),
            ),
          ),
        ),
      ),
    );
  }

  // ── Controls Row (date range + sort label) ─────────────────────────────────

  Widget _buildControlsRow() {
    final hasDateFilter = _dateRange != null;
    final df = DateFormat('MMM d');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Date range chip
          GestureDetector(
            onTap: _openDateRangePicker,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasDateFilter
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: 14,
                    color: hasDateFilter
                        ? Colors.white
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasDateFilter
                        ? '${df.format(_dateRange!.start)} – ${df.format(_dateRange!.end)}'
                        : 'Filter by date',
                    style: TextStyle(
                      color: hasDateFilter
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasDateFilter) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _dateRange = null),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort mode chip (tap cycles)
          GestureDetector(
            onTap: () => setState(() => _sortMode = _sortMode.next),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_sortMode.icon,
                      size: 14,
                      color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    _sortMode.label,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
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
  }

  // ── Filter Row (All / Credits / Debits / Failed) ───────────────────────────

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Credits', 'Debits', 'Failed'].map((f) {
            final isSelected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.onPrimaryFixed
                          : AppColors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Summary Chips ──────────────────────────────────────────────────────────

  Widget _buildSummaryChips(List<TransactionModel> filtered) {
    double totalAmount = 0;
    for (final tx in filtered) {
      if (tx.isSuccess) totalAmount += tx.amount;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_rounded,
                    size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  '${filtered.length} transaction${filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_money_rounded,
                    size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  'Total: ${_currencyFormat.format(totalAmount)}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction List ───────────────────────────────────────────────────────

  Widget _buildTransactionList(
      List<TransactionModel> all, List<TransactionModel> filtered) {
    if (all.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No transactions yet',
        subtitle: 'Your ledger is clean',
      );
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: _searchQuery.isNotEmpty
            ? Icons.manage_search_rounded
            : Icons.filter_list_off_rounded,
        title: _searchQuery.isNotEmpty
            ? 'No results for "$_searchQuery"'
            : 'No ${_filter.toLowerCase()} found',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different keyword'
            : 'Try a different filter',
      );
    }

    // Group by date section
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in filtered) {
      final section = tx.dateTime != null
          ? _getDateSection(tx.dateTime!)
          : 'Processing';
      grouped.putIfAbsent(section, () => []).add(tx);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: grouped.keys.length,
      itemBuilder: (ctx, si) {
        final section = grouped.keys.elementAt(si);
        final txs = grouped[section]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Text(
                section.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant.withOpacity(0.55),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: txs
                    .asMap()
                    .entries
                    .map((e) => _buildTxRow(
                          ctx,
                          e.value,
                          isFirst: e.key == 0,
                          isLast: e.key == txs.length - 1,
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Transaction Row (with swipe-to-copy) ───────────────────────────────────

  static ({IconData icon, Color color}) _txCategory(
      TransactionModel tx) {
    if (tx.status == 'Failed') {
      return (
        icon: Icons.error_outline_rounded,
        color: AppColors.error
      );
    }
    final d = tx.description.toLowerCase();
    if (d.contains('bill') ||
        d.contains('utility') ||
        d.contains('electric') ||
        d.contains('water')) {
      return (
        icon: Icons.receipt_rounded,
        color: const Color(0xFFE67E22)
      );
    }
    if (d.contains('food') ||
        d.contains('restaurant') ||
        d.contains('coffee') ||
        d.contains('eat')) {
      return (
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFE74C3C)
      );
    }
    if (d.contains('shop') ||
        d.contains('store') ||
        d.contains('amazon')) {
      return (
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF9B59B6)
      );
    }
    if (d.contains('transfer from') ||
        d.contains('received') ||
        tx.isCredit) {
      return (
        icon: Icons.call_received_rounded,
        color: AppColors.success
      );
    }
    if (d.contains('transfer to') || d.contains('send')) {
      return (
        icon: Icons.send_rounded,
        color: AppColors.primaryContainer
      );
    }
    if (d.contains('saving') || d.contains('invest')) {
      return (
        icon: Icons.savings_rounded,
        color: const Color(0xFF1ABC9C)
      );
    }
    if (d.contains('salary') ||
        d.contains('payroll') ||
        d.contains('income')) {
      return (
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success
      );
    }
    return tx.isCredit
        ? (icon: Icons.south_rounded, color: AppColors.success)
        : (icon: Icons.north_rounded, color: AppColors.primaryContainer);
  }

  Widget _buildTxRow(BuildContext context, TransactionModel tx,
      {bool isFirst = false, bool isLast = false}) {
    final isCredit = tx.isCredit;
    final isFailed = tx.status == 'Failed';
    final isPending = tx.status == 'Pending';
    final category = _txCategory(tx);

    Color statusDotColor;
    if (isFailed) {
      statusDotColor = AppColors.error;
    } else if (isPending) {
      statusDotColor = AppColors.warning;
    } else {
      statusDotColor = AppColors.success;
    }

    // Right-swipe to copy transaction ID
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detect a rightward swipe (positive velocity)
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300) {
          Clipboard.setData(
              ClipboardData(text: tx.transactionId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.copy_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'ID copied: ${tx.transactionId}',
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.surfaceContainerHigh,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                TransactionDetailScreen(transaction: tx)),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(20) : Radius.zero,
            bottom:
                isLast ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(category.icon,
                  color: category.color, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        tx.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isFailed
                              ? AppColors.error
                              : AppColors.onSurfaceVariant
                                  .withOpacity(0.55),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: statusDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (tx.relatedUserName != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${isCredit ? 'from' : 'to'} ${tx.relatedUserName}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant
                                  .withOpacity(0.45),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tx.dateTime != null)
                    Text(
                      DateFormat('h:mm a').format(tx.dateTime!),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant
                            .withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),

            // Amount + swipe hint
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : isFailed ? '' : '-'}${_currencyFormat.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isFailed
                        ? AppColors.onSurfaceVariant
                            .withOpacity(0.3)
                        : isCredit
                            ? AppColors.success
                            : AppColors.onSurface,
                    decoration: isFailed
                        ? TextDecoration.lineThrough
                        : null,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                // Subtle swipe hint icon
                Icon(
                  Icons.swipe_right_alt_rounded,
                  size: 12,
                  color: AppColors.onSurfaceVariant.withOpacity(0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 42,
                color: AppColors.onSurfaceVariant.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}
