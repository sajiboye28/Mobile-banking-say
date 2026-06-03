import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:real_banking/models/transaction_model.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class InsightsScreen extends StatefulWidget {
  final String uid;

  const InsightsScreen({super.key, required this.uid});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _bgSecondary = AppColors.surfaceContainerLow;
  static const Color _blue = AppColors.primaryContainer;
  static const Color _green = AppColors.success;
  static const Color _red = AppColors.error;

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  String _selectedPeriod = 'Last 30 Days';
  final List<String> _periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'All Time',
  ];

  // ── Extended category system ───────────────────────────────────────────────
  static const Map<String, Color> _categoryColors = {
    'Food & Dining': Color(0xFFE74C3C),
    'Shopping': AppColors.warning,
    'Transport': Color(0xFF3498DB),
    'Bills & Utilities': AppColors.secondary,
    'Entertainment': Color(0xFF9B59B6),
    'Health': Color(0xFF1ABC9C),
    'Transfer': AppColors.primaryContainer,
    'Other': AppColors.outline,
  };

  static const Map<String, IconData> _categoryIcons = {
    'Food & Dining': Icons.restaurant_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Transport': Icons.directions_car_rounded,
    'Bills & Utilities': Icons.receipt_long_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.local_hospital_rounded,
    'Transfer': Icons.swap_horiz_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  // Hardcoded monthly budgets
  static const Map<String, double> _budgets = {
    'Food & Dining': 500.0,
    'Shopping': 300.0,
    'Entertainment': 100.0,
    'Transport': 200.0,
  };

  // Hardcoded investment portfolio value
  static const double _investmentValue = 12450.0;

  // ── Period helpers ─────────────────────────────────────────────────────────

  DateTime _getPeriodStart() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 30 Days':
        return now.subtract(const Duration(days: 30));
      case 'Last 90 Days':
        return now.subtract(const Duration(days: 90));
      default:
        return DateTime(2000);
    }
  }

  // ── Category mapping ───────────────────────────────────────────────────────

  String _categorizeTransaction(TransactionModel tx) {
    final desc = tx.description.toLowerCase();

    // Food & Dining
    if (desc.contains('food') ||
        desc.contains('restaurant') ||
        desc.contains('cafe') ||
        desc.contains('coffee') ||
        desc.contains('grocery') ||
        desc.contains('eat') ||
        desc.contains('lunch') ||
        desc.contains('dinner') ||
        desc.contains('breakfast') ||
        desc.contains('pizza') ||
        desc.contains('burger') ||
        desc.contains('mcdonald') ||
        desc.contains('starbucks') ||
        desc.contains('doordash') ||
        desc.contains('grubhub') ||
        desc.contains('ubereats')) {
      return 'Food & Dining';
    }

    // Transport
    if (desc.contains('transport') ||
        desc.contains('uber') ||
        desc.contains('lyft') ||
        desc.contains('gas') ||
        desc.contains('fuel') ||
        desc.contains('taxi') ||
        desc.contains('bus') ||
        desc.contains('train') ||
        desc.contains('metro') ||
        desc.contains('parking') ||
        desc.contains('toll')) {
      return 'Transport';
    }

    // Entertainment
    if (desc.contains('netflix') ||
        desc.contains('spotify') ||
        desc.contains('hulu') ||
        desc.contains('disney') ||
        desc.contains('movie') ||
        desc.contains('cinema') ||
        desc.contains('concert') ||
        desc.contains('game') ||
        desc.contains('entertainment') ||
        desc.contains('subscription') && !desc.contains('bill')) {
      return 'Entertainment';
    }

    // Bills & Utilities
    if (desc.contains('bill') ||
        desc.contains('utility') ||
        desc.contains('electric') ||
        desc.contains('water') ||
        desc.contains('internet') ||
        desc.contains('rent') ||
        desc.contains('mortgage') ||
        desc.contains('insurance') ||
        desc.contains('phone')) {
      return 'Bills & Utilities';
    }

    // Health
    if (desc.contains('health') ||
        desc.contains('doctor') ||
        desc.contains('hospital') ||
        desc.contains('pharmacy') ||
        desc.contains('medical') ||
        desc.contains('dental') ||
        desc.contains('gym') ||
        desc.contains('fitness')) {
      return 'Health';
    }

    // Shopping
    if (desc.contains('shop') ||
        desc.contains('store') ||
        desc.contains('amazon') ||
        desc.contains('purchase') ||
        desc.contains('buy') ||
        desc.contains('mall') ||
        desc.contains('target') ||
        desc.contains('walmart') ||
        desc.contains('ebay')) {
      return 'Shopping';
    }

    // Transfer
    if (desc.contains('transfer') ||
        desc.contains('sent') ||
        desc.contains('received') ||
        desc.contains('payment to') ||
        desc.contains('payment from')) {
      return 'Transfer';
    }

    return 'Other';
  }

  List<TransactionModel> _filterByPeriod(List<TransactionModel> transactions) {
    final start = _getPeriodStart();
    return transactions.where((tx) {
      final date = tx.dateTime;
      return date != null && date.isAfter(start);
    }).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<_InsightsData>(
          future: () async {
            final pb = PbService.instance.pb;
            final results = await Future.wait([
              pb.collection('users').getOne(widget.uid),
              pb.collection('transactions').getFullList(
                filter: 'userId="${widget.uid}"',
                sort: '-created',
              ),
            ]);
            return _InsightsData(
              user: results[0] as RecordModel,
              txRecords: results[1] as List<RecordModel>,
            );
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryContainer, strokeWidth: 2.5),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error loading data',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              );
            }

            final txDocs = snapshot.data?.txRecords ?? [];
            final allTransactions = txDocs
                .map((doc) => TransactionModel.fromRecord(doc))
                .toList()
              ..sort((a, b) {
                final aT = a.timestamp?.millisecondsSinceEpoch ?? 0;
                final bT = b.timestamp?.millisecondsSinceEpoch ?? 0;
                return bT.compareTo(aT);
              });
            final transactions = _filterByPeriod(allTransactions);

            final userData = snapshot.data?.user.data ?? <String, dynamic>{};
            final balance =
                (userData['balance'] ?? 0).toDouble();
            final savingsTotal =
                (userData['savingsTotal'] ?? 0).toDouble();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            // Task 1 #5 — Net Worth summary card
                            _buildNetWorthSummaryCard(
                                balance, savingsTotal),
                            const SizedBox(height: 24),
                            // Spending breakdown (PieChart) — Task 1 #2
                            _buildSpendingBreakdown(transactions),
                            const SizedBox(height: 24),
                            // Monthly spending trend (LineChart) — Task 1 #1
                            _buildMonthlySpendingTrend(allTransactions),
                            const SizedBox(height: 24),
                            // Income vs Expenses bar chart
                            _buildIncomeVsExpenses(allTransactions),
                            const SizedBox(height: 24),
                            // Top Merchants — Task 1 #3
                            _buildTopMerchants(transactions),
                            const SizedBox(height: 24),
                            // Budget Tracker — Task 1 #4
                            _buildBudgetTracker(transactions),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Insights',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: AppColors.surfaceContainerLow,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              items: _periods.map((period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPeriod = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Dark Card Container ────────────────────────────────────────────────────

  Widget _buildDarkCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ── Task 1 #5 — Net Worth Summary Card ─────────────────────────────────────

  Widget _buildNetWorthSummaryCard(double balance, double savingsTotal) {
    final totalNetWorth = balance + savingsTotal + _investmentValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryContainer, AppColors.background],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NET WORTH',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(totalNetWorth),
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Breakdown rows
          _buildNetWorthRow(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Account Balance',
            value: balance,
            color: _blue,
          ),
          const SizedBox(height: 12),
          _buildNetWorthRow(
            icon: Icons.savings_rounded,
            label: 'Savings Goals',
            value: savingsTotal,
            color: _green,
          ),
          const SizedBox(height: 12),
          _buildNetWorthRow(
            icon: Icons.trending_up_rounded,
            label: 'Investment Portfolio',
            value: _investmentValue,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Net Worth',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _currencyFormat.format(totalNetWorth),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthRow({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          _currencyFormat.format(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Task 1 #2 — Spending Breakdown by Category (PieChart) ─────────────────

  Widget _buildSpendingBreakdown(List<TransactionModel> transactions) {
    final debits = transactions.where((tx) => tx.isDebit && tx.isSuccess);
    final Map<String, double> categoryTotals = {};
    double totalSpending = 0;

    for (final tx in debits) {
      final category = _categorizeTransaction(tx);
      categoryTotals[category] = (categoryTotals[category] ?? 0) + tx.amount;
      totalSpending += tx.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = sortedEntries.map((entry) {
      final percentage =
          totalSpending > 0 ? (entry.value / totalSpending) * 100 : 0.0;
      return PieChartSectionData(
        value: entry.value,
        color: _categoryColors[entry.key] ?? Colors.grey,
        radius: 42,
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        titlePositionPercentageOffset: 0.65,
      );
    }).toList();

    return _buildDarkCard(
      title: 'Spending Breakdown',
      child: Column(
        children: [
          if (totalSpending == 0)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No spending data for this period',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 58,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Spent',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(totalSpending),
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Category legend with amounts
            ...sortedEntries.map((entry) {
              final percentage = totalSpending > 0
                  ? (entry.value / totalSpending) * 100
                  : 0.0;
              final color =
                  _categoryColors[entry.key] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      _categoryIcons[entry.key] ?? Icons.circle,
                      color: AppColors.onSurfaceVariant,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(entry.value),
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Task 1 #1 — Monthly Spending Trend (LineChart) ─────────────────────────

  Widget _buildMonthlySpendingTrend(
      List<TransactionModel> allTransactions) {
    final now = DateTime.now();
    final months = <DateTime>[];
    for (int i = 5; i >= 0; i--) {
      // Handle month arithmetic safely
      int year = now.year;
      int month = now.month - i;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      months.add(DateTime(year, month, 1));
    }

    final List<double> monthlySpend = List.filled(6, 0);

    for (final tx in allTransactions) {
      if (!tx.isDebit || !tx.isSuccess || tx.dateTime == null) continue;
      final txDate = tx.dateTime!;
      for (int i = 0; i < 6; i++) {
        if (txDate.year == months[i].year &&
            txDate.month == months[i].month) {
          monthlySpend[i] += tx.amount;
          break;
        }
      }
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < 6; i++) {
      spots.add(FlSpot(i.toDouble(), monthlySpend[i]));
    }

    final maxVal =
        monthlySpend.fold<double>(0, (prev, e) => max(prev, e));
    final double chartMaxY = maxVal > 0 ? maxVal * 1.3 : 1000.0;

    final allZero = monthlySpend.every((v) => v == 0);

    return _buildDarkCard(
      title: 'Monthly Spending Trend',
      child: Column(
        children: [
          if (allZero)
            const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No spending data available',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: chartMaxY,
                  clipData: const FlClipData.all(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => _bgSecondary,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final month = idx >= 0 && idx < months.length
                              ? DateFormat('MMMM yyyy')
                                  .format(months[idx])
                              : '';
                          return LineTooltipItem(
                            '$month\n${_currencyFormat.format(spot.y)}',
                            const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (data, indicators) {
                      return indicators.map((_) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: _red.withOpacity(0.4),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 5,
                              color: _red,
                              strokeWidth: 2,
                              strokeColor: AppColors.onSurface,
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMaxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.outlineVariant.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          String label;
                          if (value >= 1000000) {
                            label =
                                '\$${(value / 1000000).toStringAsFixed(1)}M';
                          } else if (value >= 1000) {
                            label =
                                '\$${(value / 1000).toStringAsFixed(0)}K';
                          } else {
                            label = '\$${value.toStringAsFixed(0)}';
                          }
                          return Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(months[idx]),
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: _red,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: _red,
                          strokeWidth: 1.5,
                          strokeColor:
                              AppColors.surfaceContainerLow,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _red.withOpacity(0.2),
                            _red.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!allZero) ...[
            const SizedBox(height: 16),
            // Summary row — highest and lowest spending months
            Builder(builder: (context) {
              final nonZero = monthlySpend
                  .asMap()
                  .entries
                  .where((e) => e.value > 0)
                  .toList();
              if (nonZero.isEmpty) return const SizedBox.shrink();
              final highest =
                  nonZero.reduce((a, b) => a.value > b.value ? a : b);
              final lowest =
                  nonZero.reduce((a, b) => a.value < b.value ? a : b);
              return Row(
                children: [
                  Expanded(
                    child: _buildTrendStat(
                      label: 'Highest Month',
                      value: _currencyFormat.format(highest.value),
                      sub: DateFormat('MMM yyyy')
                          .format(months[highest.key]),
                      color: _red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTrendStat(
                      label: 'Lowest Month',
                      value: _currencyFormat.format(lowest.value),
                      sub: DateFormat('MMM yyyy')
                          .format(months[lowest.key]),
                      color: _green,
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendStat({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.onSurfaceVariant, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              )),
          Text(sub,
              style: const TextStyle(
                  color: AppColors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Income vs Expenses Bar Chart ───────────────────────────────────────────

  Widget _buildIncomeVsExpenses(List<TransactionModel> allTransactions) {
    final now = DateTime.now();
    final months = <DateTime>[];
    for (int i = 5; i >= 0; i--) {
      int year = now.year;
      int month = now.month - i;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      months.add(DateTime(year, month, 1));
    }

    final List<double> incomes = List.filled(6, 0);
    final List<double> expenses = List.filled(6, 0);

    for (final tx in allTransactions) {
      if (!tx.isSuccess || tx.dateTime == null) continue;
      final txDate = tx.dateTime!;
      for (int i = 0; i < 6; i++) {
        if (txDate.year == months[i].year &&
            txDate.month == months[i].month) {
          if (tx.isCredit) {
            incomes[i] += tx.amount;
          } else if (tx.isDebit) {
            expenses[i] += tx.amount;
          }
          break;
        }
      }
    }

    final maxVal = [...incomes, ...expenses]
        .fold<double>(0, (prev, e) => max(prev, e));
    final double maxY = maxVal > 0 ? maxVal * 1.2 : 1000.0;

    return _buildDarkCard(
      title: 'Income vs Expenses',
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _bgSecondary,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$label\n${_currencyFormat.format(rod.toY)}',
                        TextStyle(
                          color: rodIndex == 0 ? _green : _red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        String label;
                        if (value >= 1000000) {
                          label =
                              '\$${(value / 1000000).toStringAsFixed(1)}M';
                        } else if (value >= 1000) {
                          label =
                              '\$${(value / 1000).toStringAsFixed(0)}K';
                        } else {
                          label = '\$${value.toStringAsFixed(0)}';
                        }
                        return Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM').format(months[idx]),
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.outlineVariant.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(6, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: incomes[i],
                        color: _green,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: expenses[i],
                        color: _red,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', _green),
              const SizedBox(width: 24),
              _buildLegendItem('Expenses', _red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Task 1 #3 — Top Merchants ──────────────────────────────────────────────

  Widget _buildTopMerchants(List<TransactionModel> transactions) {
    // Group debits by recipient / description
    final Map<String, _MerchantStats> merchantMap = {};

    for (final tx in transactions) {
      if (!tx.isDebit || !tx.isSuccess) continue;
      // Use relatedUserName if available, otherwise use description
      final key = (tx.relatedUserName?.isNotEmpty == true)
          ? tx.relatedUserName!
          : tx.description;
      final stats = merchantMap.putIfAbsent(key, () => _MerchantStats());
      stats.count++;
      stats.total += tx.amount;
    }

    final sorted = merchantMap.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final top5 = sorted.take(5).toList();

    final maxCount =
        top5.isEmpty ? 1 : top5.first.value.count.toDouble();

    return _buildDarkCard(
      title: 'Top Merchants',
      child: top5.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No merchant data for this period',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          : Column(
              children: top5.asMap().entries.map((entry) {
                final idx = entry.key;
                final name = entry.value.key;
                final stats = entry.value.value;
                final barFraction = stats.count / maxCount;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryContainer.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(stats.total),
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 38),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: barFraction,
                                minHeight: 5,
                                backgroundColor: AppColors.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _blue.withOpacity(0.75),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${stats.count} txn${stats.count != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── Task 1 #4 — Budget Tracker ─────────────────────────────────────────────

  Widget _buildBudgetTracker(List<TransactionModel> transactions) {
    // Sum current month's debit spending per category
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final Map<String, double> monthlySpend = {};
    for (final tx in transactions) {
      if (!tx.isDebit || !tx.isSuccess) continue;
      if (tx.dateTime == null || tx.dateTime!.isBefore(monthStart)) continue;
      final category = _categorizeTransaction(tx);
      monthlySpend[category] = (monthlySpend[category] ?? 0) + tx.amount;
    }

    return _buildDarkCard(
      title: 'Budget Tracker',
      child: Column(
        children: [
          // Month label
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: AppColors.onSurfaceVariant, size: 14),
              const SizedBox(width: 6),
              Text(
                'Budget for ${DateFormat('MMMM yyyy').format(now)}',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._budgets.entries.map((entry) {
            final category = entry.key;
            final budget = entry.value;
            final spent = monthlySpend[category] ?? 0.0;
            final progress = (spent / budget).clamp(0.0, 1.0);
            final isOver = spent > budget;
            final remaining = budget - spent;
            final progressColor = isOver ? _red : _green;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (_categoryColors[category] ?? Colors.grey)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _categoryIcons[category] ?? Icons.category_rounded,
                          color: _categoryColors[category] ?? Colors.grey,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_currencyFormat.format(spent)} of ${_currencyFormat.format(budget)}',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOver ? 'Over Budget' : 'On Track',
                          style: TextStyle(
                            color: progressColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOver
                            ? '${_currencyFormat.format(spent - budget)} over'
                            : '${_currencyFormat.format(remaining)} remaining',
                        style: TextStyle(
                          color: progressColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Helper class for merchant stats
class _MerchantStats {
  int count = 0;
  double total = 0;
}

class _InsightsData {
  final RecordModel user;
  final List<RecordModel> txRecords;
  _InsightsData({required this.user, required this.txRecords});
}
