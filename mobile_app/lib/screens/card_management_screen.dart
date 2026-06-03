import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:real_banking/models/virtual_card_model.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';

class CardManagementScreen extends StatefulWidget {
  final String uid;
  final String userName;

  const CardManagementScreen({
    super.key,
    required this.uid,
    required this.userName,
  });

  @override
  State<CardManagementScreen> createState() => _CardManagementScreenState();
}

class _CardManagementScreenState extends State<CardManagementScreen>
    with SingleTickerProviderStateMixin {

  List<VirtualCardModel> _cards = [];
  bool _isLoading = true;
  bool _isCreating = false;

  // Per-card CVV reveal state: cardId -> timer
  final Map<String, Timer> _cvvTimers = {};
  final Set<String> _revealedCvvIds = {};

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _flipController.addListener(() {
      if (_flipAnimation.value >= 0.5 && !_showBack) {
        setState(() => _showBack = true);
      } else if (_flipAnimation.value < 0.5 && _showBack) {
        setState(() => _showBack = false);
      }
    });
    _loadCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    for (final t in _cvvTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final records = await PbService.instance.pb
          .collection('virtual_cards')
          .getFullList(filter: 'userId="${widget.uid}"', sort: '-created');
      if (mounted) {
        setState(() {
          _cards = records.map((r) => VirtualCardModel.fromRecord(r)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Error loading cards: $e', isError: true);
      }
    }
  }

  Future<void> _createCard() async {
    setState(() => _isCreating = true);
    try {
      final random = Random();
      final cardNumber = '4532'
          '${random.nextInt(9000) + 1000}'
          '${random.nextInt(9000) + 1000}'
          '${random.nextInt(9000) + 1000}';
      final cvv = (random.nextInt(900) + 100).toString();
      final now = DateTime.now();
      final expiryDate =
          '${now.month.toString().padLeft(2, '0')}/${(now.year + 3).toString().substring(2)}';

      await PbService.instance.pb.collection('virtual_cards').create(body: {
        'userId': widget.uid,
        'cardNumber': cardNumber,
        'cardHolder': widget.userName,
        'expiryDate': expiryDate,
        'cvv': cvv,
        'cardType': 'Visa Virtual',
        'isActive': true,
        'spendingLimit': 5000.0,
        'currentSpend': 0.0,
        'cardholderName': widget.userName.toUpperCase(),
        'expiryMonth': now.month,
        'expiryYear': now.year + 3,
        'isFrozen': false,
        'dailyLimit': 0.0,
        'monthlyLimit': 0.0,
      });

      await _loadCards();
      if (mounted) _showSnack('Virtual card created!');
    } catch (e) {
      if (mounted) _showSnack('Failed to create card: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _toggleFreeze(VirtualCardModel card) async {
    final newState = !card.isFrozen;
    try {
      await PbService.instance.pb.collection('virtual_cards').update(card.cardId, body: {
        'isFrozen': newState,
        'isActive': !newState,
      });
      await _loadCards();
      _showSnack(newState ? 'Card frozen' : 'Card unfrozen');
    } catch (e) {
      _showSnack('Failed to update card: $e', isError: true);
    }
  }

  Future<void> _cancelCard(VirtualCardModel card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Card?',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This will permanently delete your virtual card ending in ${card.cardNumber.substring(12)}. This action cannot be undone.',
          style: TextStyle(
            color: AppColors.onSurfaceVariant.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Card',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Card',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await PbService.instance.pb.collection('virtual_cards').delete(card.cardId);
        await _loadCards();
        _showSnack('Card cancelled');
      } catch (e) {
        _showSnack('Failed to cancel card: $e', isError: true);
      }
    }
  }

  void _showSetLimitDialog(VirtualCardModel card) {
    double currentLimit =
        card.dailyLimit > 0 ? card.dailyLimit : card.monthlyLimit > 0 ? card.monthlyLimit : 5000;
    double sliderValue = currentLimit.clamp(100, 10000);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Set Spending Limit',
            style: TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${sliderValue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryContainer,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monthly spending limit',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(ctx).copyWith(
                  activeTrackColor: AppColors.primaryContainer,
                  inactiveTrackColor:
                      AppColors.surfaceContainerHighest,
                  thumbColor: AppColors.primaryContainer,
                  overlayColor:
                      AppColors.primaryContainer.withOpacity(0.1),
                ),
                child: Slider(
                  value: sliderValue,
                  min: 100,
                  max: 10000,
                  divisions: 99,
                  onChanged: (v) =>
                      setDialogState(() => sliderValue = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$100',
                      style: TextStyle(
                          color: AppColors.onSurfaceVariant.withOpacity(0.5),
                          fontSize: 11)),
                  Text('\$10,000',
                      style: TextStyle(
                          color: AppColors.onSurfaceVariant.withOpacity(0.5),
                          fontSize: 11)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PbService.instance.pb
                      .collection('virtual_cards')
                      .update(card.cardId, body: {
                    'spendingLimit': sliderValue,
                    'monthlyLimit': sliderValue,
                  });
                  await _loadCards();
                  _showSnack('Spending limit updated');
                } catch (e) {
                  _showSnack('Failed to update limit: $e', isError: true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.electricGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _revealCvv(String cardId) {
    setState(() => _revealedCvvIds.add(cardId));
    _cvvTimers[cardId]?.cancel();
    _cvvTimers[cardId] = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _revealedCvvIds.remove(cardId));
      }
    });
  }

  void _copyCardNumber(VirtualCardModel card) {
    final formatted =
        '${card.cardNumber.substring(0, 4)} ${card.cardNumber.substring(4, 8)} ${card.cardNumber.substring(8, 12)} ${card.cardNumber.substring(12)}';
    Clipboard.setData(ClipboardData(text: formatted));
    _showSnack('Card number copied to clipboard');
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ── Persistent create-card button always visible at bottom ──────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _buildGetCardButton(),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryContainer,
                  strokeWidth: 2.5,
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(),
                  ),
                  if (_cards.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCardSection(_cards[index]),
                        childCount: _cards.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSecurityTips(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                'My Cards',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Manage your virtual cards',
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Card icon in rounded square
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No virtual cards yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Virtual cards keep your real card details safe when shopping online.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant.withOpacity(0.65),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          // Feature pills
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _featurePill(Icons.bolt_rounded, 'Instant issuance'),
              _featurePill(Icons.ac_unit_rounded, 'Freeze anytime'),
              _featurePill(Icons.tune_rounded, 'Spending limits'),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetCardButton() {
    return GestureDetector(
      onTap: _isCreating ? null : _createCard,
      child: AnimatedOpacity(
        opacity: _isCreating ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: _isCreating ? null : AppColors.electricGradient,
            color: _isCreating ? AppColors.surfaceContainerHigh : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isCreating
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primaryContainer.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Center(
            child: _isCreating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_card_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _cards.isEmpty ? 'Create Virtual Card' : 'Request Another Card',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(VirtualCardModel card) {
    final isCvvRevealed = _revealedCvvIds.contains(card.cardId);
    final spendingLimit = card.monthlyLimit > 0 ? card.monthlyLimit : 5000.0;
    // currentSpend not in model; default 0
    const currentSpend = 0.0;
    final spendProgress =
        spendingLimit > 0 ? (currentSpend / spendingLimit).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Widget ──────────────────────────────────────────────────
          _buildCardWidget(card, isCvvRevealed),
          const SizedBox(height: 16),

          // ── Spending Progress ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Spending Limit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant.withOpacity(0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      '\$${currentSpend.toStringAsFixed(0)} / \$${spendingLimit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: spendProgress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      spendProgress > 0.8
                          ? AppColors.error
                          : AppColors.primaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Quick Actions (2×2 grid) ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _actionChip(
                  icon: card.isFrozen
                      ? Icons.lock_open_rounded
                      : Icons.ac_unit_rounded,
                  label: card.isFrozen ? 'Unfreeze' : 'Freeze',
                  color: card.isFrozen ? AppColors.success : AppColors.primary,
                  onTap: () => _toggleFreeze(card),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionChip(
                  icon: Icons.content_copy_rounded,
                  label: 'Copy Number',
                  color: AppColors.primaryContainer,
                  onTap: () => _copyCardNumber(card),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _actionChip(
                  icon: Icons.tune_rounded,
                  label: 'Set Limit',
                  color: AppColors.warning,
                  onTap: () => _showSetLimitDialog(card),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionChip(
                  icon: Icons.cancel_rounded,
                  label: 'Cancel Card',
                  color: AppColors.error,
                  onTap: () => _cancelCard(card),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardWidget(VirtualCardModel card, bool isCvvRevealed) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0D1B3E),
              Color(0xFF0A0A1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ambient circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                ),
              ),
            ),
            // Frozen overlay
            if (card.isFrozen)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.8),
                              width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'FROZEN',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Active/Frozen badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (card.isFrozen
                                  ? AppColors.error
                                  : AppColors.success)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: card.isFrozen
                                ? AppColors.error.withOpacity(0.5)
                                : AppColors.success.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          card.isFrozen ? 'FROZEN' : 'ACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: card.isFrozen
                                ? AppColors.error
                                : AppColors.success,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      // VISA logo
                      const Text(
                        'VISA',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // Middle — chip icon
                  const Icon(
                    Icons.contactless_rounded,
                    color: Colors.white54,
                    size: 30,
                  ),
                  // Bottom info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Masked card number
                      Text(
                        '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  ${card.cardNumber.length >= 16 ? card.cardNumber.substring(12) : '????'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARD HOLDER',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.cardholderName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPIRES',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white.withOpacity(0.5),
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.expiryFormatted,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _revealCvv(card.cardId),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CVV',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCvvRevealed ? card.cvv : '\u2022\u2022\u2022',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isCvvRevealed) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _revealCvv(card.cardId),
                          child: Row(
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to reveal CVV',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTips() {
    const tips = [
      (
        icon: Icons.lock_rounded,
        title: 'Never share your CVV',
        body:
            'Your CVV is confidential. No legitimate bank or service will ever ask for it.'
      ),
      (
        icon: Icons.visibility_off_rounded,
        title: 'Freeze when not in use',
        body:
            'Freeze your virtual card when you\'re not actively using it to prevent unauthorised charges.'
      ),
      (
        icon: Icons.notifications_active_rounded,
        title: 'Monitor transactions',
        body:
            'Regularly review your transaction history and report any suspicious activity immediately.'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Card Security Tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(tip.icon,
                        size: 18, color: AppColors.primaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tip.body,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
