import 'dart:math';
import 'package:flutter/material.dart';
import 'package:real_banking/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────
class _CryptoAsset {
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final Color iconColor;
  final String iconLetter;
  final String marketCap;
  final String volume24h;
  final String description;

  const _CryptoAsset({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.iconColor,
    required this.iconLetter,
    required this.marketCap,
    required this.volume24h,
    required this.description,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Static market data
// ─────────────────────────────────────────────────────────────────────────────
const _kAssets = <_CryptoAsset>[
  _CryptoAsset(
    symbol: 'BTC',
    name: 'Bitcoin',
    price: 67234.50,
    change24h: 2.34,
    iconColor: Color(0xFFF7931A),
    iconLetter: '₿',
    marketCap: '\$1.32T',
    volume24h: '\$38.4B',
    description:
        'Bitcoin is the first decentralized cryptocurrency. It operates on a peer-to-peer network with no central authority, using blockchain technology to record transactions.',
  ),
  _CryptoAsset(
    symbol: 'ETH',
    name: 'Ethereum',
    price: 3567.80,
    change24h: -0.87,
    iconColor: Color(0xFF627EEA),
    iconLetter: 'Ξ',
    marketCap: '\$428.6B',
    volume24h: '\$18.2B',
    description:
        'Ethereum is a decentralized platform enabling smart contracts and dApps. Its native token Ether (ETH) powers the network and is the second-largest crypto by market cap.',
  ),
  _CryptoAsset(
    symbol: 'SOL',
    name: 'Solana',
    price: 185.40,
    change24h: 5.21,
    iconColor: Color(0xFF9945FF),
    iconLetter: 'S',
    marketCap: '\$84.7B',
    volume24h: '\$4.1B',
    description:
        'Solana is a high-performance blockchain supporting fast, low-cost transactions. It uses a novel Proof-of-History consensus combined with Proof-of-Stake.',
  ),
  _CryptoAsset(
    symbol: 'BNB',
    name: 'BNB',
    price: 608.30,
    change24h: 1.45,
    iconColor: Color(0xFFF3BA2F),
    iconLetter: 'B',
    marketCap: '\$89.4B',
    volume24h: '\$2.3B',
    description:
        'BNB is the native token of the BNB Chain ecosystem, originally created as a utility token for Binance exchange. It is used to pay fees and participate in token sales.',
  ),
  _CryptoAsset(
    symbol: 'XRP',
    name: 'XRP',
    price: 0.6234,
    change24h: -2.10,
    iconColor: Color(0xFF00AAE4),
    iconLetter: 'X',
    marketCap: '\$34.1B',
    volume24h: '\$1.7B',
    description:
        'XRP is the digital asset of the XRP Ledger, designed for fast, low-cost international money transfers. It is used by banks and financial institutions worldwide.',
  ),
  _CryptoAsset(
    symbol: 'ADA',
    name: 'Cardano',
    price: 0.4523,
    change24h: 0.78,
    iconColor: Color(0xFF0033AD),
    iconLetter: '₳',
    marketCap: '\$16.0B',
    volume24h: '\$412M',
    description:
        'Cardano is a proof-of-stake blockchain platform focused on sustainability and scalability. Built with peer-reviewed research, it aims to provide financial services globally.',
  ),
  _CryptoAsset(
    symbol: 'AVAX',
    name: 'Avalanche',
    price: 38.45,
    change24h: 3.67,
    iconColor: Color(0xFFE84142),
    iconLetter: 'A',
    marketCap: '\$15.8B',
    volume24h: '\$627M',
    description:
        'Avalanche is a fast, low-cost, eco-friendly blockchain. It supports smart contracts and can process thousands of transactions per second with near-instant finality.',
  ),
  _CryptoAsset(
    symbol: 'DOT',
    name: 'Polkadot',
    price: 8.92,
    change24h: -1.23,
    iconColor: Color(0xFFE6007A),
    iconLetter: '●',
    marketCap: '\$11.6B',
    volume24h: '\$318M',
    description:
        'Polkadot enables cross-blockchain transfers of any data or asset. It provides shared security across all connected chains and is designed to enable a web of blockchains.',
  ),
  _CryptoAsset(
    symbol: 'LINK',
    name: 'Chainlink',
    price: 18.67,
    change24h: 4.56,
    iconColor: Color(0xFF375BD2),
    iconLetter: '⬡',
    marketCap: '\$10.9B',
    volume24h: '\$589M',
    description:
        'Chainlink is a decentralized oracle network that connects smart contracts with real-world data. It enables smart contracts to securely interact with external data sources.',
  ),
  _CryptoAsset(
    symbol: 'MATIC',
    name: 'Polygon',
    price: 0.8934,
    change24h: 2.89,
    iconColor: Color(0xFF8247E5),
    iconLetter: 'M',
    marketCap: '\$8.7B',
    volume24h: '\$427M',
    description:
        'Polygon (formerly Matic) is a layer-2 scaling solution for Ethereum. It provides faster and cheaper transactions while maintaining Ethereum security.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Crypto Screen
// ─────────────────────────────────────────────────────────────────────────────
class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Formatting helpers ────────────────────────────────────────────────────
  String _fmtPrice(double p) {
    if (p >= 10000) {
      return '\$${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    } else if (p >= 1) {
      return '\$${p.toStringAsFixed(2)}';
    } else {
      return '\$${p.toStringAsFixed(4)}';
    }
  }

  // ── Bottom sheet helpers ──────────────────────────────────────────────────
  void _showTradingSheet(String action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.science_rounded,
                  color: AppColors.warning, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              '$action Crypto — Demo Mode',
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crypto trading is coming soon to STCU Banking.\nYou\'ll be notified when it launches.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssetDetail(_CryptoAsset asset) {
    final isPos = asset.change24h >= 0;
    final changeColor =
        isPos ? AppColors.success : AppColors.error;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header row
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: asset.iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: asset.iconColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        asset.iconLetter,
                        style: TextStyle(
                          color: asset.iconColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
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
                          asset.name,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          asset.symbol,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtPrice(asset.price),
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: changeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPos
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: changeColor,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${asset.change24h.abs().toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Market Cap',
                      value: asset.marketCap,
                      icon: Icons.bar_chart_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: '24h Volume',
                      value: asset.volume24h,
                      icon: Icons.swap_horiz_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // About
              const Text(
                'About',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                asset.description,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 28),

              // Buy / Sell row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showTradingSheet('Sell');
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Sell',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showTradingSheet('Buy');
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.electricGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Buy',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: const Text(
          'Crypto',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.science_rounded,
                    color: AppColors.warning, size: 13),
                SizedBox(width: 4),
                Text(
                  'DEMO',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryContainer,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.onSurface,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Portfolio'),
            Tab(text: 'Market'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPortfolioTab(),
          _buildMarketTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Portfolio tab — empty state (demo, $0 portfolio)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPortfolioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Portfolio value card ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.electricGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.currency_bitcoin_rounded,
                        color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Total Portfolio Value',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '\$0.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.horizontal_rule_rounded,
                          color: Colors.white70, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'No holdings yet',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Buy / Sell buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTradingSheet('Buy'),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: AppColors.primaryContainer, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Buy Crypto',
                                style: TextStyle(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTradingSheet('Sell'),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Sell Crypto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
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
          const SizedBox(height: 28),

          // ── Empty holdings state ──────────────────────────────────────
          const Text(
            'YOUR HOLDINGS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryContainer.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.currency_bitcoin_rounded,
                    color: AppColors.primaryContainer,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Start investing in crypto',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Buy Bitcoin, Ethereum, and 50+ other\ncryptocurrencies directly from your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => _showTradingSheet('Buy'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: AppColors.electricGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primaryContainer.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Explore Crypto',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Trending section ──────────────────────────────────────────
          const Text(
            'TRENDING TODAY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildTrendingSection(),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    // Top 3 gainers
    final gainers = _kAssets.toList()
      ..sort((a, b) => b.change24h.compareTo(a.change24h));
    final top3 = gainers.take(3).toList();

    return Row(
      children: top3.asMap().entries.map((entry) {
        final idx = entry.key;
        final asset = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: idx == 0 ? 0 : 6,
              right: idx == 2 ? 0 : 6,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.success.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? const Color(0xFFFFD700)
                            : idx == 1
                                ? const Color(0xFFC0C0C0)
                                : const Color(0xFFCD7F32),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#${idx + 1}',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: asset.iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      asset.iconLetter,
                      style: TextStyle(
                        color: asset.iconColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  asset.symbol,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${asset.change24h.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Market tab
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMarketTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Market summary bar
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Total Mkt Cap',
                  value: '\$2.47T',
                  isPositive: true,
                  change: '+1.8%',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.outlineVariant.withOpacity(0.2),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'BTC Dominance',
                  value: '53.4%',
                  isPositive: true,
                  change: '+0.3%',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.outlineVariant.withOpacity(0.2),
              ),
              Expanded(
                child: _MiniStat(
                  label: '24h Volume',
                  value: '\$89.4B',
                  isPositive: false,
                  change: '-2.1%',
                ),
              ),
            ],
          ),
        ),

        // Column headers
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: const [
              SizedBox(width: 48),
              SizedBox(
                width: 6,
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Asset',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '7d chart',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  'Price / 24h',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Asset rows
        ..._kAssets.map(
          (asset) => _MarketRow(
            asset: asset,
            rng: _rng,
            fmtPrice: _fmtPrice,
            onTap: () => _showAssetDetail(asset),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Market row widget
// ─────────────────────────────────────────────────────────────────────────────
class _MarketRow extends StatelessWidget {
  final _CryptoAsset asset;
  final Random rng;
  final String Function(double) fmtPrice;
  final VoidCallback onTap;

  const _MarketRow({
    required this.asset,
    required this.rng,
    required this.fmtPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = asset.change24h >= 0;
    final changeColor = isPos ? AppColors.success : AppColors.error;
    // Deterministic sparkline heights seeded per symbol
    final seed = asset.symbol.codeUnits.fold(0, (a, b) => a + b);
    final sparkRng = Random(seed);
    final sparkHeights = List.generate(8, (_) => 6.0 + sparkRng.nextDouble() * 22);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
            // Colored icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: asset.iconColor.withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: asset.iconColor.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  asset.iconLetter,
                  style: TextStyle(
                    color: asset.iconColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name / symbol
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    asset.name,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Sparkline
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: sparkHeights
                      .map((h) => Container(
                            width: 4,
                            height: h,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: changeColor.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Price + change badge
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmtPrice(asset.price),
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPos
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: changeColor,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${asset.change24h.abs().toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: changeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;
  final String change;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.isPositive,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.error;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          change,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
