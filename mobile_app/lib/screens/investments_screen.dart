import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:real_banking/theme/app_colors.dart';

class InvestmentsScreen extends StatefulWidget {
  final String uid;

  const InvestmentsScreen({super.key, required this.uid});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedPieIndex = -1;

  static const _holdings = [
    _Holding(
      name: 'Apple',
      ticker: 'AAPL',
      shares: 10,
      price: 189.50,
      changePercent: 1.2,
      type: 'Stock',
      color: Color(0xFFB7C4FF),
      sparkline: [182, 185, 183, 187, 186, 188, 190, 189],
    ),
    _Holding(
      name: 'Microsoft',
      ticker: 'MSFT',
      shares: 5,
      price: 415.20,
      changePercent: -0.3,
      type: 'Stock',
      color: Color(0xFF4ADE80),
      sparkline: [418, 417, 416, 419, 415, 414, 416, 415],
    ),
    _Holding(
      name: 'Tesla',
      ticker: 'TSLA',
      shares: 8,
      price: 245.60,
      changePercent: 3.1,
      type: 'Stock',
      color: Color(0xFFFBBF24),
      sparkline: [235, 238, 240, 237, 241, 243, 245, 246],
    ),
    _Holding(
      name: 'S&P 500 ETF',
      ticker: 'SPY',
      shares: 15,
      price: 487.30,
      changePercent: 0.8,
      type: 'ETF',
      color: Color(0xFFFF8C42),
      sparkline: [482, 483, 481, 484, 485, 486, 487, 487],
    ),
    _Holding(
      name: 'Bitcoin',
      ticker: 'BTC',
      shares: 0.05,
      price: 43200,
      changePercent: -2.1,
      type: 'Crypto',
      color: Color(0xFFF7931A),
      sparkline: [44200, 43800, 44000, 43500, 43200, 43600, 43100, 43200],
    ),
  ];

  static const _marketStocks = [
    _MarketItem('Apple', 'AAPL', 189.50, 1.2),
    _MarketItem('Microsoft', 'MSFT', 415.20, -0.3),
    _MarketItem('Tesla', 'TSLA', 245.60, 3.1),
    _MarketItem('S&P 500 ETF', 'SPY', 487.30, 0.8),
    _MarketItem('Bitcoin', 'BTC', 43200.00, -2.1),
    _MarketItem('Google', 'GOOGL', 175.80, 0.5),
    _MarketItem('Amazon', 'AMZN', 182.40, 1.8),
    _MarketItem('NVIDIA', 'NVDA', 875.30, 2.4),
    _MarketItem('Meta', 'META', 512.60, -1.1),
    _MarketItem('Ethereum', 'ETH', 2380.00, 0.9),
  ];

