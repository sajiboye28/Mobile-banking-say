import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/services/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:real_banking/theme/app_colors.dart';

final String _kTransactionUrl = '$kApiBase/transaction';
final String _kRequestOtpUrl = '$kApiBase/transaction/request-otp';

class SendMoneyScreen extends StatefulWidget {
  final String senderUid;
  // Optional pre-filled data for QR-based payments
  final String? initialRecipientUid;
  final String? initialRecipientName;
  final double? initialAmount;

  const SendMoneyScreen({
    super.key,
    required this.senderUid,
    this.initialRecipientUid,
    this.initialRecipientName,
    this.initialAmount,
  });

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final TextEditingController _recipientEmailController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  // Steps: 0=transfer form, 1=OTP entry
  int _currentStep = 0;
  String? _errorMessage;
  String? _recipientName;
  bool _showSuccess = false;
  bool _useAccountNumber = false;
  String? _transactionId;
  bool _otpSent = false;
  bool _requestingOtp = false;
  String? _otpEmail;

  // Balance & recent recipients
  double _userBalance = 0.0;
  bool _balanceLoaded = false;
  List<Map<String, String>> _recentRecipients = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipientUid != null) {
      _recipientEmailController.text = widget.initialRecipientUid ?? '';
      _recipientName = widget.initialRecipientName;
      _currentStep = 0;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    _amountController.addListener(_onAmountChanged);
    _loadBalanceAndRecipients();
  }

  @override
  void dispose() {
    _recipientEmailController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadBalanceAndRecipients() async {
    try {
      // Load balance from PocketBase
      final userRecord = await PbService.instance.pb
          .collection('users')
          .getOne(widget.senderUid);
      if (mounted) {
        setState(() {
          _userBalance = (userRecord.data['balance'] ?? 0).toDouble();
          _balanceLoaded = true;
        });
      }

      // Load last 20 debit transactions to extract recent recipients
      final txResult = await PbService.instance.pb
          .collection('transactions')
          .getList(
            page: 1,
            perPage: 20,
            filter: 'userId = "${widget.senderUid}" && type = "Debit"',
            sort: '-created',
          );

      final seen = <String>{};
      final recipients = <Map<String, String>>[];
      for (final record in txResult.items) {
        final email =
            (record.data['relatedUserEmail'] as String?) ?? '';
        final name =
            (record.data['relatedUserName'] as String?) ?? email;
        if (email.isNotEmpty && !seen.contains(email)) {
          seen.add(email);
          recipients.add({'email': email, 'name': name});
          if (recipients.length >= 5) break;
        }
      }
      if (mounted) setState(() => _recentRecipients = recipients);
    } catch (_) {
      // Silently fail — balance and recipients are enhancements only
    }
  }

  double? get _enteredAmount =>
      double.tryParse(_amountController.text.trim());

  double get _balanceAfterTransfer {
    final amount = _enteredAmount ?? 0.0;
    return (_userBalance - amount).clamp(0.0, double.infinity);
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _currentStep = 1;
      _errorMessage = null;
    });
    await _requestOtp();
  }

  Future<void> _requestOtp() async {
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
        body: jsonEncode({}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _otpSent = true;
          _otpEmail = data['email'] as String?;
          _currentStep = 1;
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

  Future<void> _handleSend() async {
    final tccCode = _otpController.text.trim().toUpperCase();
    if (tccCode.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-character code from your email.');
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }
    if (_balanceLoaded && amount > _userBalance) {
      setState(() => _errorMessage = 'Insufficient balance.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipientInput = _recipientEmailController.text.trim();
      final note = _noteController.text.trim();
      final description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Transfer to $recipientInput';

      final idToken = PbService.instance.authToken;
      if (idToken == null || idToken.isEmpty) {
        setState(() {
          _errorMessage = 'Session expired. Please sign in again.';
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> requestBody = {
        'amount': amount,
        'tccCode': tccCode,
        'description': description,
        if (note.isNotEmpty) 'note': note,
      };
      if (_useAccountNumber) {
        requestBody['recipientAccountNumber'] = recipientInput;
      } else {
        requestBody['recipientEmail'] = recipientInput;
      }

      final response = await http.post(
        Uri.parse(_kTransactionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final resolvedName =
            data['recipientName'] as String? ?? recipientInput;
        final txId = data['transactionId'] as String? ?? '';

        // Save note to transaction via PocketBase if we have a txId and note
        if (txId.isNotEmpty && note.isNotEmpty) {
          try {
            await PbService.instance.pb
                .collection('transactions')
                .update(txId, body: {'note': note});
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _recipientName = resolvedName;
            _transactionId = txId;
            _showSuccess = true;
          });
        }
      } else {
        setState(() {
          _errorMessage = data['error'] as String? ??
              'Transaction failed. Please try again.';
        });
      }
    } catch (e) {
      setState(
          () => _errorMessage = 'Could not reach server. Check your connection.');
    } finally {
      if (mounted && !_showSuccess) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _showSuccess = false;
      _currentStep = 0;
      _errorMessage = null;
      _transactionId = null;
      _recipientName = null;
      _otpSent = false;
      _otpEmail = null;
      _recipientEmailController.clear();
      _amountController.clear();
      _descriptionController.clear();
      _noteController.clear();
      _otpController.clear();
    });
    _loadBalanceAndRecipients();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return _buildSuccessScreen();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStepBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: _currentStep == 0
                      ? _buildTransferForm()
                      : _buildOtpStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Success screen ────────────────────────────────────────────────────────
  Widget _buildSuccessScreen() {
    final refNumber = _transactionId != null && _transactionId!.length >= 8
        ? _transactionId!.substring(0, 8).toUpperCase()
        : 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surfaceContainerLow],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'Transfer Complete',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              // Details card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _successRow(
                        'Recipient',
                        _recipientName ??
                            _recipientEmailController.text.trim(),
                      ),
                      const Divider(
                          color: AppColors.surfaceContainerHighest, height: 24),
                      _successRow(
                        'Amount',
                        '\$${_amountController.text}',
                        valueStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      const Divider(
                          color: AppColors.surfaceContainerHighest, height: 24),
                      _successRow('Reference', refNumber),
                      if (_noteController.text.trim().isNotEmpty) ...[
                        const Divider(
                            color: AppColors.surfaceContainerHighest,
                            height: 24),
                        _successRow('Note', _noteController.text.trim()),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _resetForm,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.electricGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Send Again',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successRow(String label, String value,
      {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.onSurface, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send Money',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Sovereign transfer protocol',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step indicator bar ────────────────────────────────────────────────────
  Widget _buildStepBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _StepDot(
            number: 1,
            label: 'Details',
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: _currentStep >= 1
                      ? [AppColors.primaryContainer, AppColors.primary]
                      : [
                          AppColors.surfaceContainerHigh,
                          AppColors.surfaceContainerHigh,
                        ],
                ),
              ),
            ),
          ),
          _StepDot(
            number: 2,
            label: 'Confirm',
            isActive: _currentStep == 1,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  // ─── Input field helper ────────────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.onSurfaceVariant.withOpacity(0.6),
        fontSize: 14,
      ),
      hintText: hint,
      hintStyle: TextStyle(
          color: AppColors.onSurfaceVariant.withOpacity(0.25), fontSize: 14),
      prefixIcon: prefix,
      filled: true,
      fillColor: AppColors.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primaryContainer, width: 2),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
    );
  }

  // ─── Transfer Form (Step 0) ────────────────────────────────────────────────
  Widget _buildTransferForm() {
    final amount = _enteredAmount ?? 0.0;
    final balanceRemaining = _userBalance - amount;
    final isOverBalance = _balanceLoaded && amount > _userBalance;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Error banner
          if (_errorMessage != null) ...[
            _buildErrorBanner(),
            const SizedBox(height: 16),
          ],

          // Recent Recipients
          if (_recentRecipients.isNotEmpty) ...[
            Text(
              'RECENT RECIPIENTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _recentRecipients.map((r) {
                  final initial = (r['name'] ?? r['email'] ?? '?')
                      .trim()
                      .isNotEmpty
                      ? (r['name'] ?? r['email'] ?? '?')
                          .trim()[0]
                          .toUpperCase()
                      : '?';
                  return GestureDetector(
                    onTap: () {
                      _recipientEmailController.text = r['email'] ?? '';
                      _useAccountNumber = false;
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _recipientEmailController.text.trim() ==
                                  (r['email'] ?? '')
                              ? AppColors.primaryContainer
                              : AppColors.outlineVariant.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: AppColors.electricGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                r['email'] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Toggle: Email vs Account Number
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _useAccountNumber = false;
                      _recipientEmailController.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_useAccountNumber
                            ? AppColors.surfaceContainerLow
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alternate_email_rounded,
                              size: 15,
                              color: !_useAccountNumber
                                  ? AppColors.primaryContainer
                                  : AppColors.onSurfaceVariant.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: !_useAccountNumber
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _useAccountNumber = true;
                      _recipientEmailController.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _useAccountNumber
                            ? AppColors.surfaceContainerLow
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tag_rounded,
                              size: 15,
                              color: _useAccountNumber
                                  ? AppColors.primaryContainer
                                  : AppColors.onSurfaceVariant.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(
                            'Acct Number',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _useAccountNumber
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Recipient field
          TextFormField(
            controller: _recipientEmailController,
            keyboardType: _useAccountNumber
                ? TextInputType.number
                : TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
            decoration: _inputDecoration(
              label: _useAccountNumber ? 'Account Number' : 'Recipient Email',
              hint: _useAccountNumber
                  ? '8-digit account number'
                  : 'recipient@example.com',
              prefix: Icon(
                _useAccountNumber
                    ? Icons.tag_rounded
                    : Icons.alternate_email_rounded,
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          // Amount hero input
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOverBalance
                    ? AppColors.error.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'AMOUNT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant.withOpacity(0.5),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          color: isOverBalance
                              ? AppColors.error
                              : AppColors.onSurface,
                          letterSpacing: -2,
                          height: 1,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: AppColors.surfaceContainerHigh,
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          errorStyle: TextStyle(fontSize: 0),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '';
                          final a = double.tryParse(v.trim());
                          if (a == null || a <= 0) return '';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                // Balance remaining live subtitle
                if (_balanceLoaded && amount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOverBalance
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOverBalance
                          ? 'Exceeds balance by \$${(amount - _userBalance).toStringAsFixed(2)}'
                          : 'Balance remaining: \$${balanceRemaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOverBalance
                            ? AppColors.error
                            : AppColors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
            decoration: _inputDecoration(
              label: 'Description (optional)',
              hint: 'What is this for?',
              prefix: Icon(Icons.notes_rounded,
                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                  size: 20),
            ),
          ),
          const SizedBox(height: 12),

          // Note field
          TextFormField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
            decoration: _inputDecoration(
              label: 'Add a note (optional)',
              hint: 'e.g. Dinner last night',
              prefix: Icon(Icons.sticky_note_2_rounded,
                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                  size: 20),
            ),
          ),
          const SizedBox(height: 28),

          // Continue CTA
          _buildPrimaryButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onTap: (_isLoading || isOverBalance) ? null : _handleContinue,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  // ─── OTP Step (Step 1) ─────────────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),

        // Email icon (with spinner overlay while sending)
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _requestingOtp
                      ? Icons.hourglass_top_rounded
                      : Icons.mark_email_unread_rounded,
                  color: AppColors.primaryContainer,
                  size: 38,
                ),
              ),
              if (_requestingOtp)
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primaryContainer,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          _requestingOtp ? 'Sending Code…' : 'Check Your Email',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Body text
        Text(
          _requestingOtp
              ? 'Generating and emailing your one-time code. This only takes a moment.'
              : "We've sent a one-time transaction code to ${_otpEmail ?? 'your email'}. Enter it below to complete your transfer.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant.withOpacity(0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Error banner
        if (_errorMessage != null) ...[
          _buildErrorBanner(),
          const SizedBox(height: 20),
        ],

        // OTP input
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.text,
          maxLength: 6,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            TextInputFormatter.withFunction((old, newVal) {
              final clean = newVal.text
                  .toUpperCase()
                  .replaceAll(RegExp(r'[^A-Z2-9]'), '')
                  .substring(
                      0,
                      newVal.text
                              .toUpperCase()
                              .replaceAll(RegExp(r'[^A-Z2-9]'), '')
                              .length
                              .clamp(0, 6));
              return newVal.copyWith(
                text: clean,
                selection: TextSelection.collapsed(offset: clean.length),
              );
            }),
          ],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: 10,
          ),
          decoration: _inputDecoration(
            label: '6-character code',
            hint: 'XXXXXX',
            prefix: Icon(Icons.vpn_key_rounded,
                color: AppColors.onSurfaceVariant.withOpacity(0.5), size: 20),
          ).copyWith(
            counterText: '',
          ),
        ),
        const SizedBox(height: 28),

        // Complete Transfer CTA
        _buildPrimaryButton(
          label: 'Complete Transfer',
          icon: Icons.send_rounded,
          onTap: (_isLoading || _requestingOtp) ? null : _handleSend,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),

        // Resend code
        Center(
          child: TextButton(
            onPressed: (_isLoading || _requestingOtp)
                ? null
                : () async {
                    setState(() {
                      _otpSent = false;
                      _errorMessage = null;
                      _otpController.clear();
                    });
                    await _requestOtp();
                  },
            child: Text(
              _requestingOtp ? 'Sending…' : 'Resend Code',
              style: TextStyle(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.error.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryContainer, AppColors.primary],
                )
              : null,
          color: onTap == null ? AppColors.surfaceContainerHigh : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.onPrimaryFixed,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        color: AppColors.onPrimaryFixed, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimaryFixed,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Dot widget
// ─────────────────────────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepDot({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: (isActive || isCompleted)
                ? const LinearGradient(
                    colors: [
                      AppColors.primaryContainer,
                      AppColors.primary,
                    ],
                  )
                : null,
            color: (isActive || isCompleted)
                ? null
                : AppColors.surfaceContainerHigh,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    color: AppColors.onPrimaryFixed, size: 18)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? AppColors.onPrimaryFixed
                          : AppColors.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
