import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/services/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

final String _kRequestOtpUrl = '$kApiBase/transaction/request-otp';

// ─── Data model ──────────────────────────────────────────────────────────────

class _Biller {
  final String name;
  final String category;
  final IconData icon;
  final Color color;
  final bool fixedAmount;
  final double? fixedAmountValue;

  const _Biller({
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    this.fixedAmount = false,
    this.fixedAmountValue,
  });
}

const List<String> _kCategories = [
  'All',
  'Utilities',
  'Internet',
  'Phone',
  'Insurance',
  'Subscriptions',
  'Government',
  'Others',
];

const List<_Biller> _kBillers = [
  // Utilities
  _Biller(
      name: 'Electric Company',
      category: 'Utilities',
      icon: Icons.bolt,
      color: Color(0xFFF59E0B)),
  _Biller(
      name: 'Water Board',
      category: 'Utilities',
      icon: Icons.water_drop,
      color: Color(0xFF3B82F6)),
  _Biller(
      name: 'Gas Company',
      category: 'Utilities',
      icon: Icons.local_fire_department,
      color: Color(0xFFEF4444)),
  _Biller(
      name: 'City Services',
      category: 'Utilities',
      icon: Icons.location_city,
      color: Color(0xFF8B5CF6)),

  // Internet
  _Biller(
      name: 'Comcast / Xfinity',
      category: 'Internet',
      icon: Icons.router,
      color: Color(0xFF0EA5E9)),
  _Biller(
      name: 'AT&T Internet',
      category: 'Internet',
      icon: Icons.wifi,
      color: Color(0xFF00B4D8)),
  _Biller(
      name: 'Spectrum',
      category: 'Internet',
      icon: Icons.signal_wifi_4_bar,
      color: Color(0xFF6366F1)),
  _Biller(
      name: 'Verizon Fios',
      category: 'Internet',
      icon: Icons.lan,
      color: Color(0xFFEC4899)),

  // Phone
  _Biller(
      name: 'T-Mobile',
      category: 'Phone',
      icon: Icons.phone_android,
      color: Color(0xFFDB2777)),
  _Biller(
      name: 'Verizon Wireless',
      category: 'Phone',
      icon: Icons.cell_tower,
      color: Color(0xFFDC2626)),
  _Biller(
      name: 'AT&T Mobile',
      category: 'Phone',
      icon: Icons.smartphone,
      color: Color(0xFF2563EB)),
  _Biller(
      name: 'Cricket Wireless',
      category: 'Phone',
      icon: Icons.sim_card,
      color: Color(0xFF16A34A)),

  // Subscriptions
  _Biller(
      name: 'Netflix',
      category: 'Subscriptions',
      icon: Icons.movie,
      color: Color(0xFFDC2626),
      fixedAmount: true,
      fixedAmountValue: 15.49),
  _Biller(
      name: 'Spotify',
      category: 'Subscriptions',
      icon: Icons.music_note,
      color: Color(0xFF16A34A),
      fixedAmount: true,
      fixedAmountValue: 9.99),
  _Biller(
      name: 'Amazon Prime',
      category: 'Subscriptions',
      icon: Icons.local_shipping,
      color: Color(0xFFF59E0B),
      fixedAmount: true,
      fixedAmountValue: 14.99),
  _Biller(
      name: 'YouTube Premium',
      category: 'Subscriptions',
      icon: Icons.play_circle_fill,
      color: Color(0xFFEF4444),
      fixedAmount: true,
      fixedAmountValue: 13.99),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class BillPayScreen extends StatefulWidget {
  final String uid;

  const BillPayScreen({super.key, required this.uid});

  @override
  State<BillPayScreen> createState() => _BillPayScreenState();
}

class _BillPayScreenState extends State<BillPayScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_Biller> get _filteredBillers => _selectedCategory == 'All'
      ? _kBillers
      : _kBillers.where((b) => b.category == _selectedCategory).toList();

  // ── Payment bottom sheet ─────────────────────────────────────────────────

  void _openPaymentSheet(_Biller biller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BillerPaymentSheet(uid: widget.uid, biller: biller),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bill Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryContainer,
          labelColor: AppColors.onSurface,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Pay Bills'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPayTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ── Pay tab ──────────────────────────────────────────────────────────────

  Widget _buildPayTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryChips(),
        const SizedBox(height: 8),
        Expanded(child: _buildBillerGrid()),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _kCategories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerHigh,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillerGrid() {
    final billers = _filteredBillers;
    if (billers.isEmpty) {
      return Center(
        child: Text(
          'No billers in this category',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: billers.length,
      itemBuilder: (context, index) => _BillerCard(
        biller: billers[index],
        onTap: () => _openPaymentSheet(billers[index]),
      ),
    );
  }

  // ── History tab ──────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return FutureBuilder<List<RecordModel>>(
      future: PbService.instance.pb
          .collection('bill_payments')
          .getFullList(filter: 'userId="${widget.uid}"', sort: '-created'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyHistory();
        }
        final docs = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _HistoryCard(data: docs[index].data);
          },
        );
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'No bill payments yet',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bill payment history will appear here.',
            style: TextStyle(
                color: AppColors.onSurfaceVariant.withOpacity(0.6),
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Biller Card ─────────────────────────────────────────────────────────────

class _BillerCard extends StatelessWidget {
  final _Biller biller;
  final VoidCallback onTap;

  const _BillerCard({required this.biller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: biller.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(biller.icon, color: biller.color, size: 22),
            ),
            const Spacer(),
            // Name
            Text(
              biller.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Category + auto-pay row
            Row(
              children: [
                Expanded(
                  child: Text(
                    biller.category,
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Auto-pay setup coming soon'),
                        backgroundColor:
                            AppColors.surfaceContainerHigh,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.autorenew_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final provider = data['provider'] as String? ?? 'Unknown Biller';
    final category = data['category'] as String? ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final status = data['status'] as String? ?? 'Pending';
    final tsStr = data['timestamp'] as String? ?? data['created'] as String? ?? '';
    final tsDate = tsStr.isNotEmpty ? DateTime.tryParse(tsStr) : null;
    final dateStr = tsDate != null
        ? DateFormat('MMM d, y • h:mm a').format(tsDate)
        : 'Date unknown';

    final isSuccess = status == 'Success';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: AppColors.primaryContainer, size: 22),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$category • $dateStr',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSuccess ? AppColors.success : AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

// ─── Payment Bottom Sheet ─────────────────────────────────────────────────────

class _BillerPaymentSheet extends StatefulWidget {
  final String uid;
  final _Biller biller;

  const _BillerPaymentSheet({required this.uid, required this.biller});

  @override
  State<_BillerPaymentSheet> createState() => _BillerPaymentSheetState();
}

class _BillerPaymentSheetState extends State<_BillerPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();

  bool _scheduleForLater = false;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  // Step: false = form, true = PIN/OTP flow
  bool _showAuthFlow = false;
  // OTP sub-step: false = PIN entry, true = OTP entry
  bool _otpSent = false;
  bool _requestingOtp = false;
  String? _otpEmail;
  String? _errorMessage;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.biller.fixedAmount && widget.biller.fixedAmountValue != null) {
      _amountController.text =
          widget.biller.fixedAmountValue!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _showAuthFlow = true;
      _errorMessage = null;
    });
  }

  Future<void> _requestOtp() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(
          () => _errorMessage = 'Please enter your 4-digit transaction PIN');
      return;
    }
    setState(() {
      _requestingOtp = true;
      _errorMessage = null;
    });
    try {
      final token = PbService.instance.authToken ?? '';
      final response = await http.post(
        Uri.parse(_kRequestOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'pin': pin}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _otpSent = true;
          _otpEmail = data['email'] as String?;
          _requestingOtp = false;
        });
      } else {
        setState(() {
          _errorMessage =
              data['error'] as String? ?? 'Failed to send code. Try again.';
          _requestingOtp = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _requestingOtp = false;
      });
    }
  }

  Future<void> _handlePayBill() async {
    final otp = _otpController.text.trim().toUpperCase();
    if (otp.length != 6) {
      setState(
          () => _errorMessage = 'Enter the 6-character code from your email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pb = PbService.instance.pb;
      final userRecord = await pb.collection('users').getOne(widget.uid);
      final userData = userRecord.data;
      final amount = double.parse(_amountController.text.trim());

      if (userData['canTransact'] == false) {
        _setError('Your transaction ability has been disabled.');
        return;
      }
      if ((userData['balance'] as num).toDouble() < amount) {
        _setError('Insufficient balance.');
        return;
      }

      final description =
          '${widget.biller.category} Bill — ${widget.biller.name}';
      final now = DateTime.now().toIso8601String();

      await pb.collection('users').update(widget.uid, body: {
        'balance': (userData['balance'] as num).toDouble() - amount,
      });

      final debitRecord = await pb.collection('transactions').create(body: {
        'userId': widget.uid,
        'amount': amount,
        'type': 'Debit',
        'timestamp': now,
        'description': description,
        'status': 'Success',
        'relatedUserId': null,
        'relatedUserName': widget.biller.name,
      });

      await pb.collection('bill_payments').create(body: {
        'userId': widget.uid,
        'category': widget.biller.category,
        'provider': widget.biller.name,
        'accountNumber': _accountController.text.trim(),
        'amount': amount,
        'description': description,
        'timestamp': now,
        'status': 'Success',
        'transactionId': debitRecord.id,
        'scheduled': _scheduleForLater,
        'scheduledDate':
            _scheduleForLater ? _scheduledDate.toIso8601String() : null,
      });

      if (mounted) {
        setState(() => _showSuccess = true);
        await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _setError('Payment failed. Please try again.');
    }
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _scheduledDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _showSuccess
            ? _buildSuccess()
            : SingleChildScrollView(
                child: _showAuthFlow
                    ? (_otpSent
                        ? _buildOtpSection()
                        : _buildPinSection())
                    : _buildFormSection(),
              ),
      ),
    );
  }

  Widget _buildSuccess() {
    return SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Successful!',
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${_amountController.text} paid to ${widget.biller.name}',
            style: TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.biller.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.biller.icon,
                    color: widget.biller.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.biller.name,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.biller.category,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            _buildErrorBox(_errorMessage!),
            const SizedBox(height: 14),
          ],

          // Account number
          _buildTextField(
            controller: _accountController,
            label: 'Account / Reference Number',
            hint: 'Enter your account number',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.text,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter your account number'
                : null,
          ),
          const SizedBox(height: 16),

          // Amount
          _buildTextField(
            controller: _amountController,
            label: widget.biller.fixedAmount
                ? 'Amount (Fixed)'
                : 'Amount',
            hint: '0.00',
            icon: Icons.attach_money_rounded,
            prefixText: '\$ ',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            readOnly: widget.biller.fixedAmount,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter amount';
              final parsed = double.tryParse(v.trim());
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Schedule option
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.onSurfaceVariant, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Schedule for later',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _scheduleForLater,
                      onChanged: (v) =>
                          setState(() => _scheduleForLater = v),
                      activeColor: AppColors.primaryContainer,
                    ),
                  ],
                ),
                if (_scheduleForLater) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primaryContainer
                                .withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: AppColors.primaryContainer, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMM d, y')
                                .format(_scheduledDate),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildPrimaryButton(
            label: 'Continue',
            onTap: _isLoading ? null : _handleContinue,
          ),
        ],
      ),
    );
  }

  // ─── PIN Section ──────────────────────────────────────────────────────────

  Widget _buildPinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
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

        const Text(
          'Transaction PIN',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your 4-digit transaction PIN to proceed',
          style: TextStyle(
              color: AppColors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _summaryRow('Biller', widget.biller.name),
              const SizedBox(height: 8),
              _summaryRow('Account', _accountController.text.trim()),
              const SizedBox(height: 8),
              _summaryRow('Amount', '\$${_amountController.text.trim()}'),
              if (_scheduleForLater) ...[
                const SizedBox(height: 8),
                _summaryRow('Scheduled',
                    DateFormat('MMM d, y').format(_scheduledDate)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_errorMessage != null) ...[
          _buildErrorBox(_errorMessage!),
          const SizedBox(height: 14),
        ],

        // PIN input
        TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            labelText: '4-digit PIN',
            labelStyle:
                TextStyle(color: AppColors.onSurface.withOpacity(0.5)),
            hintText: '••••',
            counterText: '',
            prefixIcon: Icon(Icons.lock_rounded,
                color: AppColors.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.primaryContainer, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildPrimaryButton(
          label: 'Send Code to Email',
          icon: Icons.email_rounded,
          onTap: _requestingOtp ? null : _requestOtp,
          isLoading: _requestingOtp,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _requestingOtp
              ? null
              : () => setState(() {
                    _showAuthFlow = false;
                    _errorMessage = null;
                    _pinController.clear();
                  }),
          child: Text(
            'Go Back',
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─── OTP Section ──────────────────────────────────────────────────────────

  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
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
        const SizedBox(height: 24),

        // Email icon
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_rounded,
              color: AppColors.primaryContainer,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "We've sent a one-time transaction code to ${_otpEmail ?? 'your email'}. Enter it below to complete the payment.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          _buildErrorBox(_errorMessage!),
          const SizedBox(height: 14),
        ],

        // OTP input
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.text,
          maxLength: 6,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: 10,
          ),
          decoration: InputDecoration(
            labelText: '6-character code',
            labelStyle:
                TextStyle(color: AppColors.onSurface.withOpacity(0.5)),
            hintText: 'XXXXXX',
            counterText: '',
            prefixIcon: Icon(Icons.vpn_key_rounded,
                color: AppColors.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.primaryContainer, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildPrimaryButton(
          label: 'Pay Bill',
          icon: Icons.payment_rounded,
          onTap: _isLoading ? null : _handlePayBill,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => setState(() {
                    _otpSent = false;
                    _errorMessage = null;
                    _otpController.clear();
                    _pinController.clear();
                  }),
          child: Text(
            'Resend Code',
            style: TextStyle(
              color: AppColors.primaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      style: const TextStyle(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: AppColors.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600),
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
            color: AppColors.onSurface, fontWeight: FontWeight.w600),
        hintStyle:
            TextStyle(color: AppColors.onSurface.withOpacity(0.3)),
        prefixIcon: Icon(icon,
            color: AppColors.onSurface.withOpacity(0.5)),
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppColors.primaryContainer, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
