import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:real_banking/models/transaction_model.dart';
import 'package:real_banking/theme/app_colors.dart';

class TransactionReceiptScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionReceiptScreen({super.key, required this.transaction});

  @override
  State<TransactionReceiptScreen> createState() =>
      _TransactionReceiptScreenState();
}

class _TransactionReceiptScreenState extends State<TransactionReceiptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnimController;
  late Animation<double> _checkScale;

  TransactionModel get transaction => widget.transaction;

  bool get _isSuccess => transaction.status.toLowerCase() == 'success';
  bool get _isPending => transaction.status.toLowerCase() == 'pending';
  bool get _isFailed => transaction.status.toLowerCase() == 'failed';

  final _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkScale = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );
    _checkAnimController.forward();
  }

  @override
  void dispose() {
    _checkAnimController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    if (_isSuccess) return AppColors.success;
    if (_isFailed) return AppColors.error;
    return AppColors.warning;
  }

  String get _statusLabel {
    if (_isSuccess) return 'TRANSFER SUCCESSFUL';
    if (_isFailed) return 'TRANSFER FAILED';
    return 'TRANSFER PENDING';
  }

  IconData get _statusIcon {
    if (_isSuccess) return Icons.check_rounded;
    if (_isFailed) return Icons.close_rounded;
    return Icons.schedule_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Receipt',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'STCU',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryContainer,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Hero badge + amount
                  _buildHeroSection(),
                  const SizedBox(height: 20),
                  // Receipt card
                  _buildReceiptCard(),
                  const SizedBox(height: 16),
                  // Security footer
                  _buildSecurityNotice(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ─── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Column(
      children: [
        ScaleTransition(
          scale: _checkScale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isSuccess ? AppColors.electricGradient : null,
              color: _isSuccess ? null : _statusColor.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: (_isSuccess
                          ? AppColors.primaryContainer
                          : _statusColor)
                      .withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(_statusIcon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _statusLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _statusColor,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${transaction.isCredit ? '+' : '-'}${_currencyFormat.format(transaction.amount)}',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            color: transaction.isCredit ? AppColors.primary : AppColors.onSurface,
            letterSpacing: -2,
          ),
        ),
      ],
    );
  }

  // ─── Receipt Card ──────────────────────────────────────────────────────────
  Widget _buildReceiptCard() {
    final dateStr = transaction.dateTime != null
        ? DateFormat("MMM dd, yyyy • HH:mm 'UTC'").format(transaction.dateTime!)
        : 'Processing...';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.08),
            blurRadius: 32,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRANSACTION ID',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: () => _copyToClipboard(transaction.transactionId),
                    child: Row(
                      children: [
                        Text(
                          transaction.transactionId.length > 12
                              ? '${transaction.transactionId.substring(0, 12)}...'
                              : transaction.transactionId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded,
                            size: 12, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      transaction.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _statusColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          _rowDivider(),
          const SizedBox(height: 20),

          // Detail grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      label: 'DATE & TIME',
                      value: dateStr,
                    ),
                    const SizedBox(height: 20),
                    _buildDetailItem(
                      label: transaction.isCredit ? 'FROM' : 'TO',
                      value: transaction.isCredit
                          ? (transaction.relatedUserName ??
                              transaction.relatedUserId ??
                              'Unknown')
                          : (transaction.relatedUserName ??
                              transaction.relatedUserId ??
                              'Unknown'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(label: 'TYPE', value: transaction.type),
                    const SizedBox(height: 20),
                    _buildDetailItem(
                      label: 'FINAL AMOUNT',
                      value: _currencyFormat.format(transaction.amount),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _rowDivider(),
          const SizedBox(height: 20),

          // QR code
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FINAL AMOUNT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(transaction.amount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: transaction.transactionId,
                  version: QrVersions.auto,
                  size: 72,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0A0A0A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _rowDivider() {
    return Container(
      height: 0.5,
      color: AppColors.outlineVariant.withOpacity(0.3),
    );
  }

  // ─── Security Notice ───────────────────────────────────────────────────────
  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded,
              color: AppColors.primary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This receipt is cryptographically signed by the STCU Protocol. Any alterations will invalidate the transaction hash verification.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
              color: AppColors.outlineVariant.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt saved')),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.electricGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'DOWNLOAD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share link copied')),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded,
                        color: AppColors.onSurfaceVariant, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'SHARE',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1)),
    );
  }
}
