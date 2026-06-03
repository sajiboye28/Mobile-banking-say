import 'dart:math';
import 'package:flutter/material.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardSettingsScreen extends StatefulWidget {
  final String uid;
  final String cardId;

  const CardSettingsScreen({
    super.key,
    required this.uid,
    required this.cardId,
  });

  @override
  State<CardSettingsScreen> createState() => _CardSettingsScreenState();
}

class _CardSettingsScreenState extends State<CardSettingsScreen> {
  RecordModel? _cardRecord;
  bool _cardLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    setState(() => _cardLoading = true);
    try {
      final r = await PbService.instance.pb.collection('virtual_cards').getOne(widget.cardId);
      if (mounted) setState(() { _cardRecord = r; _cardLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _cardLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // PocketBase helpers
  // ---------------------------------------------------------------------------

  Future<void> _updateCardField(String field, dynamic value) async {
    try {
      await PbService.instance.pb.collection('virtual_cards').update(widget.cardId, body: {field: value});
      _loadCard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _generateCardNumber() {
    final random = Random.secure();
    final segments = List.generate(4, (_) {
      return random.nextInt(9000) + 1000;
    });
    return segments.join();
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  Future<void> _showSpendLimitDialog(double currentLimit) async {
    final controller =
        TextEditingController(text: currentLimit.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Spend Limit',
            style: TextStyle(color: AppColors.onSurface)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppColors.onSurface, fontSize: 22),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: const TextStyle(color: AppColors.primaryContainer, fontSize: 22),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child:
                const Text('Save', style: TextStyle(color: AppColors.onSurface)),
          ),
        ],
      ),
    );
    if (result != null) {
      await _updateCardField('spendLimit', result);
    }
  }

  Future<void> _showChangePinDialog() async {
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change PIN',
            style: TextStyle(color: AppColors.onSurface)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pinField(currentPinCtrl, 'Current PIN'),
              const SizedBox(height: 12),
              _pinField(newPinCtrl, 'New PIN'),
              const SizedBox(height: 12),
              _pinField(confirmPinCtrl, 'Confirm New PIN'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                if (newPinCtrl.text != confirmPinCtrl.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('PINs do not match'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                _updateCardField('pin', newPinCtrl.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN changed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child:
                const Text('Update', style: TextStyle(color: AppColors.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _pinField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      obscureText: true,
      maxLength: 4,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.onSurface, letterSpacing: 8),
      validator: (v) =>
          (v == null || v.length != 4) ? 'Enter 4-digit PIN' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        counterText: '',
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _showReplaceCardDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Replace Card',
            style: TextStyle(color: AppColors.onSurface)),
        content: const Text(
          'A new card number will be generated. The current card will be deactivated immediately. Continue?',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Replace', style: TextStyle(color: AppColors.background)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final newNumber = _generateCardNumber();
      final random = Random.secure();
      final newCvv = (random.nextInt(900) + 100).toString();
      await PbService.instance.pb.collection('virtual_cards').update(widget.cardId, body: {
        'cardNumber': newNumber,
        'cvv': newCvv,
      });
      _loadCard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card replaced successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showTerminateDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terminate Digital Card',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
          'This action is irreversible. Your digital card will be permanently deleted. Are you sure?',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Terminate',
                style: TextStyle(color: AppColors.onSurface)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PbService.instance.pb.collection('virtual_cards').delete(widget.cardId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card terminated'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showReportLostDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('Report Lost', style: TextStyle(color: AppColors.warning)),
        content: const Text(
          'Your card will be frozen immediately and flagged as lost. You can request a replacement afterwards.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Report',
                style: TextStyle(color: AppColors.background)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PbService.instance.pb.collection('virtual_cards').update(widget.cardId, body: {
        'isFrozen': true,
        'reportedLost': true,
      });
      _loadCard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card reported lost and frozen'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Card Settings',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Builder(builder: (context) {
        if (_cardLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryContainer),
          );
        }
        if (_cardRecord == null) {
          return const Center(
            child: Text('Card not found',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16)),
          );
        }
        {
          final data = _cardRecord!.data;
          final cardNumber = data['cardNumber'] as String? ?? '';
          final last4 =
              cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : '----';
          final isFrozen = data['isFrozen'] as bool? ?? false;
          final cardholderName = data['cardholderName'] as String? ?? '';
          final expiryMonth = data['expiryMonth'] as int? ?? 1;
          final expiryYear = data['expiryYear'] as int? ?? 2028;
          final expiry =
              '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';

          // Spending controls
          final spendLimit = (data['spendLimit'] as num?)?.toDouble() ?? 12500;
          final dailyTxnLimit =
              (data['dailyTransactionLimit'] as num?)?.toDouble() ?? 5000;
          final atmLimit =
              (data['atmWithdrawalLimit'] as num?)?.toDouble() ?? 2000;

          // Security toggles
          final contactless = data['contactlessPayments'] as bool? ?? true;
          final onlineTxn = data['onlineTransactions'] as bool? ?? true;
          final international = data['internationalUsage'] as bool? ?? false;
          final atmWithdrawals = data['atmWithdrawalsEnabled'] as bool? ?? true;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1 - Card Preview
                _buildCardPreview(
                    last4, isFrozen, cardholderName, expiry),
                const SizedBox(height: 24),

                // 2 - Quick Actions
                _buildQuickActions(isFrozen),
                const SizedBox(height: 28),

                // 3 - Spending Controls
                _buildSectionTitle('Spending Controls'),
                const SizedBox(height: 12),
                _buildSpendingControls(spendLimit, dailyTxnLimit, atmLimit),
                const SizedBox(height: 28),

                // 4 - Security Features
                _buildSectionTitle('Security Features'),
                const SizedBox(height: 12),
                _buildSecurityToggles(
                    contactless, onlineTxn, international, atmWithdrawals),
                const SizedBox(height: 28),

                // 5 - Card Actions
                _buildSectionTitle('Card Actions'),
                const SizedBox(height: 12),
                _buildCardActions(),
                const SizedBox(height: 28),

                // 6 - Premium Concierge
                _buildPremiumConcierge(),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Card Preview
  // ---------------------------------------------------------------------------

  Widget _buildCardPreview(
      String last4, bool isFrozen, String name, String expiry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surfaceContainerLow, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryContainer.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OBSIDIAN TIER',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              _statusBadge(isFrozen),
            ],
          ),
          const SizedBox(height: 28),
          // Card number (masked)
          Text(
            '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  $last4',
            style: TextStyle(
              color: AppColors.onSurface.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARD HOLDER',
                      style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 9,
                          letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EXPIRES',
                      style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 9,
                          letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    expiry,
                    style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isFrozen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFrozen
            ? AppColors.warning.withOpacity(0.15)
            : AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFrozen
              ? AppColors.warning.withOpacity(0.4)
              : AppColors.success.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFrozen ? Icons.ac_unit : Icons.check_circle_outline,
            color: isFrozen ? AppColors.warning : AppColors.success,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isFrozen ? 'Frozen' : 'Active',
            style: TextStyle(
              color: isFrozen ? AppColors.warning : AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Quick Actions Row
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(bool isFrozen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _quickActionButton(
          icon: Icons.ac_unit,
          label: isFrozen ? 'Unfreeze' : 'Freeze',
          color: isFrozen ? AppColors.success : AppColors.primaryContainer,
          onTap: () => _updateCardField('isFrozen', !isFrozen),
        ),
        _quickActionButton(
          icon: Icons.warning_amber_rounded,
          label: 'Report Lost',
          color: AppColors.warning,
          onTap: _showReportLostDialog,
        ),
        _quickActionButton(
          icon: Icons.lock_outline,
          label: 'PIN Change',
          color: AppColors.primaryContainer,
          onTap: _showChangePinDialog,
        ),
      ],
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Spending Controls
  // ---------------------------------------------------------------------------

  Widget _buildSpendingControls(
      double spendLimit, double dailyLimit, double atmLimit) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          _spendingTile(
            icon: Icons.credit_card,
            title: 'Spend Limit',
            value: '\$${_formatAmount(spendLimit)}',
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryContainer, size: 18),
              onPressed: () => _showSpendLimitDialog(spendLimit),
            ),
          ),
          const Divider(color: AppColors.outlineVariant, height: 1, indent: 56),
          _spendingTile(
            icon: Icons.swap_horiz,
            title: 'Daily Transaction Limit',
            value: '\$${_formatAmount(dailyLimit)}',
          ),
          const Divider(color: AppColors.outlineVariant, height: 1, indent: 56),
          _spendingTile(
            icon: Icons.atm,
            title: 'ATM Withdrawal Limit',
            value: '\$${_formatAmount(atmLimit)}',
          ),
        ],
      ),
    );
  }

  Widget _spendingTile({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      final s = amount.toStringAsFixed(0);
      final buffer = StringBuffer();
      int count = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        buffer.write(s[i]);
        count++;
        if (count % 3 == 0 && i != 0) buffer.write(',');
      }
      return buffer.toString().split('').reversed.join();
    }
    return amount.toStringAsFixed(0);
  }

  // ---------------------------------------------------------------------------
  // 4. Security Features
  // ---------------------------------------------------------------------------

  Widget _buildSecurityToggles(
      bool contactless, bool online, bool international, bool atm) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          _securityToggle(
            icon: Icons.contactless_outlined,
            title: 'Contactless Payments',
            value: contactless,
            field: 'contactlessPayments',
          ),
          const Divider(color: AppColors.outlineVariant, height: 1, indent: 56),
          _securityToggle(
            icon: Icons.language,
            title: 'Online Transactions',
            value: online,
            field: 'onlineTransactions',
          ),
          const Divider(color: AppColors.outlineVariant, height: 1, indent: 56),
          _securityToggle(
            icon: Icons.flight_takeoff,
            title: 'International Usage',
            value: international,
            field: 'internationalUsage',
          ),
          const Divider(color: AppColors.outlineVariant, height: 1, indent: 56),
          _securityToggle(
            icon: Icons.atm,
            title: 'ATM Withdrawals',
            value: atm,
            field: 'atmWithdrawalsEnabled',
          ),
        ],
      ),
    );
  }

  Widget _securityToggle({
    required IconData icon,
    required String title,
    required bool value,
    required String field,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.success,
            activeTrackColor: AppColors.success.withOpacity(0.35),
            inactiveThumbColor: AppColors.onSurfaceVariant,
            inactiveTrackColor: AppColors.outlineVariant,
            onChanged: (v) => _updateCardField(field, v),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Card Actions
  // ---------------------------------------------------------------------------

  Widget _buildCardActions() {
    return Column(
      children: [
        _actionButton(
          icon: Icons.sync,
          label: 'Replace Card',
          color: AppColors.warning,
          onTap: _showReplaceCardDialog,
        ),
        const SizedBox(height: 10),
        _actionButton(
          icon: Icons.lock_reset,
          label: 'Change PIN',
          color: AppColors.primaryContainer,
          onTap: _showChangePinDialog,
        ),
        const SizedBox(height: 10),
        _actionButton(
          icon: Icons.delete_forever_outlined,
          label: 'Terminate Digital Card',
          color: AppColors.error,
          onTap: _showTerminateDialog,
          destructive: true,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return Material(
      color: destructive ? AppColors.error.withOpacity(0.08) : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: destructive ? AppColors.error.withOpacity(0.3) : AppColors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: destructive ? AppColors.error : AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: destructive ? AppColors.error.withOpacity(0.5) : AppColors.onSurfaceVariant,
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Premium Concierge
  // ---------------------------------------------------------------------------

  Widget _buildPremiumConcierge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.25),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.diamond_outlined,
                    color: AppColors.onSurface, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Concierge',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Unlock exclusive perks & priority support',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: AppColors.primaryContainer,
                  ),
                );
              },
              child: const Text(
                'Upgrade Now',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section title helper
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
