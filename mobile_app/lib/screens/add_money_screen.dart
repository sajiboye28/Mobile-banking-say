import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/services/app_config.dart';
import 'package:real_banking/theme/app_colors.dart';

final String _kDepositUrl = '$kApiBase/deposit';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSuccess = false;
  double _depositedAmount = 0;
  int _selectedSource = 0;

  final List<_BankSource> _sources = [
    _BankSource('Chase Bank', 'Checking ••••4521', Icons.account_balance_rounded, const Color(0xFF117ACA)),
    _BankSource('Bank of America', 'Savings ••••8834', Icons.account_balance_wallet_rounded, const Color(0xFFE31837)),
    _BankSource('Wells Fargo', 'Checking ••••2267', Icons.corporate_fare_rounded, const Color(0xFFD71E28)),
  ];

  final List<double> _quickAmounts = [50, 100, 250, 500, 1000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }
    if (amount > 50000) {
      setState(() => _errorMessage = 'Maximum deposit is \$50,000.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final idToken = PbService.instance.authToken;
      if (idToken == null) {
        setState(() { _errorMessage = 'Session expired. Please sign in again.'; _isLoading = false; });
        return;
      }

      final response = await http.post(
        Uri.parse(_kDepositUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
        body: jsonEncode({'amount': amount, 'source': _sources[_selectedSource].displayName}),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() { _depositedAmount = amount; _showSuccess = true; });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _errorMessage = data['error'] as String? ?? 'Deposit failed. Please try again.'; });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not reach server. Check your connection.');
    } finally {
      if (mounted && !_showSuccess) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return _buildSuccessScreen();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(),
                        const SizedBox(height: 16),
                      ],
                      // Amount input
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text('DEPOSIT AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant.withOpacity(0.5), letterSpacing: 2)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Text('\$', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.success)),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: -2, height: 1),
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(color: AppColors.surfaceContainerHigh, fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -2),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (_) => setState(() => _errorMessage = null),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quick amount buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quickAmounts.map((amt) => GestureDetector(
                            onTap: () => setState(() { _amountController.text = amt.toStringAsFixed(0); _errorMessage = null; }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('\$${amt.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('FROM ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant.withOpacity(0.5), letterSpacing: 2)),
                      const SizedBox(height: 12),
                      ..._sources.asMap().entries.map((entry) => _buildSourceCard(entry.key, entry.value)),
                      const SizedBox(height: 28),
                      // Deposit button
                      GestureDetector(
                        onTap: _isLoading ? null : _handleDeposit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _isLoading ? null : const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C97A)]),
                            color: _isLoading ? AppColors.surfaceContainerHigh : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_circle_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Add Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard(int index, _BankSource source) {
    final isSelected = _selectedSource == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSource = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerLow : AppColors.surfaceContainerLow.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer.withOpacity(0.6) : AppColors.outlineVariant.withOpacity(0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: source.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(source.icon, color: source.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source.name, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(source.subtitle, style: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryContainer, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: -0.5)),
              Text('Deposit to your account', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C97A)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('Deposit Successful!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text('\$${_depositedAmount.toStringAsFixed(2)} added to your account', style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _BankSource {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  String get displayName => '$name $subtitle';
  const _BankSource(this.name, this.subtitle, this.icon, this.color);
}
