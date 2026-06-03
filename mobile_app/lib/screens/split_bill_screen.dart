import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class SplitBillScreen extends StatefulWidget {
  final String uid;

  const SplitBillScreen({super.key, required this.uid});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _totalController = TextEditingController();
  final _descController = TextEditingController();

  bool _isCustomSplit = false;
  bool _isSending = false;
  bool _showSuccess = false;
  int _successCount = 0;
  double _successAmount = 0;

  // Participants: index 0 = current user (self)
  final List<_Participant> _participants = [];
  final List<TextEditingController> _customAmountControllers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _isCustomSplit = _tabController.index == 1);
    });
    // Add self as first participant (no email needed, they're excluded from requests)
    _participants.add(_Participant(name: 'You (me)', email: '', isSelf: true));
    _customAmountControllers.add(TextEditingController());
    _totalController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _totalController.dispose();
    _descController.dispose();
    for (final c in _customAmountControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalAmount =>
      double.tryParse(_totalController.text.replaceAll(',', '')) ?? 0;

  double get _equalShare {
    if (_participants.isEmpty) return 0;
    return _totalAmount / _participants.length;
  }

  double get _customTotal {
    double sum = 0;
    for (final c in _customAmountControllers) {
      sum += double.tryParse(c.text) ?? 0;
    }
    return sum;
  }

  void _addParticipant(String name, String email) {
    setState(() {
      _participants.add(_Participant(name: name, email: email, isSelf: false));
      _customAmountControllers.add(TextEditingController());
    });
  }

  void _removeParticipant(int index) {
    if (index == 0) return; // Cannot remove self
    setState(() {
      _participants.removeAt(index);
      _customAmountControllers[index].dispose();
      _customAmountControllers.removeAt(index);
    });
  }

  void _showAddPersonDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Person',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: _inputDecoration('Name', Icons.person_rounded),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailController,
                style: const TextStyle(color: AppColors.onSurface),
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email', Icons.email_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _addParticipant(
                    nameController.text.trim(), emailController.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequests() async {
    if (_totalAmount <= 0) {
      _showSnack('Enter a valid total amount', isError: true);
      return;
    }
    final others =
        _participants.where((p) => !p.isSelf).toList();
    if (others.isEmpty) {
      _showSnack('Add at least one person to split with', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final pb = PbService.instance.pb;
      double sharePerPerson = 0;

      if (!_isCustomSplit) {
        sharePerPerson = _equalShare;
        for (int i = 0; i < _participants.length; i++) {
          final p = _participants[i];
          if (p.isSelf) continue;
          await pb.collection('payment_requests').create(body: {
            'fromUserId': widget.uid,
            'toEmail': p.email,
            'toName': p.name,
            'amount': double.parse(sharePerPerson.toStringAsFixed(2)),
            'note': _descController.text.trim().isEmpty
                ? 'Split bill'
                : '${_descController.text.trim()} (split)',
            'status': 'pending',
          });
        }
      } else {
        // Custom split
        for (int i = 0; i < _participants.length; i++) {
          final p = _participants[i];
          if (p.isSelf) continue;
          final amount =
              double.tryParse(_customAmountControllers[i].text) ?? 0;
          if (amount <= 0) continue;
          sharePerPerson = amount;
          await pb.collection('payment_requests').create(body: {
            'fromUserId': widget.uid,
            'toEmail': p.email,
            'toName': p.name,
            'amount': amount,
            'note': _descController.text.trim().isEmpty
                ? 'Split bill'
                : '${_descController.text.trim()} (split)',
            'status': 'pending',
          });
        }
        sharePerPerson = _customTotal / others.length;
      }

      setState(() {
        _isSending = false;
        _showSuccess = true;
        _successCount = others.length;
        _successAmount = _isCustomSplit ? sharePerPerson : _equalShare;
      });
    } catch (e) {
      setState(() => _isSending = false);
      _showSnack('Error sending requests: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
      filled: true,
      fillColor: AppColors.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
            color: AppColors.primaryContainer, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _showSuccess ? _buildSuccessView() : _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.onSurface, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Split Bill',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Divide expenses with friends',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Total Amount input
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.electricGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL BILL AMOUNT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '\$',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _totalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w300,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _inputDecoration(
                      'Bill description (e.g. Dinner at Marco\'s)',
                      Icons.description_rounded),
                ),
                const SizedBox(height: 24),

                // Participants section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PARTICIPANTS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAddPersonDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_rounded,
                                color: AppColors.primaryContainer, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Add Person',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Participants list
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children:
                        List.generate(_participants.length, (index) {
                      final p = _participants[index];
                      final isFirst = index == 0;
                      final isLast = index == _participants.length - 1;
                      return _buildParticipantRow(
                          p, index, isFirst, isLast);
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Split type tab
                const Text(
                  'SPLIT TYPE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Equal Split'),
                      Tab(text: 'Custom Split'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Split preview
                _isCustomSplit
                    ? _buildCustomSplitView()
                    : _buildEqualSplitPreview(),
                const SizedBox(height: 24),

                // Split & Request button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendRequests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primaryContainer.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Split & Request',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Recent Splits
                _buildRecentSplitsSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantRow(
      _Participant p, int index, bool isFirst, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : const Border(
                top: BorderSide(
                    color: AppColors.outlineVariant, width: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.isSelf
                  ? AppColors.primaryContainer.withOpacity(0.15)
                  : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.isSelf
                      ? AppColors.primaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (p.email.isNotEmpty)
                  Text(
                    p.email,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (!p.isSelf)
            GestureDetector(
              onTap: () => _removeParticipant(index),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.error, size: 15),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEqualSplitPreview() {
    final share = _equalShare;
    final count = _participants.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Each person pays',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '\$${share.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Split between',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'person' : 'people'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          if (_totalAmount > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.outlineVariant, height: 1),
            const SizedBox(height: 12),
            ...List.generate(_participants.length, (i) {
              final p = _participants[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: p.isSelf
                                ? AppColors.success
                                : AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${share.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomSplitView() {
    final remaining = _totalAmount - _customTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Remaining to allocate',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '\$${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: remaining < 0
                      ? AppColors.error
                      : remaining == 0
                          ? AppColors.success
                          : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_participants.length, (i) {
            final p = _participants[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: p.isSelf
                          ? AppColors.primaryContainer.withOpacity(0.15)
                          : AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: p.isSelf
                              ? AppColors.primaryContainer
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _customAmountControllers[i],
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        prefixText: '\$',
                        prefixStyle: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        hintText: '0.00',
                        hintStyle: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primaryContainer, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Requests Sent!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Requests sent to $_successCount ${_successCount == 1 ? 'person' : 'people'} for \$${_successAmount.toStringAsFixed(2)} each',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _showSuccess = false;
                _totalController.clear();
                _descController.clear();
                // Reset to just self
                while (_participants.length > 1) {
                  _customAmountControllers.last.dispose();
                  _customAmountControllers.removeLast();
                  _participants.removeLast();
                }
                _customAmountControllers[0].clear();
              }),
              child: const Text(
                'Split another bill',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSplitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT SPLITS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<RecordModel>>(
          future: PbService.instance.pb
              .collection('payment_requests')
              .getFullList(
                filter: 'fromUserId="${widget.uid}"',
                sort: '-created',
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryContainer,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No recent splits',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            // Filter: note contains 'split'
            final docs = snapshot.data!.where((r) {
              final note = (r.data['note'] ?? '').toString().toLowerCase();
              return note.contains('split');
            }).take(5).toList();

            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No recent splits',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: docs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  final data = r.data;
                  final isFirst = idx == 0;
                  final toName = data['toName'] ?? data['toEmail'] ?? 'Unknown';
                  final amount = (data['amount'] ?? 0).toDouble();
                  final note = data['note'] ?? '';
                  final status = data['status'] ?? 'pending';

                  return Container(
                    decoration: BoxDecoration(
                      border: isFirst
                          ? null
                          : const Border(
                              top: BorderSide(
                                  color: AppColors.outlineVariant,
                                  width: 0.15)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group_rounded,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                toName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                note,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: status == 'paid'
                                    ? AppColors.success.withOpacity(0.12)
                                    : AppColors.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: status == 'paid'
                                      ? AppColors.success
                                      : AppColors.warning,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _Participant {
  final String name;
  final String email;
  final bool isSelf;

  const _Participant({
    required this.name,
    required this.email,
    required this.isSelf,
  });
}
