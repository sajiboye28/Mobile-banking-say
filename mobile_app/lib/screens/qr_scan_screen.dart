import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:real_banking/screens/send_money_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  final String senderUid;

  const QrScanScreen({super.key, required this.senderUid});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── QR result handling ────────────────────────────────────────────────────

  void _handleScannedData(String rawData) {
    if (_scanned) return;
    setState(() => _scanned = true);

    // Try to parse as payment JSON
    try {
      final data = jsonDecode(rawData);
      if (data is Map) {
        final name = data['name']?.toString();
        final accountNumber = data['accountNumber']?.toString();
        final bank = data['bank']?.toString();
        final amountRaw = data['amount'];

        // Legacy nexusbanking format (uid-based)
        final uid = data['uid']?.toString();

        if ((name != null && accountNumber != null) || uid != null) {
          final double? amount = amountRaw != null
              ? double.tryParse(amountRaw.toString())
              : null;
          _showPaymentReadySheet(
            recipientUid: uid ?? accountNumber ?? '',
            recipientName: name ?? 'Unknown',
            bank: bank ?? 'STCU',
            accountNumber: accountNumber,
            amount: amount,
          );
          return;
        }
      }
    } catch (_) {
      // not JSON — fall through
    }

    // Raw text fallback
    _showRawTextDialog(rawData);
  }

  void _showRawTextDialog(String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'QR Code Content',
          style: TextStyle(
              color: AppColors.onSurface, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(
                    color: AppColors.onSurface, fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Copied to clipboard'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: const Text('Copy',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant.withOpacity(0.7))),
          ),
        ],
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _scanned = false);
    });
  }

  void _showPaymentReadySheet({
    required String recipientUid,
    required String recipientName,
    required String bank,
    String? accountNumber,
    double? amount,
  }) {
    final amountController = TextEditingController(
      text: amount != null ? amount.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),

              // Success icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.success, size: 32),
              ),
              const SizedBox(height: 14),

              const Text(
                'Payment Ready',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review details before sending',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Recipient card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      icon: Icons.person_rounded,
                      label: 'Recipient',
                      value: recipientName,
                    ),
                    if (accountNumber != null) ...[
                      const SizedBox(height: 12),
                      _infoRow(
                        icon: Icons.credit_card_rounded,
                        label: 'Account',
                        value: accountNumber.length > 4
                            ? '••••${accountNumber.substring(accountNumber.length - 4)}'
                            : accountNumber,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _infoRow(
                      icon: Icons.account_balance_rounded,
                      label: 'Bank',
                      value: bank,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Amount field
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                        color: AppColors.onSurface.withOpacity(0.25),
                        fontSize: 28,
                        fontWeight: FontWeight.w900),
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(
                        color: AppColors.success,
                        fontSize: 28,
                        fontWeight: FontWeight.w900),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Send button
              GestureDetector(
                onTap: () {
                  final amt = double.tryParse(amountController.text) ?? 0;
                  if (amt <= 0) {
                    ScaffoldMessenger.of(sheetCtx).showSnackBar(SnackBar(
                      content: const Text('Enter a valid amount'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                    return;
                  }
                  Navigator.pop(sheetCtx); // close sheet
                  Navigator.pop(context); // close scan screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendMoneyScreen(
                        senderUid: widget.senderUid,
                        initialRecipientUid: recipientUid,
                        initialRecipientName: recipientName,
                        initialAmount: amt,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.electricGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Send Money',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _scanned = false);
    });
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.onSurfaceVariant, size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
              color: AppColors.onSurfaceVariant, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.onSurface, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  kIsWeb ? _buildWebPlaceholder() : _buildScannerView(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Web placeholder ───────────────────────────────────────────────────────

  Widget _buildWebPlaceholder() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Mock QR frame with animated scan line
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.surfaceContainerHigh),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(
                            0.06 + _scanLineAnimation.value * 0.1),
                        blurRadius:
                            16 + _scanLineAnimation.value * 16,
                        spreadRadius: _scanLineAnimation.value * 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Corner markers
                      ..._buildCorners(280),

                      // Scan line
                      Positioned(
                        top: 20 + (_scanLineAnimation.value * 230),
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primaryContainer
                                    .withOpacity(0.8),
                                AppColors.primaryContainer,
                                AppColors.primaryContainer
                                    .withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer
                                    .withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Center icon
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 72,
                              color: AppColors.onSurfaceVariant
                                  .withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Camera unavailable',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant
                                    .withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Heading
            const Text(
              'Scan with mobile app',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'QR code scanning requires a device camera.\nOpen the STCU app on your phone to pay instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),

            // Instructions cards
            ..._webInstructions.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.surfaceContainerHigh),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.text,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),

            // Demo scan button
            GestureDetector(
              onTap: () {
                _handleScannedData(jsonEncode({
                  'name': 'Demo Recipient',
                  'accountNumber': 'ACCT123456',
                  'bank': 'STCU',
                  'amount': '50.00',
                }));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primaryContainer.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Try Demo Scan',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static const _webInstructions = [
    _WebInstruction(
      icon: Icons.phone_android_rounded,
      text: 'Open the STCU Banking app on your mobile device',
    ),
    _WebInstruction(
      icon: Icons.qr_code_rounded,
      text: 'Tap "Scan QR" and point your camera at the recipient\'s code',
    ),
    _WebInstruction(
      icon: Icons.send_rounded,
      text: 'Confirm the recipient and amount, then send instantly',
    ),
  ];

  // ── Corner decorations ────────────────────────────────────────────────────

  List<Widget> _buildCorners(double size) {
    const cornerLength = 28.0;
    const cornerWidth = 3.0;
    const offset = 16.0;

    return [
      Positioned(
          top: offset,
          left: offset,
          child: Container(
              width: cornerLength,
              height: cornerWidth,
              color: AppColors.primaryContainer)),
      Positioned(
          top: offset,
          left: offset,
          child: Container(
              width: cornerWidth,
              height: cornerLength,
              color: AppColors.primaryContainer)),
      Positioned(
          top: offset,
          right: offset,
          child: Container(
              width: cornerLength,
              height: cornerWidth,
              color: AppColors.primaryContainer)),
      Positioned(
          top: offset,
          right: offset,
          child: Container(
              width: cornerWidth,
              height: cornerLength,
              color: AppColors.primaryContainer)),
      Positioned(
          bottom: offset,
          left: offset,
          child: Container(
              width: cornerLength,
              height: cornerWidth,
              color: AppColors.primaryContainer)),
      Positioned(
          bottom: offset,
          left: offset,
          child: Container(
              width: cornerWidth,
              height: cornerLength,
              color: AppColors.primaryContainer)),
      Positioned(
          bottom: offset,
          right: offset,
          child: Container(
              width: cornerLength,
              height: cornerWidth,
              color: AppColors.primaryContainer)),
      Positioned(
          bottom: offset,
          right: offset,
          child: Container(
              width: cornerWidth,
              height: cornerLength,
              color: AppColors.primaryContainer)),
    ];
  }

  // ── Native scanner view ───────────────────────────────────────────────────

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            for (final barcode in capture.barcodes) {
              if (barcode.rawValue != null) {
                _handleScannedData(barcode.rawValue!);
                return;
              }
            }
          },
        ),
        // Dark vignette overlay
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.7,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),
        // Scan frame
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  children: [
                    ..._buildCorners(260),
                    // Animated scan line
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, _) {
                        return Positioned(
                          top: 16 + (_scanLineAnimation.value * 220),
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.primaryContainer
                                      .withOpacity(0.85),
                                  AppColors.primaryContainer,
                                  AppColors.primaryContainer
                                      .withOpacity(0.85),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Point camera at a QR code',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _WebInstruction {
  final IconData icon;
  final String text;

  const _WebInstruction({required this.icon, required this.text});
}