  static const _newsItems = [
    _NewsItem(
      headline: 'Fed Holds Interest Rates Steady, Markets Rally on Positive Outlook',
      source: 'Reuters',
      time: '2h ago',
      icon: Icons.account_balance_rounded,
    ),
    _NewsItem(
      headline: 'Tech Giants Report Strong Q1 Earnings, Beating Analyst Estimates',
      source: 'Bloomberg',
      time: '4h ago',
      icon: Icons.trending_up_rounded,
    ),
    _NewsItem(
      headline: 'Bitcoin Surges Past \$43K as Institutional Demand Grows',
      source: 'CoinDesk',
      time: '6h ago',
      icon: Icons.currency_bitcoin_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDemoSnackbar(BuildContext context, String action, String ticker) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.warning, size: 18),
            const SizedBox(width: 8),
            Text(
              'Demo Mode — $action $ticker disabled',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxScrolled) => [
            _buildSliverAppBar(context),
          ],
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPortfolioTab(context),
                    _buildMarketTab(),
                    _buildOrdersTab(),
                    _buildNewsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.onSurface, size: 20),
      ),
      title: const Text(
        'Investments',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.onSurfaceVariant),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Portfolio'),
          Tab(text: 'Market'),
          Tab(text: 'Orders'),
          Tab(text: 'News'),
        ],
      ),
    );
  }

  // ── Portfolio Tab ─────────────────────────────────────────────────────────

  Widget _buildPortfolioTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        _buildPortfolioValueCard(),
        const SizedBox(height: 24),
        _buildAllocationChart(),
        const SizedBox(height: 24),
        const Text(
          'Holdings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        ..._holdings.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HoldingCard(
                holding: h,
                onBuy: () => _showDemoSnackbar(context, 'Trading', h.ticker),
                onSell: () => _showDemoSnackbar(context, 'Trading', h.ticker),
              ),
            )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPortfolioValueCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0052FF), Color(0xFF2B418F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Portfolio',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '\$12,450.80',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward_rounded,
                    color: Color(0xFF4ADE80), size: 14),
                SizedBox(width: 4),
                Text(
                  '+\$234.50 (+1.92%) today',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PortfolioStat(
                  label: 'Invested', value: '\$11,200.00'),
              const SizedBox(width: 24),
              _PortfolioStat(
                  label: 'Returns', value: '+\$1,250.80'),
              const SizedBox(width: 24),
              _PortfolioStat(label: 'Return %', value: '+11.17%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationChart() {
    const sections = [
      _PieSection('Stocks', 65, Color(0xFFB7C4FF)),
      _PieSection('ETF', 23, Color(0xFFFF8C42)),
      _PieSection('Crypto', 12, Color(0xFFF7931A)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asset Allocation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = response
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 36,
                    sections: sections.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      final isTouched = i == _touchedPieIndex;
                      return PieChartSectionData(
                        color: s.color,
                        value: s.percent.toDouble(),
                        title: '${s.percent}%',
                        radius: isTouched ? 55 : 48,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 13 : 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.label,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${s.percent}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: s.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Market Tab ────────────────────────────────────────────────────────────

  Widget _buildMarketTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _marketStocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final stock = _marketStocks[i];
        final isPositive = stock.changePercent >= 0;
        final color = isPositive ? AppColors.success : AppColors.error;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    stock.ticker.substring(0, math.min(2, stock.ticker.length)),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      stock.ticker,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stock.price >= 1000
                        ? '\$${stock.price.toStringAsFixed(0)}'
                        : '\$${stock.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
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

  // ── Orders Tab ────────────────────────────────────────────────────────────

  Widget _buildOrdersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: AppColors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No open orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your open and pending orders will appear here',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── News Tab ──────────────────────────────────────────────────────────────

  Widget _buildNewsTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _newsItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final news = _newsItems[i];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(news.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.headline,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          news.source,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          news.time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Holding Card
// ─────────────────────────────────────────────────────────────────────────────
class _HoldingCard extends StatelessWidget {
  final _Holding holding;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  const _HoldingCard({
    required this.holding,
    required this.onBuy,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = holding.changePercent >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;
    final totalValue = holding.shares * holding.price;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Ticker badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: holding.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    holding.ticker.length > 3
                        ? holding.ticker.substring(0, 3)
                        : holding.ticker,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: holding.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holding.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '${holding.shares % 1 == 0 ? holding.shares.toInt() : holding.shares} ${holding.type == 'Crypto' ? 'BTC' : 'shares'} · ${holding.type}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Sparkline
              _Sparkline(
                values: holding.sparkline,
                color: changeColor,
                width: 60,
                height: 32,
              ),

              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalValue >= 1000
                        ? '\$${(totalValue / 1000).toStringAsFixed(2)}k'
                        : '\$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${holding.changePercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: changeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TradeButton(
                  label: 'Buy',
                  color: AppColors.success,
                  onTap: onBuy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TradeButton(
                  label: 'Sell',
                  color: AppColors.error,
                  onTap: onSell,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sparkline Widget
// ─────────────────────────────────────────────────────────────────────────────
class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double width;
  final double height;

  const _Sparkline({
    required this.values,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(width: width, height: height);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    return SizedBox(
      width: width,
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final normalized = range > 0 ? (v - min) / range : 0.5;
          final barH = (normalized * (height - 4)) + 4;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: barH,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trade Button
// ─────────────────────────────────────────────────────────────────────────────
class _TradeButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TradeButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio stat widget (inside value card)
// ─────────────────────────────────────────────────────────────────────────────
class _PortfolioStat extends StatelessWidget {
  final String label;
  final String value;

  const _PortfolioStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _Holding {
  final String name;
  final String ticker;
  final double shares;
  final double price;
  final double changePercent;
  final String type;
  final Color color;
  final List<double> sparkline;

  const _Holding({
    required this.name,
    required this.ticker,
    required this.shares,
    required this.price,
    required this.changePercent,
    required this.type,
    required this.color,
    required this.sparkline,
  });
}

class _MarketItem {
  final String name;
  final String ticker;
  final double price;
  final double changePercent;

  const _MarketItem(this.name, this.ticker, this.price, this.changePercent);
}

class _NewsItem {
  final String headline;
  final String source;
  final String time;
  final IconData icon;

  const _NewsItem({
    required this.headline,
    required this.source,
    required this.time,
    required this.icon,
  });
}

class _PieSection {
  final String label;
  final int percent;
  final Color color;

  const _PieSection(this.label, this.percent, this.color);
}
