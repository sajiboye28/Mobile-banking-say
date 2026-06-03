import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class ScheduledPaymentsScreen extends StatefulWidget {
  final String uid;

  const ScheduledPaymentsScreen({super.key, required this.uid});

  @override
  State<ScheduledPaymentsScreen> createState() =>
      _ScheduledPaymentsScreenState();
}

class _ScheduledPaymentsScreenState extends State<ScheduledPaymentsScreen> {
  List<RecordModel>? _records;
  bool _loadingSchedules = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _loadingSchedules = true);
    try {
      final records = await PbService.instance.pb
          .collection('scheduled_payments')
          .getFullList(filter: 'userId="${widget.uid}"', sort: 'nextPaymentDate');
      if (mounted) setState(() { _records = records; _loadingSchedules = false; });
    } catch (_) {
      if (mounted) setState(() { _records = []; _loadingSchedules = false; });
    }
  }

  // ─── Add Schedule Sheet ────────────────────────────────────────────────────

  void _showAddScheduleSheet() {
    final recipientController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String frequency = 'Monthly';
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    bool isLoading = false;

    final frequencies = ['One-time', 'Weekly', 'Every 2 Weeks', 'Monthly'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Text(
                      'Schedule a Payment',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set up automatic recurring or one-time payments.',
                      style: TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Recipient email
                    _sheetField(
                      controller: recipientController,
                      label: 'Recipient Email',
                      hint: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    // Amount
                    _sheetField(
                      controller: amountController,
                      label: 'Amount',
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      prefixText: '\$ ',
                    ),
                    const SizedBox(height: 12),

                    // Frequency dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: frequency,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceContainerHigh,
                          style: const TextStyle(
                              color: AppColors.onSurface, fontSize: 14),
                          icon: const Icon(Icons.expand_more_rounded,
                              color: AppColors.onSurfaceVariant),
                          items: frequencies
                              .map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setSheetState(() => frequency = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Start date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 2)),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primaryContainer,
                                onPrimary: Colors.white,
                                surface: AppColors.surfaceContainerLow,
                                onSurface: AppColors.onSurface,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() => startDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppColors.onSurfaceVariant, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Date',
                                    style: TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11),
                                  ),
                                  Text(
                                    DateFormat('MMMM dd, yyyy').format(startDate),
                                    style: const TextStyle(
                                        color: AppColors.onSurface,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.onSurfaceVariant, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description / memo
                    _sheetField(
                      controller: descriptionController,
                      label: 'Description / Memo (optional)',
                      hint: 'e.g. Monthly rent',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Schedule button
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.electricGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final recipient =
                                      recipientController.text.trim();
                                  final amountStr =
                                      amountController.text.trim();

                                  if (recipient.isEmpty) {
                                    _showSnackBar(
                                        'Please enter a recipient email.',
                                        color: AppColors.error);
                                    return;
                                  }
                                  if (amountStr.isEmpty ||
                                      double.tryParse(amountStr) == null ||
                                      double.parse(amountStr) <= 0) {
                                    _showSnackBar('Please enter a valid amount.',
                                        color: AppColors.error);
                                    return;
                                  }

                                  setSheetState(() => isLoading = true);
                                  try {
                                    await PbService.instance.pb
                                        .collection('scheduled_payments')
                                        .create(body: {
                                      'userId': widget.uid,
                                      'recipientEmail': recipient,
                                      'amount': double.parse(amountStr),
                                      'frequency': frequency,
                                      'nextPaymentDate': startDate.toIso8601String(),
                                      'description':
                                          descriptionController.text.trim(),
                                      'isActive': true,
                                    });
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      _showSnackBar(
                                          'Payment scheduled successfully!');
                                      _loadSchedules();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      _showSnackBar('Error: $e',
                                          color: AppColors.error);
                                    }
                                  } finally {
                                    if (ctx.mounted) {
                                      setSheetState(() => isLoading = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Schedule Payment',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        labelStyle:
            const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
        hintStyle:
            const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
        prefixStyle: const TextStyle(color: AppColors.onSurface, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ─── Pause / Cancel ────────────────────────────────────────────────────────

  Future<void> _togglePause(String docId, bool currentlyActive) async {
    await PbService.instance.pb
        .collection('scheduled_payments')
        .update(docId, body: {'isActive': !currentlyActive});
    if (mounted) {
      _showSnackBar(currentlyActive ? 'Payment paused.' : 'Payment resumed.');
      _loadSchedules();
    }
  }

  void _showCancelConfirmation(String docId, String recipient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text(
              'Cancel Schedule',
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Cancel the scheduled payment to $recipient? This cannot be undone.',
          style: const TextStyle(
              color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await PbService.instance.pb
                  .collection('scheduled_payments')
                  .delete(docId);
              if (mounted) {
                _showSnackBar('Scheduled payment cancelled.',
                    color: AppColors.warning);
                _loadSchedules();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel It',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color ?? AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: const Text(
          'Scheduled Payments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleSheet,
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Schedule',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Builder(builder: (context) {
        if (_loadingSchedules) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.primaryContainer, strokeWidth: 2.5),
          );
        }
        final docs = _records ?? [];
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Header Card ──────────────────────────────────────
                  _buildHeaderCard(docs),
                  const SizedBox(height: 24),

                  if (docs.isEmpty) ...[
                    const SizedBox(height: 60),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.schedule_rounded,
                              color: AppColors.onSurfaceVariant, size: 56),
                          SizedBox(height: 16),
                          Text(
                            'No scheduled payments',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap "Add Schedule" to set up\nautomatic payments.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Your Schedules',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...docs.map((r) => _buildScheduleItem(r.id, r.data)),
                  ],
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderCard(List<RecordModel> docs) {
    final activeCount = docs.where((r) => r.data['isActive'] == true).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.electricGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Schedules',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${docs.length} total schedule${docs.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String docId, Map<String, dynamic> data) {
    final isActive = data['isActive'] as bool? ?? false;
    final frequency = data['frequency'] as String? ?? 'One-time';
    final recipientEmail = data['recipientEmail'] as String? ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final description = data['description'] as String? ?? '';
    final nextPaymentDate = DateTime.tryParse(data['nextPaymentDate'] as String? ?? '');

    // Determine status
    String status;
    Color statusColor;
    Color statusBg;
    if (isActive) {
      status = 'Active';
      statusColor = AppColors.success;
      statusBg = AppColors.success.withOpacity(0.12);
    } else {
      status = 'Paused';
      statusColor = AppColors.warning;
      statusBg = AppColors.warning.withOpacity(0.12);
    }

    Color freqColor;
    switch (frequency) {
      case 'Weekly':
        freqColor = AppColors.primaryContainer;
        break;
      case 'Every 2 Weeks':
        freqColor = AppColors.primary;
        break;
      case 'Monthly':
        freqColor = AppColors.secondary;
        break;
      default:
        freqColor = AppColors.onSurfaceVariant;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipientEmail,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '\$${NumberFormat('#,##0.00').format(amount)}',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Frequency badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: freqColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  frequency,
                  style: TextStyle(
                    color: freqColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (nextPaymentDate != null)
                Text(
                  'Next: ${DateFormat('MMM d').format(nextPaymentDate)}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _togglePause(docId, isActive),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.warning.withOpacity(0.12)
                          : AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color:
                              isActive ? AppColors.warning : AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Pause' : 'Resume',
                          style: TextStyle(
                            color: isActive
                                ? AppColors.warning
                                : AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCancelConfirmation(docId, recipientEmail),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_rounded,
                            color: AppColors.error, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
