import 'package:flutter/material.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:real_banking/screens/send_money_screen.dart';
import 'package:real_banking/services/pb_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _amountController = TextEditingController(text: '1.00');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double? _result;

  // Hardcoded realistic exchange rates relative to USD (2024)
  static const Map<String, double> _rates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 149.50,
    'CAD': 1.36,
    'AUD': 1.53,
    'CHF': 0.89,
    'CNY': 7.24,
    'INR': 83.12,
    'MXN': 17.15,
    'BRL': 4.97,
    'NGN': 1580.00,
    'ZAR': 18.63,
    'AED': 3.67,
    'SGD': 1.34,
  };

  static const List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar',        'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro',              'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound',    'flag': '🇬🇧'},
    {'code': 'JPY', 'name': 'Japanese Yen',     'flag': '🇯🇵'},
    {'code': 'CAD', 'name': 'Canadian Dollar',  'flag': '🇨🇦'},
    {'code': 'AUD', 'name': 'Australian Dollar','flag': '🇦🇺'},
    {'code': 'CHF', 'name': 'Swiss Franc',      'flag': '🇨🇭'},
    {'code': 'CNY', 'name': 'Chinese Yuan',     'flag': '🇨🇳'},
    {'code': 'INR', 'name': 'Indian Rupee',     'flag': '🇮🇳'},
    {'code': 'MXN', 'name': 'Mexican Peso',     'flag': '🇲🇽'},
    {'code': 'BRL', 'name': 'Brazilian Real',   'flag': '🇧🇷'},
    {'code': 'NGN', 'name': 'Nigerian Naira',   'flag': '🇳🇬'},
    {'code': 'ZAR', 'name': 'South African Rand','flag': '🇿🇦'},
    {'code': 'AED', 'name': 'UAE Dirham',       'flag': '🇦🇪'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'flag': '🇸🇬'},
  ];

  // Popular conversions: from, to
  static const List<Map<String, String>> _popularConversions = [
    {'from': 'USD', 'to': 'EUR'},
    {'from': 'USD', 'to': 'GBP'},
    {'from': 'USD', 'to': 'JPY'},
    {'from': 'USD', 'to': 'NGN'},
  ];

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Convert from _fromCurrency to _toCurrency using USD as base.
  void _convert() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fromRate = _rates[_fromCurrency] ?? 1.0;
    final toRate = _rates[_toCurrency] ?? 1.0;
    // Convert amount → USD → target
    setState(() => _result = amount * (toRate / fromRate));
  }

  double _pairRate(String from, String to) {
    final fromRate = _rates[from] ?? 1.0;
    final toRate = _rates[to] ?? 1.0;
    return toRate / fromRate;
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convert();
  }

  Map<String, String> _currencyMeta(String code) =>
      _currencies.firstWhere((c) => c['code'] == code, orElse: () => _currencies.first);

  @override
  Widget build(BuildContext context) {
    final uid = PbService.instance.currentUserId ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: const Text('Currency Converter', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── From currency card ─────────────────────────────────────────
            _currencyCard('From', _fromCurrency, _amountController, editable: true),
            const SizedBox(height: 12),

            // ── Swap button ────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _swap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryContainer.withOpacity(0.35)),
                  ),
                  child: const Icon(Icons.swap_vert_rounded, color: AppColors.primaryContainer, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── To currency card ───────────────────────────────────────────
            _currencyCard('To', _toCurrency, null, editable: false),
            const SizedBox(height: 24),

            // ── Large result display ───────────────────────────────────────
            if (_result != null) _resultCard(),
            const SizedBox(height: 28),

            // ── Popular Conversions ────────────────────────────────────────
            _sectionTitle('Popular Conversions'),
            const SizedBox(height: 12),
            _popularConversionsGrid(),
            const SizedBox(height: 28),

            // ── Rate Alerts ────────────────────────────────────────────────
            _sectionTitle('Rate Alerts'),
            const SizedBox(height: 12),
            _rateAlertsCard(),
            const SizedBox(height: 28),

            // ── Last updated ───────────────────────────────────────────────
            Center(
              child: Text(
                'Rates updated: March 2024',
                style: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.7), fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

            // ── Send at this rate ─────────────────────────────────────────
            _sendAtRateButton(uid),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Result card ────────────────────────────────────────────────────────────
  Widget _resultCard() {
    final rate = _pairRate(_fromCurrency, _toCurrency);
    final fromMeta = _currencyMeta(_fromCurrency);
    final toMeta = _currencyMeta(_toCurrency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          Text(
            '${fromMeta['flag']} ${_amountController.text} $_fromCurrency  =',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            '${toMeta['flag']} ${_result!.toStringAsFixed(4)} $_toCurrency',
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '1 $_fromCurrency = ${rate.toStringAsFixed(4)} $_toCurrency',
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Currency card (From / To) ──────────────────────────────────────────────
  Widget _currencyCard(
    String label,
    String selectedCode,
    TextEditingController? controller, {
    required bool editable,
  }) {
    final meta = _currencyMeta(selectedCode);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Currency selector
              GestureDetector(
                onTap: () => _showCurrencyPicker(isFrom: label == 'From'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBright),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(meta['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        selectedCode,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Amount field or result
              Expanded(
                child: editable
                    ? TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(color: AppColors.onSurface.withOpacity(0.15)),
                        ),
                        onChanged: (_) => _convert(),
                      )
                    : Text(
                        _result != null
                            ? (_result! >= 1000
                                ? _result!.toStringAsFixed(2)
                                : _result!.toStringAsFixed(4))
                            : '0.00',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Currency full name
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              meta['name']!,
              style: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.7), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Popular conversions grid ───────────────────────────────────────────────
  Widget _popularConversionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _popularConversions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, i) {
        final pair = _popularConversions[i];
        final from = pair['from']!;
        final to = pair['to']!;
        final fromMeta = _currencyMeta(from);
        final toMeta = _currencyMeta(to);
        final rate = _pairRate(from, to);

        return GestureDetector(
          onTap: () {
            setState(() {
              _fromCurrency = from;
              _toCurrency = to;
            });
            _convert();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (_fromCurrency == from && _toCurrency == to)
                    ? AppColors.primaryContainer.withOpacity(0.6)
                    : AppColors.surfaceContainerHigh,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(fromMeta['flag']!, style: const TextStyle(fontSize: 16)),
                    const Icon(Icons.arrow_forward, color: AppColors.onSurfaceVariant, size: 14),
                    Text(toMeta['flag']!, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$from → $to',
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1 $from = ${rate >= 100 ? rate.toStringAsFixed(1) : rate.toStringAsFixed(4)} $to',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Rate alerts card ───────────────────────────────────────────────────────
  Widget _rateAlertsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_outlined, color: AppColors.warning, size: 22),
        ),
        title: const Text(
          'Get notified when rates change',
          style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'Set a target rate and we\'ll alert you',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Rate alerts coming soon'),
              backgroundColor: AppColors.surfaceContainerHigh,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  // ── Send at this rate button ───────────────────────────────────────────────
  Widget _sendAtRateButton(String uid) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppColors.electricGradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SendMoneyScreen(senderUid: uid),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.send_rounded, color: AppColors.onSurface, size: 18),
                SizedBox(width: 8),
                Text(
                  'Send at this rate',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );

  // ── Currency picker bottom sheet ───────────────────────────────────────────
  void _showCurrencyPicker({required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select Currency',
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: _currencies
                      .map((c) => ListTile(
                            leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                            title: Text(
                              c['code']!,
                              style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              c['name']!,
                              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                            ),
                            trailing: ((isFrom ? _fromCurrency : _toCurrency) == c['code'])
                                ? const Icon(Icons.check_circle, color: AppColors.primaryContainer)
                                : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onTap: () {
                              setState(() {
                                if (isFrom) {
                                  _fromCurrency = c['code']!;
                                } else {
                                  _toCurrency = c['code']!;
                                }
                              });
                              Navigator.pop(ctx);
                              _convert();
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
