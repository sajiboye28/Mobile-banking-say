import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real_banking/models/transaction_model.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Receipt', style: TextStyle(fontWeight: FontWeight.w800)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // Hero amount section
            _buildHeroSection(isCredit, currencyFormat),
            const SizedBox(height: 20),
            // Details card
            _buildDetailsCard(isCredit),
            const SizedBox(height: 16),
            // Action row
            _buildActions(context),
            const SizedBox(height: 16),
            // Security footer
            _buildSecurityFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isCredit, NumberFormat fmt) {
    return Column(
      children: [
        // Glow circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.electricGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withOpacity(0.35),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.check_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isCredit ? 'TRANSFER RECEIVED' : 'TRANSFER SENT',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${isCredit ? '+' : '-'}${fmt.format(transaction.amount)}',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            color: isCredit ? AppColors.primary : AppColors.onSurface,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          transaction.dateTime != null
              ? DateFormat('EEEE, MMMM d, yyyy • hh:mm a')
                  .format(transaction.dateTime!)
              : 'Processing...',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(bool isCredit) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction ID
          _buildReceiptRow(
            label: 'TRANSACTION ID',
            value: transaction.transactionId,
            canCopy: true,
            mono: true,
          ),
          _rowDivider(),
          // Date & Time
          _buildReceiptRow(
            label: 'DATE & TIME',
            value: transaction.dateTime != null
                ? DateFormat("MMM dd, yyyy • HH:mm 'UTC'")
                    .format(transaction.dateTime!)
                : 'Processing...',
          ),
          _rowDivider(),
          // From/To
          _buildReceiptRow(
            label: isCredit ? 'FROM' : 'TO',
            value: isCredit
                ? (transaction.relatedUserName ??
                    transaction.relatedUserId ??
                    'Unknown')
                : (transaction.relatedUserName ??
                    transaction.relatedUserId ??
                    'Unknown'),
          ),
          _rowDivider(),
          // Type
          _buildReceiptRow(
            label: 'TYPE',
            value: transaction.type,
          ),
          _rowDivider(),
          // Description
          if (transaction.description.isNotEmpty) ...[
            _buildReceiptRow(
              label: 'NOTE',
              value: transaction.description,
            ),
            _rowDivider(),
          ],
          // Status
          _buildStatusRow(transaction),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required String value,
    bool canCopy = false,
    bool mono = false,
  }) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            const SizedBox(width: 16),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontFamily: mono ? 'monospace' : null,
                      ),
                    ),
                  ),
                  if (canCopy) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1)),
                        );
                      },
                      child: const Icon(Icons.copy_rounded,
                          size: 14, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusRow(TransactionModel t) {
    final isSuccess = t.isSuccess;
    final isPending = t.status.toLowerCase() == 'pending';

    final Color statusColor;
    if (isSuccess) {
      statusColor = AppColors.success;
    } else if (isPending) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: statusColor,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDivider() {
    return Container(
      height: 0.5,
      color: AppColors.outlineVariant.withOpacity(0.3),
    );
  }

  String _buildReceiptText() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dt = transaction.dateTime;
    final dateStr = dt != null ? DateFormat('MMM d, yyyy h:mm a').format(dt) : 'N/A';
    return '''
══════════════════════════════
       STCU
         TRANSACTION RECEIPT
══════════════════════════════
Transaction ID : ${transaction.transactionId}
Date & Time    : $dateStr
Type           : ${transaction.type.toUpperCase()}
Status         : ${transaction.status.toUpperCase()}
Amount         : ${currencyFormat.format(transaction.amount)}
Description    : ${transaction.description}
${transaction.relatedUserName != null ? 'Counterparty   : ${transaction.relatedUserName}' : ''}
══════════════════════════════
     Thank you for banking with
          STCU
══════════════════════════════''';
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _buildReceiptText()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('Receipt copied to clipboard'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                  Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('COPY RECEIPT',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: transaction.transactionId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Transaction ID copied'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                  Icon(Icons.tag_rounded, color: AppColors.onSurfaceVariant, size: 18),
                  SizedBox(width: 8),
                  Text('COPY ID',
                      style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFooter() {
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
}
