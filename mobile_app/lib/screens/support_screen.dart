import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/models/support_ticket_model.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/screens/submit_ticket_screen.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chat message model
// ─────────────────────────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isBot;
  final bool isTyping;

  const _ChatMessage({
    required this.text,
    required this.isBot,
    this.isTyping = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Support Screen
// ─────────────────────────────────────────────────────────────────────────────
class SupportScreen extends StatefulWidget {
  final String uid;
  final String userName;
  final String userEmail;

  const SupportScreen({
    super.key,
    required this.uid,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // ── Chat state ─────────────────────────────────────────────────────────────
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Hi! I\'m STCU virtual assistant. Tap a question below to get started.',
      isBot: true,
    ),
  ];
  bool _isTyping = false;

  static const _botReplies = <String, String>{
    'How do I send money?':
        'To send money: go to Home → Send Money, enter the recipient\'s email, the amount, and confirm with your TCC code. Funds transfer instantly to other Nexus accounts.',
    'What is my TCC code?':
        'Your TCC (Transaction Confirmation Code) is a 4–6 digit PIN used to authorise transfers and sensitive actions. You can change it in Settings → Security → TCC Code.',
    'How to add funds?':
        'To add funds: tap "Add Money" on the Home screen, enter the amount, and follow the on-screen steps. Deposits are reflected in your balance immediately after processing.',
    'How to contact support?':
        'You can submit a support ticket right here, call us at 1-800-STCU-BNK, or email support@stcu.com. Our team responds within 24 hours on business days.',
  };

  static const _faqs = <Map<String, String>>[
    {
      'q': 'How do I send money?',
      'a':
          'Go to Home → Send Money. Enter the recipient\'s email, amount, and confirm with your TCC code. The money will be transferred instantly to other Nexus accounts.',
    },
    {
      'q': 'What is a TCC code?',
      'a':
          'TCC (Transaction Confirmation Code) is a 4–6 digit security PIN used to authorise transactions. You can change it under Settings → Security → TCC Code.',
    },
    {
      'q': 'How do I reset my password?',
      'a':
          'Go to Settings → Account → Change Password, or tap "Forgot Password" on the login screen. A password-reset link will be sent to your registered email address.',
    },
    {
      'q': 'Why is my account pending?',
      'a':
          'New accounts require admin approval. Please allow up to 1 business day while an administrator reviews and activates your account. You will be notified by email.',
    },
    {
      'q': 'How do I freeze my card?',
      'a':
          'Go to your virtual card screen and tap the Freeze toggle. Your card will be temporarily disabled for all new transactions until you unfreeze it.',
    },
    {
      'q': 'What are savings goals?',
      'a':
          'Savings goals let you set financial targets (e.g. "Holiday Fund") and track your progress. You can move funds from your main balance into each goal at any time.',
    },
    {
      'q': 'How do I pay bills?',
      'a':
          'Tap "Pay Bills" on the Home screen. Select a category, choose a provider, enter the amount, and confirm with your TCC code. Most bills are processed same-day.',
    },
    {
      'q': 'How do I add funds to my account?',
      'a':
          'Tap "Add Money" on the Home screen. Enter the desired amount and follow the on-screen instructions. Funds are reflected in your balance after processing.',
    },
    {
      'q': 'What should I do if I notice an unauthorised transaction?',
      'a':
          'Immediately freeze your card via the card screen, then submit a support ticket describing the transaction. Our fraud team will investigate within 24 hours.',
    },
    {
      'q': 'How do I update my personal information?',
      'a':
          'Go to Profile → Edit Profile to update your name, phone number, or address. For email changes, please contact support as additional verification is required.',
    },
  ];

  void _handleQuestionTap(String question) {
    if (_isTyping) return;
    setState(() {
      _messages.add(_ChatMessage(text: question, isBot: false));
      _isTyping = true;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: _botReplies[question] ??
              'I\'m not sure about that. Please submit a support ticket and our team will assist you.',
          isBot: true,
        ));
      });
    });
  }

  // ── Contact action ─────────────────────────────────────────────────────────
  void _copyAndSnack(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            pinned: true,
            title: const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Hero card ────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryContainer.withOpacity(0.18),
                        AppColors.background,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    color: AppColors.surfaceContainerLow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.electricGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.headset_mic_rounded,
                            size: 30, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'How can we help?',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Find answers or reach out to our team',
                        style: TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── SECTION: Live Chat ────────────────────────────────────────
                _sectionLabel('LIVE CHAT'),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Chat bubble list
                      Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount:
                              _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isTyping && index == _messages.length) {
                              return _TypingIndicator();
                            }
                            final msg = _messages[index];
                            return _ChatBubble(message: msg);
                          },
                        ),
                      ),
                      // Question chips
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _botReplies.keys.map((q) {
                            return GestureDetector(
                              onTap: () => _handleQuestionTap(q),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primaryContainer
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  q,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── SECTION: FAQ ──────────────────────────────────────────────
                _sectionLabel('FREQUENTLY ASKED QUESTIONS'),
                const SizedBox(height: 12),

                ...(_faqs.map((faq) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          iconColor: AppColors.onSurfaceVariant,
                          collapsedIconColor: AppColors.onSurfaceVariant,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryContainer.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.help_outline_rounded,
                              color: AppColors.primaryContainer,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            faq['q']!,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Text(
                              faq['a']!,
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))),
                const SizedBox(height: 24),

                // ── Submit ticket button ──────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubmitTicketScreen(
                        uid: widget.uid,
                        userName: widget.userName,
                        userEmail: widget.userEmail,
                      ),
                    ),
                  ),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.electricGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primaryContainer.withOpacity(0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Submit a Support Ticket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── My submitted tickets ──────────────────────────────────────
                _sectionLabel('MY TICKETS'),
                const SizedBox(height: 12),

                FutureBuilder<List<RecordModel>>(
                  future: PbService.instance.pb
                      .collection('support_tickets')
                      .getFullList(
                        filter: 'userId="${widget.uid}"',
                        sort: '-created',
                      ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                              color: AppColors.primaryContainer),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  size: 36),
                              SizedBox(height: 10),
                              Text(
                                'No tickets submitted yet',
                                style: TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: snapshot.data!.map((r) {
                        final ticket = SupportTicketModel.fromRecord(r);
                        return _TicketCard(ticket: ticket);
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // ── Call Us / Email Us ────────────────────────────────────────
                _sectionLabel('CONTACT US'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.phone_rounded,
                        label: 'Call Us',
                        value: '1-800-STCU-BNK',
                        color: AppColors.success,
                        onTap: () => _copyAndSnack(
                            context, '1-800-STCU-BNK', 'Phone number'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.email_rounded,
                        label: 'Email Us',
                        value: 'support@stcu.com',
                        color: AppColors.primaryContainer,
                        onTap: () => _copyAndSnack(context,
                            'support@stcu.com', 'Email address'),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat bubble widget
// ─────────────────────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.electricGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot
                    ? AppColors.surfaceContainerHigh
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isBot ? 4 : 16),
                  bottomRight: Radius.circular(isBot ? 16 : 4),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isBot ? AppColors.onSurface : Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing indicator
// ─────────────────────────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 140), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.electricGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _animations[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _animations[i].value),
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      decoration: BoxDecoration(
                        color:
                            AppColors.onSurfaceVariant.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticket card widget
// ─────────────────────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final SupportTicketModel ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final statusConfig = <String, Map<String, dynamic>>{
      'open': {'color': AppColors.primaryContainer, 'label': 'Open'},
      'in-progress': {'color': AppColors.warning, 'label': 'In Progress'},
      'resolved': {'color': AppColors.success, 'label': 'Resolved'},
      'closed': {
        'color': AppColors.onSurfaceVariant,
        'label': 'Closed'
      },
    };
    final config = statusConfig[ticket.status] ??
        {'color': AppColors.onSurfaceVariant, 'label': ticket.status};
    final color = config['color'] as Color;
    final label = config['label'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            ticket.dateTime != null
                ? DateFormat('MMM d, yyyy').format(ticket.dateTime!)
                : '',
            style: const TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 11),
          ),
          if (ticket.adminReply != null &&
              ticket.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: AppColors.success, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket.adminReply!,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact button widget
// ─────────────────────────────────────────────────────────────────────────────
class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Icon(Icons.copy_rounded,
                    color: color.withOpacity(0.5), size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
