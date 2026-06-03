import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:real_banking/theme/app_colors.dart';

class QrGenerateScreen extends StatefulWidget {
  final String uid;
  final String userName;
  final String? accountNumber;

  const QrGenerateScreen({
    super.key,
    required this.uid,
    required this.userName,
    this.accountNumber,
  });

  @override
  State<QrGenerateScreen> createState() => _QrGenerateScreenState();
}

class _QrGenerateScreenState extends State<QrGenerateScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _accountNumber =>
      widget.accountNumber ?? widget.uid.substring(0, 12).toUpperCase();

  String get _maskedAccount {
    final acc = _accountNumber;
    if (acc.length <= 4) return acc;
    return '••••${acc.substring(acc.length - 4)}';
  }

  String get _uidFirst8 => widget.uid.length >= 8
      ? widget.uid.substring(0, 8)
      : widget.uid;

  String get _paymentLink => 'stcu.app/pay/$_uidFirst8';

  String _buildQrData() {
    final payload = <String, dynamic>{
      'name': widget.userName,
      'accountNumber': _accountNumber,
      'bank': 'STCU',
    };
    final amountText = _amountController.text.trim();
    if (amountText.isNotEmpty) {
      final parsed = double.tryParse(amountText);
      if (parsed != null && parsed > 0) {
        payload['amount'] = parsed.toStringAsFixed(2);
      }
    }
    return jsonEncode(payload);
  }

  void _onShareTapped() {
    Clipboard.setData(ClipboardData(text: _paymentLink));
    _showSnack('Payment link copied: $_paymentLink', AppColors.success);
  }

  void _onDownloadTapped() {
    _showSnack(
        'Save a screenshot to share your QR code',
        AppColors.surfaceContainerHighest);
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.onSurface, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Receive Payment',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Bank badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                AppColors.primaryContainer.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.account_balance_rounded,
                              color: AppColors.primary, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'STCU Digital Banking',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Name
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Scan to pay me instantly',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // QR Card with animated glow
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryContainer.withOpacity(
                                        0.12 + _glowAnimation.value * 0.18),
                                blurRadius:
                                    24 + _glowAnimation.value * 20,
                                spreadRadius:
                                    _glowAnimation.value * 4,
                              ),
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(
                                    0.08 + _glowAnimation.value * 0.08),
                                blurRadius:
                                    36 + _glowAnimation.value * 12,
                                spreadRadius:
                                    _glowAnimation.value * 2,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: AppColors.surfaceContainerHigh),
                        ),
                        child: Column(
                          children: [
                            // White QR container
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: _buildQrData(),
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0A0A0A),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape:
                                      QrDataModuleShape.square,
                                  color: Color(0xFF0A0A0A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name under QR
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Masked account
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _maskedAccount,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Bank label
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.verified_rounded,
                                    color: AppColors.success, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'STCU Digital Banking',
                                  style: TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.surfaceContainerHigh),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.attach_money_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Request Specific Amount (Optional)',
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              prefixStyle: const TextStyle(
                                color: AppColors.success,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                  color: AppColors.onSurface
                                      .withOpacity(0.25),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800),
                              border: InputBorder.none,
                            ),
                          ),
                          if (_amountController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'QR encodes this amount — payer can still change it.',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant
                                    .withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.share_rounded,
                            label: 'Share QR',
                            gradient: AppColors.electricGradient,
                            onTap: _onShareTapped,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.download_rounded,
                            label: 'Download QR',
                            gradient: LinearGradient(
                              colors: [
                                AppColors.surfaceContainerHigh,
                                AppColors.surfaceContainerHighest,
                              ],
                            ),
                            labelColor: AppColors.onSurface,
                            onTap: _onDownloadTapped,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment link row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.surfaceContainerHigh),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded,
                              color: AppColors.onSurfaceVariant, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _paymentLink,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _onShareTapped,
                            child: const Icon(Icons.copy_rounded,
                                color: AppColors.onSurfaceVariant, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final Color labelColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.labelColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withOpacity(0.2),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: labelColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
