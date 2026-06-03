import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class LoanScreen extends StatefulWidget {
  final String uid;

  const LoanScreen({super.key, required this.uid});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  final _currencyFormatDecimal =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  static const _loanProducts = [
    _LoanProduct(
      name: 'Personal Loan',
      icon: Icons.person_rounded,
      maxAmount: 15000,
      apr: 0.089,
      color: Color(0xFFB7C4FF),
      description: 'Flexible funds for any purpose',
    ),
    _LoanProduct(
      name: 'Home Improvement',
      icon: Icons.home_repair_service_rounded,
      maxAmount: 50000,
      apr: 0.065,
      color: Color(0xFF4ADE80),
      description: 'Upgrade your living space',
    ),
    _LoanProduct(
      name: 'Auto Loan',
      icon: Icons.directions_car_rounded,
      maxAmount: 35000,
      apr: 0.072,
      color: Color(0xFFFBBF24),
      description: 'Drive home your dream car',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildPreApprovedCard(),
                    const SizedBox(height: 28),
                    _buildProductsSection(context),
                    const SizedBox(height: 28),
                    _buildMyLoansSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      expandedHeight: 80,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.onSurface, size: 20),
      ),
      title: const Text(
        'Loan Center',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildPreApprovedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0052FF), Color(0xFFB7C4FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PRE-APPROVED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Pre-Approved Limit',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\$25,000',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Instant approval · No collateral required',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loan Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        ..._loanProducts.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LoanProductCard(
                product: product,
                currencyFormat: _currencyFormat,
                onTap: () => _showApplicationSheet(context, product),
              ),
            )),
      ],
    );
  }

  Widget _buildMyLoansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Loans',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<RecordModel>>(
          future: PbService.instance.pb
              .collection('loans')
              .getFullList(filter: 'userId="${widget.uid}"', sort: '-created'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyLoans();
            }
            final records = snapshot.data!;
            return Column(
              children: records
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LoanItemCard(
                          data: r.data,
                          currencyFormat: _currencyFormatDecimal,
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyLoans() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_rounded,
            size: 48,
            color: AppColors.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No active loans',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apply for a loan above to get started',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicationSheet(BuildContext context, _LoanProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoanApplicationSheet(
        product: product,
        uid: widget.uid,
        currencyFormat: _currencyFormatDecimal,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loan Product Card
// ─────────────────────────────────────────────────────────────────────────────
class _LoanProductCard extends StatelessWidget {
  final _LoanProduct product;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _LoanProductCard({
    required this.product,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: product.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(product.icon, color: product.color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.description,
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
                  'Up to ${currencyFormat.format(product.maxAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: product.color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(product.apr * 100).toStringAsFixed(1)}% APR',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loan Item Card (My Loans section)
// ─────────────────────────────────────────────────────────────────────────────
class _LoanItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currencyFormat;

  const _LoanItemCard({required this.data, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final monthlyPayment = (data['monthlyPayment'] as num?)?.toDouble() ?? 0;
    final term = (data['term'] as num?)?.toInt() ?? 12;
    final totalPayable = monthlyPayment * term;
    final paid = (data['amountPaid'] as num?)?.toDouble() ?? 0;
    final progress = totalPayable > 0 ? (paid / totalPayable).clamp(0.0, 1.0) : 0.0;
    final nextDue = DateTime.now().add(const Duration(days: 30));
    final status = data['status'] as String? ?? 'pending';

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['loanType'] as String? ?? 'Loan',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      currencyFormat.format(amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Payment',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      currencyFormat.format(monthlyPayment),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Due',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      DateFormat('MMM d').format(nextDue),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loan Application Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _LoanApplicationSheet extends StatefulWidget {
  final _LoanProduct product;
  final String uid;
  final NumberFormat currencyFormat;

  const _LoanApplicationSheet({
    required this.product,
    required this.uid,
    required this.currencyFormat,
  });

  @override
  State<_LoanApplicationSheet> createState() => _LoanApplicationSheetState();
}

class _LoanApplicationSheetState extends State<_LoanApplicationSheet> {
  double _amount = 5000;
  int _termMonths = 24;
  String _purpose = 'Home Improvement';
  bool _submitting = false;

  static const _terms = [12, 24, 36, 48, 60];
  static const _purposes = [
    'Home Improvement',
    'Medical',
    'Education',
    'Travel',
    'Other',
  ];

  double get _monthlyPayment {
    final r = widget.product.apr / 12;
    if (r == 0) return _amount / _termMonths;
    return _amount * r / (1 - math.pow(1 + r, -_termMonths));
  }

  Future<void> _submitApplication() async {
    setState(() => _submitting = true);
    try {
      await PbService.instance.pb.collection('loans').create(body: {
        'userId': widget.uid,
        'loanType': widget.product.name,
        'amount': _amount,
        'term': _termMonths,
        'apr': widget.product.apr,
        'monthlyPayment': _monthlyPayment,
        'purpose': _purpose,
        'status': 'pending',
        'amountPaid': 0,
      });
      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${widget.product.name} application is under review. We\'ll notify you within 24 hours.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.only(bottom: bottomInset + 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.product.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.product.icon,
                      color: widget.product.color, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply for ${widget.product.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '${(widget.product.apr * 100).toStringAsFixed(1)}% APR',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Amount slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Loan Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  widget.currencyFormat.format(_amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primaryContainer,
                inactiveTrackColor: AppColors.surfaceContainerHigh,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.1),
                trackHeight: 5,
              ),
              child: Slider(
                value: _amount,
                min: 500,
                max: widget.product.maxAmount.toDouble(),
                divisions: ((widget.product.maxAmount - 500) / 500).round(),
                onChanged: (v) => setState(() => _amount = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('\$500',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(widget.product.maxAmount),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Term selector
            const Text(
              'Loan Term',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _terms.map((term) {
                final selected = term == _termMonths;
                return ChoiceChip(
                  label: Text('$term mo'),
                  selected: selected,
                  onSelected: (_) => setState(() => _termMonths = term),
                  selectedColor: AppColors.primaryContainer,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Monthly payment
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryContainer.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Est. Monthly Payment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    widget.currencyFormat.format(_monthlyPayment),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Purpose dropdown
            const Text(
              'Loan Purpose',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _purpose,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceContainerHigh,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.onSurfaceVariant),
                  items: _purposes
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _purpose = v!),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor:
                      AppColors.primaryContainer.withOpacity(0.5),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Apply Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class _LoanProduct {
  final String name;
  final IconData icon;
  final int maxAmount;
  final double apr;
  final Color color;
  final String description;

  const _LoanProduct({
    required this.name,
    required this.icon,
    required this.maxAmount,
    required this.apr,
    required this.color,
    required this.description,
  });
}
