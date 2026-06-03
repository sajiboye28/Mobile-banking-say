import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:real_banking/screens/send_money_screen.dart';
import 'package:real_banking/services/pb_service.dart';

class RequestMoneyScreen extends StatefulWidget {
  final String uid;
  const RequestMoneyScreen({super.key, required this.uid});

  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;
  int _expiryDays = 3; // default expiry

  static const List<int> _expiryOptions = [1, 3, 7];

  @override
  void dispose() {
    _emailController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Send request to Firestore ──────────────────────────────────────────────
  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final toEmail = _emailController.text.trim();
      final amount = double.parse(_amountController.text.trim());
      final note = _noteController.text.trim();

      // Get sender info
      final pb = PbService.instance.pb;
      final senderRecord = await pb.collection('users').getOne(widget.uid);
      final senderData = senderRecord.data;
      final fromEmail = senderData['email'] as String? ?? '';

      if (toEmail.toLowerCase() == fromEmail.toLowerCase()) {
        setState(() {
          _error = 'You cannot request money from yourself.';
          _isLoading = false;
        });
        return;
      }

      final expiresAt = DateTime.now().add(Duration(days: _expiryDays));

      await pb.collection('payment_requests').create(body: {
        'fromUserId': widget.uid,
        'fromEmail': fromEmail,
        'fromName': senderData['fullName'] ?? '',
        'toEmail': toEmail,
        'amount': amount,
        'currency': 'USD',
        'note': note,
        'status': 'pending',
        'expiresAt': expiresAt.toIso8601String(),
      });

      if (mounted) {
        _emailController.clear();
        _amountController.clear();
        _noteController.clear();
        setState(() => _expiryDays = 3);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment request sent!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to send request. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Update request status ──────────────────────────────────────────────────
  Future<void> _updateStatus(String docId, String status) async {
    await PbService.instance.pb.collection('payment_requests').update(docId, body: {
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    final payLink = 'nexusbank.app/pay/${widget.uid.substring(0, 8)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: const Text('Request Money', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Request Form ───────────────────────────────────────────────
            _sectionTitle('Create Payment Request'),
            const SizedBox(height: 16),
            _requestForm(),
            const SizedBox(height: 32),

            // ── Pending Requests ───────────────────────────────────────────
            _sectionTitle('Pending Requests'),
            const SizedBox(height: 16),
            _pendingRequestsList(),
            const SizedBox(height: 32),

            // ── Generate Payment Link ──────────────────────────────────────
            _sectionTitle('Payment Link'),
            const SizedBox(height: 16),
            _paymentLinkCard(payLink),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Request Form ────────────────────────────────────────────────────────────
  Widget _requestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Request From email
          _fieldLabel('Request From'),
          _textField(
            controller: _emailController,
            hint: 'recipient@example.com',
            icon: Icons.person_search_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Amount
          _fieldLabel('Amount (USD)'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Row(
              children: [
                Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: AppColors.surfaceContainerHigh),
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter amount';
                      final a = double.tryParse(v.trim());
                      if (a == null || a <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryContainer.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'USD',
                    style: TextStyle(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Note / Reason
          _fieldLabel('Note / Reason'),
          _textField(
            controller: _noteController,
            hint: 'e.g. For dinner last night',
            icon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Expiry
          _fieldLabel('Request valid for'),
          const SizedBox(height: 8),
          Row(
            children: _expiryOptions.map((days) {
              final selected = _expiryDays == days;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _expiryDays = days),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryContainer.withOpacity(0.18)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainerHigh,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      days == 1 ? '1 day' : '$days days',
                      style: TextStyle(
                        color: selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Send Request button
          _gradientButton('Send Request', _isLoading, _sendRequest),
        ],
      ),
    );
  }

  // ── Pending Requests stream ─────────────────────────────────────────────────
  Widget _pendingRequestsList() {
    final currentEmail = PbService.instance.currentUser?.data['email'] as String? ?? '';
    return FutureBuilder<List<RecordModel>>(
      future: () async {
        final pb = PbService.instance.pb;
        final futures = <Future<List<RecordModel>>>[
          pb.collection('payment_requests').getFullList(
            filter: 'fromUserId="${widget.uid}"',
            sort: '-created',
          ),
        ];
        if (currentEmail.isNotEmpty) {
          futures.add(pb.collection('payment_requests').getFullList(
            filter: 'toEmail="$currentEmail"',
            sort: '-created',
          ));
        }
        final results = await Future.wait(futures);
        return results.expand((l) => l).toList();
      }(),
      builder: (context, snapshot) {
        final List<_RequestItem> items = [];
        if (snapshot.hasData) {
          final seen = <String>{};
          for (final doc in snapshot.data!) {
            if (seen.contains(doc.id)) continue;
            seen.add(doc.id);
            final data = doc.data;
            final isSentByMe = data['fromUserId'] == widget.uid;
            items.add(_RequestItem(id: doc.id, data: data, isSentByMe: isSentByMe));
          }
        }

        items.sort((a, b) {
          final aT = a.data['created'] as String?;
          final bT = b.data['created'] as String?;
          if (aT == null) return 1;
          if (bT == null) return -1;
          return bT.compareTo(aT);
        });

            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.request_page_outlined, size: 40, color: AppColors.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'No payment requests yet',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _requestTile(item),
                      ))
                  .toList(),
            );
          },
        );
  }

  Widget _requestTile(_RequestItem item) {
    final data = item.data;
    final status = data['status'] as String? ?? 'pending';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'paid':
        statusColor = AppColors.success;
        break;
      case 'declined':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.grey;
    }

    final createdStr = data['created'] as String? ?? data['createdAt'] as String? ?? '';
    final createdDt = createdStr.isNotEmpty ? DateTime.tryParse(createdStr) : null;
    final dateStr = createdDt != null ? DateFormat('MMM d, yyyy').format(createdDt) : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.isSentByMe
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.isSentByMe
                          ? '${currencyFmt.format(amount)} requested from ${data['toEmail'] ?? ''}'
                          : '${data['fromName'] ?? data['fromEmail'] ?? ''} requested ${currencyFmt.format(amount)}',
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if ((data['note'] as String? ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          data['note'] as String,
                          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ),
                    if (dateStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          dateStr,
                          style: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.6), fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Action buttons
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (item.isSentByMe)
                  // Cancel button for outgoing
                  Expanded(
                    child: _outlineButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      color: AppColors.error,
                      onTap: () => _updateStatus(item.id, 'cancelled'),
                    ),
                  ),
                if (!item.isSentByMe) ...[
                  // Pay Now for incoming
                  Expanded(
                    child: _solidButton(
                      label: 'Pay Now',
                      icon: Icons.send_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendMoneyScreen(
                              senderUid: widget.uid,
                              initialAmount: amount,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Decline for incoming
                  Expanded(
                    child: _outlineButton(
                      label: 'Decline',
                      icon: Icons.thumb_down_outlined,
                      color: AppColors.error,
                      onTap: () => _updateStatus(item.id, 'declined'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Payment link card ───────────────────────────────────────────────────────
  Widget _paymentLinkCard(String payLink) {
    final fullUrl = 'https://$payLink';
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
          Row(
            children: [
              const Icon(Icons.link_rounded, color: AppColors.primaryContainer, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Payment Link',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // URL display + copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBright),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    payLink,
                    style: const TextStyle(
                      color: AppColors.primaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: fullUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Payment link copied!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryContainer.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.copy_rounded, color: AppColors.primaryContainer, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            color: AppColors.primaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // QR code centered
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: fullUrl,
                    version: QrVersions.auto,
                    size: 150,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Scan to pay you directly',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.surfaceContainerHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.surfaceContainerHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error.withOpacity(0.6)),
        ),
      ),
    );
  }

  Widget _gradientButton(String label, bool loading, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppColors.electricGradient,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: loading ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onSurface),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _solidButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.electricGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.onSurface, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal data model ────────────────────────────────────────────────────────
class _RequestItem {
  final String id;
  final Map<String, dynamic> data;
  final bool isSentByMe;

  const _RequestItem({
    required this.id,
    required this.data,
    required this.isSentByMe,
  });
}
