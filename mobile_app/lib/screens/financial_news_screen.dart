import 'dart:math';
import 'package:flutter/material.dart';
import 'package:real_banking/theme/app_colors.dart';

class FinancialNewsScreen extends StatefulWidget {
  const FinancialNewsScreen({super.key});

  @override
  State<FinancialNewsScreen> createState() => _FinancialNewsScreenState();
}

class _FinancialNewsScreenState extends State<FinancialNewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Markets',
    'Economy',
    'Crypto',
    'Real Estate',
    'Tech',
  ];

  final List<_NewsArticle> _articles = [
    _NewsArticle(
      headline: 'Fed Holds Rates Steady, Markets Rally on Inflation Data',
      snippet:
          'The Federal Reserve maintained benchmark interest rates, citing encouraging inflation trends. Markets surged on the announcement.',
      source: 'Reuters',
      timestamp: '2h ago',
      category: 'Economy',
      fullText:
          'The Federal Reserve held its benchmark interest rate steady at 5.25–5.50% on Wednesday, signaling that policymakers believe inflation is gradually coming under control. Fed Chair Jerome Powell said the committee was "encouraged" by recent data showing a decline in the core PCE price index, though he cautioned against premature rate cuts. Markets reacted positively to the announcement, with the S&P 500 gaining 0.9% and the Nasdaq climbing more than 1.2%. Treasury yields fell sharply, with the 10-year note dropping 12 basis points to 4.18%. Analysts at major investment banks expect two rate cuts by year-end if inflation continues on its current trajectory. "The Fed is threading the needle here — maintaining restraint while leaving the door open," said one senior strategist. Retail and consumer discretionary stocks led the rally, as lower rates tend to boost spending in those sectors.',
    ),
    _NewsArticle(
      headline: 'Big Tech Earnings Beat Expectations Across the Board',
      snippet:
          'Major technology companies posted quarterly earnings that exceeded analyst forecasts, driven by AI-related revenue growth.',
      source: 'Bloomberg',
      timestamp: '4h ago',
      category: 'Tech',
      fullText:
          'A wave of strong quarterly results from the biggest names in technology sent indices to new highs this week. Cloud computing and artificial intelligence divisions were the standout performers, with several companies reporting double-digit revenue growth in these segments. Advertising revenues also rebounded sharply compared to the same period last year. Several firms raised their full-year guidance, citing stronger-than-expected enterprise demand for AI tools. "The AI investment cycle is very much alive," said one portfolio manager. Market capitalization gains across the five largest tech firms topped \$400 billion on earnings day alone. Analysts upgraded price targets across the sector, with consensus estimates for 2025 EPS being revised upward by an average of 8%. The results also buoyed semiconductor stocks, which had lagged in recent months on concerns over inventory cycles.',
    ),
    _NewsArticle(
      headline: 'Consumer Spending Rises 0.3% in January Report',
      snippet:
          'Personal consumption expenditures rose modestly in January, suggesting consumer resilience despite elevated interest rates.',
      source: 'CNBC',
      timestamp: '6h ago',
      category: 'Economy',
      fullText:
          'Personal consumption expenditures increased 0.3% in January, roughly in line with analyst expectations, the Bureau of Economic Analysis reported Thursday. The data signals that American consumers remain in reasonably good financial health despite the longest stretch of elevated interest rates in over two decades. Services spending rose 0.4%, led by healthcare and recreation, while goods spending was flat. Real disposable income edged up 0.1%, suggesting that wage growth is still outpacing inflation for most households. The savings rate ticked up to 3.8%, a slight improvement from 3.4% the prior month. Economists cautioned that this is a backward-looking indicator and that credit card delinquency rates — now at multi-year highs for lower-income households — could signal stress ahead. "The top third of consumers are still spending freely, but the bottom third are struggling," noted one economist at a major research firm.',
    ),
    _NewsArticle(
      headline: 'Oil Prices Dip as OPEC+ Extends Production Cuts',
      snippet:
          'Crude oil fell despite OPEC+ announcing an extension of supply cuts, as weak demand data from China weighed on prices.',
      source: 'Reuters',
      timestamp: '8h ago',
      category: 'Markets',
      fullText:
          'Brent crude futures fell 1.4% to \$82.60 per barrel on Thursday, even as OPEC+ announced it would extend existing production cuts through the second quarter of the year. The surprise decline was attributed to weaker-than-expected manufacturing and industrial output data from China, the world\'s largest oil importer. The International Energy Agency trimmed its 2025 demand growth forecast by 200,000 barrels per day, citing slower Chinese economic activity and accelerating electric vehicle adoption. Saudi Arabia and Russia, the alliance\'s two largest producers, confirmed they would each maintain their voluntary additional cutback of 1 million barrels per day. West Texas Intermediate dropped 1.6% to \$78.40. Natural gas prices remained stable at \$2.14 per MMBtu. Gasoline futures fell 0.8%, potentially offering relief to US consumers at the pump in coming weeks.',
    ),
    _NewsArticle(
      headline: 'Real Estate Market Shows Signs of Cooling',
      snippet:
          'Home sales declined for the third consecutive month as mortgage rates near 7% continue to sideline potential buyers.',
      source: 'Bloomberg',
      timestamp: '10h ago',
      category: 'Real Estate',
      fullText:
          'Existing home sales fell 2.8% in the most recent month, the third consecutive monthly decline, as mortgage rates hovering near 7% kept many would-be buyers on the sidelines. The National Association of Realtors reported a seasonally adjusted annual rate of 3.96 million units, the lowest since the early 2010s. Median home prices, however, remained elevated at \$398,000, up 4.1% year-over-year, as inventory shortages continue to support values even as transaction volumes fall. New listings rose 6% from the prior month, offering a modest improvement in supply. The 30-year fixed mortgage rate averaged 6.94% this week, according to Freddie Mac. Builders, meanwhile, are offering more incentives and buying down mortgage rates to move inventory. "We\'re in a strange market — prices are still high but sales are collapsing," said one real estate economist. Analysts expect a gradual recovery in activity once rates fall below 6.5%.',
    ),
    _NewsArticle(
      headline: 'Crypto Markets Surge as Bitcoin Breaks \$45K',
      snippet:
          'Bitcoin surpassed \$45,000 for the first time in months, with analysts crediting renewed institutional interest and ETF inflows.',
      source: 'CNBC',
      timestamp: '1d ago',
      category: 'Crypto',
      fullText:
          'Bitcoin climbed above \$45,000 for the first time since last year, closing at \$45,280 after a sharp intraday rally that caught many traders off guard. The move coincided with a fresh wave of inflows into spot Bitcoin ETFs, which have seen cumulative net inflows of over \$9 billion since launching earlier this year. Ethereum also rallied sharply, gaining 8.2% to trade above \$2,600. Analysts pointed to growing institutional demand, a weakening dollar, and improving macroeconomic sentiment as key drivers. "Bitcoin is increasingly being treated as a macro asset, similar to gold," said one cryptocurrency strategist. Total crypto market capitalization rose above \$1.8 trillion. Altcoins broadly participated in the rally, with Solana and Avalanche each gaining more than 12%. The options market showed a sharp uptick in calls for \$50,000 by end of quarter, suggesting traders expect further upside.',
    ),
    _NewsArticle(
      headline: 'Retail Sales Data Beats Forecasts, Dollar Strengthens',
      snippet:
          'US retail sales came in stronger than expected, boosting the dollar and sending bond yields higher across maturities.',
      source: 'Reuters',
      timestamp: '1d ago',
      category: 'Markets',
      fullText:
          'Retail sales rose 0.6% in the most recent month, beating the consensus estimate of 0.3% and reversing the prior month\'s 0.2% decline. The stronger-than-expected reading lifted the US Dollar Index by 0.5%, as traders scaled back bets on near-term Federal Reserve rate cuts. Motor vehicle sales and nonstore retailers — which include e-commerce — led the gains. The control group measure, which feeds directly into GDP calculations, rose 0.7%, well above expectations. "This is a strong number that suggests the consumer is still in decent shape," said one economist. The 10-year Treasury yield rose 8 basis points to 4.31% on the news. Equity markets had a mixed reaction, with rate-sensitive sectors like utilities and real estate falling while financials and industrials moved higher. Economists raised their Q1 GDP growth tracking estimates to above 2% following the release.',
    ),
    _NewsArticle(
      headline: 'Global Supply Chains Stabilize After Two-Year Disruption',
      snippet:
          'Shipping costs and delivery times have returned to pre-pandemic norms, offering relief to manufacturers and consumers alike.',
      source: 'Bloomberg',
      timestamp: '2d ago',
      category: 'Economy',
      fullText:
          'Global supply chains have largely stabilized following a prolonged period of disruption sparked by the pandemic, according to new data from major logistics firms. Container shipping costs on the Asia-to-Europe and transpacific routes have fallen to their lowest levels since 2019, down more than 70% from their 2021 peaks. Lead times for semiconductors and industrial components have also normalized, with average waits dropping from 26 weeks at the peak to under 12 weeks now. The improvement is being driven by expanded port capacity, new shipping routes, and a moderation in goods demand as consumers have shifted back toward services spending. Manufacturers are cautiously rebuilding inventory after years of just-in-time strategies that left them exposed. "The era of supply chain as a geopolitical and economic crisis is largely behind us," said one supply chain expert, though he noted that geopolitical risks remain a wildcard.',
    ),
  ];

  final List<_FinancialTip> _tips = [
    _FinancialTip(
      icon: Icons.savings_rounded,
      title: 'Pay Yourself First',
      tip:
          'Automate a fixed transfer to savings the day you get paid. Treat it like a non-negotiable bill.',
    ),
    _FinancialTip(
      icon: Icons.credit_card_off_rounded,
      title: 'Crush High-Interest Debt',
      tip:
          'Prioritize paying off credit cards and personal loans before investing — guaranteed 20%+ return.',
    ),
    _FinancialTip(
      icon: Icons.pie_chart_rounded,
      title: 'The 50/30/20 Rule',
      tip:
          'Allocate 50% to needs, 30% to wants, and 20% to savings and debt repayment for balanced finances.',
    ),
    _FinancialTip(
      icon: Icons.trending_up_rounded,
      title: 'Start Investing Early',
      tip:
          'Even \$50/month invested at 25 grows to over \$160,000 by 65. Compound interest rewards patience.',
    ),
    _FinancialTip(
      icon: Icons.shield_rounded,
      title: 'Build Your Emergency Fund',
      tip:
          'Keep 3–6 months of living expenses in a high-yield savings account for unexpected events.',
    ),
  ];

  final List<_MarketIndex> _indices = [
    _MarketIndex(name: 'S&P 500', value: '5,234.18', change: '+0.42%', isUp: true),
    _MarketIndex(name: 'NASDAQ', value: '16,428.82', change: '+0.67%', isUp: true),
    _MarketIndex(name: 'DOW', value: '38,924.58', change: '-0.12%', isUp: false),
    _MarketIndex(name: 'VIX', value: '14.23', change: '-3.21%', isUp: false),
  ];

  List<_NewsArticle> get _filteredArticles {
    if (_selectedCategory == 'All') return _articles;
    return _articles
        .where((a) => a.category == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _categories[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showArticleDetail(_NewsArticle article) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildSourceBadge(article.source),
                const SizedBox(width: 8),
                _buildCategoryChip(article.category),
                const Spacer(),
                Text(
                  article.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              article.headline,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.outlineVariant, height: 1),
            const SizedBox(height: 16),
            Text(
              article.fullText,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.onSurface, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial News',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Markets & headlines',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: AppColors.onSurfaceVariant, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 36,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  dividerColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 14),
                  tabs:
                      _categories.map((c) => Tab(text: c)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable content
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Market Overview
                  if (_selectedCategory == 'All') ...[
                    _buildSectionLabel('MARKET OVERVIEW'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _indices.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (ctx, i) =>
                            _buildIndexCard(_indices[i]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // News feed
                  _buildSectionLabel('LATEST NEWS'),
                  const SizedBox(height: 12),
                  ..._filteredArticles.map((a) => _buildArticleCard(a)),

                  // Financial tips (only on All tab)
                  if (_selectedCategory == 'All') ...[
                    const SizedBox(height: 24),
                    _buildSectionLabel('FINANCIAL TIPS'),
                    const SizedBox(height: 12),
                    ..._tips.map((t) => _buildTipCard(t)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildIndexCard(_MarketIndex index) {
    final rand = Random(index.name.hashCode);
    final bars = List.generate(12, (_) => 0.3 + rand.nextDouble() * 0.7);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                index.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: index.isUp
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  index.change,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: index.isUp
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            index.value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Sparkline
          SizedBox(
            height: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((h) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: 24 * h,
                    decoration: BoxDecoration(
                      color: (index.isUp
                              ? AppColors.success
                              : AppColors.error)
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(_NewsArticle article) {
    return GestureDetector(
      onTap: () => _showArticleDetail(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSourceBadge(article.source),
                const SizedBox(width: 8),
                _buildCategoryChip(article.category),
                const Spacer(),
                Text(
                  article.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article.headline,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Read more',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.primaryContainer, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    Color color;
    switch (source) {
      case 'Reuters':
        color = const Color(0xFFFF8000);
        break;
      case 'Bloomberg':
        color = const Color(0xFF0075FF);
        break;
      case 'CNBC':
        color = const Color(0xFF009900);
        break;
      default:
        color = AppColors.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        source,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryContainer,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTipCard(_FinancialTip tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.primaryContainer.withOpacity(0.1), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tip.icon,
                color: AppColors.primaryContainer, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.tip,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
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

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _MarketIndex {
  final String name;
  final String value;
  final String change;
  final bool isUp;

  const _MarketIndex({
    required this.name,
    required this.value,
    required this.change,
    required this.isUp,
  });
}

class _NewsArticle {
  final String headline;
  final String snippet;
  final String source;
  final String timestamp;
  final String category;
  final String fullText;

  const _NewsArticle({
    required this.headline,
    required this.snippet,
    required this.source,
    required this.timestamp,
    required this.category,
    required this.fullText,
  });
}

class _FinancialTip {
  final IconData icon;
  final String title;
  final String tip;

  const _FinancialTip({
    required this.icon,
    required this.title,
    required this.tip,
  });
}
