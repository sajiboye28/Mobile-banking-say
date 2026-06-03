import 'dart:math';
import 'package:flutter/material.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:real_banking/models/savings_goal_model.dart';
import 'package:real_banking/services/pb_service.dart';

class SavingsGoalsScreen extends StatefulWidget {
  final String uid;

  const SavingsGoalsScreen({super.key, required this.uid});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  String get uid => widget.uid;

  List<RecordModel>? _records;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() { _loading = true; _error = null; });
    try {
      final records = await PbService.instance.pb
          .collection('savings_goals')
          .getFullList(filter: 'userId="${uid}"', sort: '-created');
      if (mounted) setState(() { _records = records; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // Category map: key -> (emoji, IconData, label)
  static const Map<String, _CategoryMeta> _categoryMap = {
    'home': _CategoryMeta('🏠', Icons.home_rounded, 'Home'),
    'travel': _CategoryMeta('✈️', Icons.flight_rounded, 'Travel'),
    'education': _CategoryMeta('🎓', Icons.school_rounded, 'Education'),
    'car': _CategoryMeta('🚗', Icons.directions_car_rounded, 'Car'),
    'wedding': _CategoryMeta('💍', Icons.favorite_rounded, 'Wedding'),
    'medical': _CategoryMeta('🏥', Icons.local_hospital_rounded, 'Medical'),
    'business': _CategoryMeta('💼', Icons.business_center_rounded, 'Business'),
    'other': _CategoryMeta('⭐', Icons.star_rounded, 'Other'),
    // Legacy keys for backwards compatibility
    'flight': _CategoryMeta('✈️', Icons.flight_rounded, 'Travel'),
    'school': _CategoryMeta('🎓', Icons.school_rounded, 'Education'),
    'phone': _CategoryMeta('📱', Icons.phone_iphone_rounded, 'Phone'),
    'laptop': _CategoryMeta('💻', Icons.laptop_mac_rounded, 'Laptop'),
    'shopping': _CategoryMeta('🛍️', Icons.shopping_bag_rounded, 'Shopping'),
    'restaurant': _CategoryMeta('🍽️', Icons.restaurant_rounded, 'Food'),
    'fitness': _CategoryMeta('💪', Icons.fitness_center_rounded, 'Fitness'),
    'pets': _CategoryMeta('🐾', Icons.pets_rounded, 'Pets'),
    'gift': _CategoryMeta('🎁', Icons.card_giftcard_rounded, 'Gift'),
  };

  static const List<String> _colorOptions = [
    '1A237E',
    '0D47A1',
    '00695C',
    '2E7D32',
    'E65100',
    'C62828',
    '6A1B9A',
    '4E342E',
  ];

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  IconData _getIcon(String key) {
    return _categoryMap[key]?.iconData ?? Icons.savings_rounded;
  }

  String _getCategoryEmoji(String key) {
    return _categoryMap[key]?.emoji ?? '⭐';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: const Text(
          'Savings Goals',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: Builder(builder: (context) {
        if (_loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryContainer),
          );
        }
        if (_error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 56,
                    color: AppColors.onSurface.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }
        final docs = _records ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(context);
        }
        final goals = docs.map((r) => SavingsGoalModel.fromRecord(r)).toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: goals.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildSummaryCard(goals);
            return _buildGoalCard(context, goals[index - 1]);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGoalSheet(context),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Goal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Summary card at top ─────────────────────────────────────────────────────
  Widget _buildSummaryCard(List<SavingsGoalModel> goals) {
    final totalSaved =
        goals.fold<double>(0.0, (sum, g) => sum + g.currentAmount);
    final totalTarget =
        goals.fold<double>(0.0, (sum, g) => sum + g.targetAmount);
    final completedCount = goals.where((g) => g.isCompleted).length;
    final overallProgress =
        totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B3E), Color(0xFF0A0A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL SAVED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(totalSaved),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryContainer.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${goals.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      goals.length == 1 ? 'Goal' : 'Goals',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'across ${goals.length} goal${goals.length == 1 ? '' : 's'}'
            '${completedCount > 0 ? ' · $completedCount completed' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryContainer),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(overallProgress * 100).toStringAsFixed(1)}% of total target',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              Text(
                _currencyFormat.format(totalTarget),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.savings_rounded,
            size: 80,
            color: AppColors.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            'No Savings Goals Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start saving towards your dreams!\nTap the button below to create a goal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurface.withOpacity(0.4),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _showCreateGoalSheet(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.electricGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Create First Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, SavingsGoalModel goal) {
    final goalColor = _hexToColor(goal.color);
    final isCompleted = goal.isCompleted;

    // Days remaining
    int? daysRemaining;
    if (goal.deadlineDate != null && !isCompleted) {
      final diff = goal.deadlineDate!.difference(DateTime.now()).inDays;
      daysRemaining = diff.clamp(0, 99999);
    }

    return GestureDetector(
      onTap: () => _showGoalDetailSheet(context, goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.4)
                : AppColors.outlineVariant.withOpacity(0.1),
            width: isCompleted ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Goal Achieved Banner
            if (isCompleted)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(17)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Goal Achieved!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('🎉', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  18, isCompleted ? 48 : 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: goalColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _getCategoryEmoji(goal.icon),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (daysRemaining != null) ...[
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: daysRemaining <= 7
                                        ? AppColors.warning
                                        : AppColors.onSurface.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    daysRemaining == 0
                                        ? 'Due today'
                                        : '$daysRemaining days left',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: daysRemaining <= 7
                                          ? AppColors.warning
                                          : AppColors.onSurface.withOpacity(0.5),
                                      fontWeight: daysRemaining <= 7
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ] else if (goal.deadlineDate != null)
                                  Text(
                                    DateFormat('MMM d, yyyy')
                                        .format(goal.deadlineDate!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success.withOpacity(0.15)
                              : goalColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${goal.progressPercent}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCompleted ? AppColors.success : goalColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? AppColors.success : goalColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currencyFormat.format(goal.currentAmount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCompleted ? AppColors.success : goalColor,
                        ),
                      ),
                      Text(
                        'of ${_currencyFormat.format(goal.targetAmount)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _showAddFundsSheet(context, goal),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.electricGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Add Funds',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Confetti containers for achieved goals
            if (isCompleted) _buildConfettiDecoration(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfettiDecoration() {
    final random = Random(42); // Fixed seed for stable rendering
    final colors = [
      AppColors.primaryContainer,
      AppColors.success,
      AppColors.warning,
      AppColors.primary,
      Colors.pink,
      Colors.orange,
    ];

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IgnorePointer(
          child: Stack(
            children: List.generate(12, (i) {
              return Positioned(
                left: random.nextDouble() * 300,
                top: random.nextDouble() * 120,
                child: Transform.rotate(
                  angle: random.nextDouble() * 6.28,
                  child: Container(
                    width: random.nextDouble() * 8 + 4,
                    height: random.nextDouble() * 8 + 4,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length].withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showAddFundsSheet(BuildContext context, SavingsGoalModel goal) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Funds to ${goal.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Remaining: ${_currencyFormat.format(goal.remaining)}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            // Quick amounts
            Wrap(
              spacing: 8,
              children: [10, 25, 50, 100, 250].map((amt) {
                return GestureDetector(
                  onTap: () => amountController.text = amt.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Text(
                      '\$$amt',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: AppColors.onSurfaceVariant.withOpacity(0.3),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(
                  color: AppColors.primaryContainer,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.primaryContainer, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final amount =
                    double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _addFundsToGoal(context, goal, amount);
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.electricGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Add Funds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFundsToGoal(
      BuildContext context, SavingsGoalModel goal, double amount) async {
    final pb = PbService.instance.pb;
    try {
      final userRecord = await pb.collection('users').getOne(uid);
      final currentBalance =
          ((userRecord.data['balance'] ?? 0) as num).toDouble();

      if (amount > currentBalance) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient balance'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Deduct from user balance
      await pb.collection('users').update(uid, body: {
        'balance': currentBalance - amount,
      });

      // Add to goal
      final newAmount = goal.currentAmount + amount;
      await pb.collection('savings_goals').update(goal.goalId, body: {
        'currentAmount': newAmount,
        'isCompleted': newAmount >= goal.targetAmount,
      });

      // Create transaction record
      await pb.collection('transactions').create(body: {
        'userId': uid,
        'type': 'Savings',
        'amount': amount,
        'description': 'Transfer to ${goal.name}',
        'goalId': goal.goalId,
        'goalName': goal.name,
      });

      await _loadGoals();

      if (context.mounted) {
        final achieved = newAmount >= goal.targetAmount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(achieved
                ? '🎉 Goal achieved! ${goal.name} is complete!'
                : '\$${amount.toStringAsFixed(2)} added to ${goal.name}'),
            backgroundColor: achieved ? AppColors.success : AppColors.successDim,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add funds: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCreateGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateGoalSheet(uid: uid),
    );
  }

  void _showGoalDetailSheet(BuildContext context, SavingsGoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GoalDetailSheet(
        goal: goal,
        uid: uid,
        categoryMap: _categoryMap,
        hexToColor: _hexToColor,
        getIcon: _getIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category metadata helper
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryMeta {
  final String emoji;
  final IconData iconData;
  final String label;

  const _CategoryMeta(this.emoji, this.iconData, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Goal Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CreateGoalSheet extends StatefulWidget {
  final String uid;

  const _CreateGoalSheet({required this.uid});

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'home';
  String _selectedColor = '1A237E';
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  static const List<String> _colorOptions = [
    '1A237E',
    '0D47A1',
    '00695C',
    '2E7D32',
    'E65100',
    'C62828',
    '6A1B9A',
    '4E342E',
  ];

  // Category options for the picker
  static const List<_CategoryOption> _categories = [
    _CategoryOption('home', '🏠', 'Home'),
    _CategoryOption('travel', '✈️', 'Travel'),
    _CategoryOption('education', '🎓', 'Education'),
    _CategoryOption('car', '🚗', 'Car'),
    _CategoryOption('wedding', '💍', 'Wedding'),
    _CategoryOption('medical', '🏥', 'Medical'),
    _CategoryOption('business', '💼', 'Business'),
    _CategoryOption('other', '⭐', 'Other'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryContainer,
              onPrimary: Colors.white,
              surface: Color(0xFF141829),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final body = <String, dynamic>{
        'userId': widget.uid,
        'name': _nameController.text.trim(),
        'targetAmount': double.parse(_amountController.text.trim()),
        'currentAmount': 0,
        'icon': _selectedCategory,
        'color': _selectedColor,
        'isCompleted': false,
      };
      if (_selectedDeadline != null) {
        body['deadline'] = _selectedDeadline!.toIso8601String();
      }

      await PbService.instance.pb.collection('savings_goals').create(body: body);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create goal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.surfaceContainerLow),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create Savings Goal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Set a target and start saving!',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 24),

              // Goal name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: _fieldDecoration(
                  label: 'Goal Name',
                  hint: 'e.g. Europe Trip',
                  icon: Icons.flag_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target amount
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.onSurface),
                decoration: _fieldDecoration(
                  label: 'Target Amount',
                  hint: '0.00',
                  icon: Icons.attach_money_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a target amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category picker
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              _buildCategoryPicker(),
              const SizedBox(height: 24),

              // Color picker
              const Text(
                'Accent Color',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              _buildColorPicker(),
              const SizedBox(height: 24),

              // Deadline
              const Text(
                'Deadline (optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.surfaceContainerLow,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 20,
                          color: AppColors.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDeadline != null
                            ? DateFormat('MMMM d, yyyy')
                                .format(_selectedDeadline!)
                            : 'Select a deadline',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedDeadline != null
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedDeadline != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDeadline = null),
                          child: Icon(Icons.close_rounded,
                              size: 20,
                              color: AppColors.onSurface.withOpacity(0.5)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Create button
              GestureDetector(
                onTap: _isLoading ? null : _createGoal,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppColors.electricGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Goal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(color: AppColors.onSurface.withOpacity(0.5)),
      hintText: hint,
      hintStyle:
          TextStyle(color: AppColors.onSurface.withOpacity(0.3)),
      prefixIcon: Icon(icon, color: AppColors.primaryContainer),
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
        borderSide:
            const BorderSide(color: AppColors.primaryContainer, width: 2),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat.key;
        final accentColor = _hexToColor(_selectedColor);
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.2)
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: accentColor, width: 2)
                  : Border.all(
                      color: AppColors.surfaceContainerHigh, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: isSelected
                        ? accentColor
                        : AppColors.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colorOptions.map((hex) {
        final color = _hexToColor(hex);
        final isSelected = _selectedColor == hex;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = hex),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.onSurface, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category option data class
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryOption {
  final String key;
  final String emoji;
  final String label;

  const _CategoryOption(this.key, this.emoji, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Goal Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _GoalDetailSheet extends StatelessWidget {
  final SavingsGoalModel goal;
  final String uid;
  final Map<String, _CategoryMeta> categoryMap;
  final Color Function(String) hexToColor;
  final IconData Function(String) getIcon;

  const _GoalDetailSheet({
    required this.goal,
    required this.uid,
    required this.categoryMap,
    required this.hexToColor,
    required this.getIcon,
  });

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final goalColor = hexToColor(goal.color);
    final displayColor = goal.isCompleted ? AppColors.success : goalColor;
    final emoji = categoryMap[goal.icon]?.emoji ?? '⭐';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.surfaceContainerLow),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Category icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              goal.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            if (goal.isCompleted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🎉 Goal Achieved!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            const SizedBox(height: 28),

            // Progress circle
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: goal.progress,
                      strokeWidth: 12,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(displayColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${goal.progressPercent}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: displayColor,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    label: 'Saved',
                    value: _currencyFormat.format(goal.currentAmount),
                    color: displayColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'Target',
                    value: _currencyFormat.format(goal.targetAmount),
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'Remaining',
                    value: _currencyFormat.format(goal.remaining),
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (goal.deadlineDate != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.primaryContainer),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Date',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          DateFormat('MMMM d, yyyy')
                              .format(goal.deadlineDate!),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (!goal.isCompleted) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Re-trigger add funds from parent — rebuild via stream
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.electricGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Add Funds',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
