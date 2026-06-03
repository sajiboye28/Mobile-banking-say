import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/models/notification_model.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/theme/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  final String uid;

  const NotificationsScreen({super.key, required this.uid});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<RecordModel>? _records;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final records = await PbService.instance.pb
          .collection('notifications')
          .getFullList(filter: 'userId="${widget.uid}"', sort: '-created');
      if (mounted) setState(() { _records = records; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _records = []; _loading = false; });
    }
  }

  List<NotificationModel> _getSorted() {
    final list = (_records ?? [])
        .map((r) => NotificationModel.fromRecord(r))
        .toList()
      ..sort((a, b) {
        final aT = a.dateTime;
        final bT = b.dateTime;
        if (aT == null && bT == null) return 0;
        if (aT == null) return 1;
        if (bT == null) return -1;
        return bT.compareTo(aT);
      });
    return list;
  }

  Future<void> _markAsRead(String notificationId) async {
    await PbService.instance.pb
        .collection('notifications')
        .update(notificationId, body: {'isRead': true});
    _loadNotifications();
  }

  Future<void> _markAllAsRead(List<NotificationModel> notifications) async {
    final pb = PbService.instance.pb;
    for (final notification in notifications) {
      if (!notification.isRead) {
        await pb.collection('notifications')
            .update(notification.notificationId, body: {'isRead': true});
      }
    }
    _loadNotifications();
  }

  Future<void> _deleteNotification(String notificationId) async {
    await PbService.instance.pb
        .collection('notifications')
        .delete(notificationId);
    _loadNotifications();
  }

  String _getDateSection(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDate = DateTime(date.year, date.month, date.day);
    if (notifDate == today) return 'Today';
    if (notifDate == yesterday) return 'Yesterday';
    return 'Earlier';
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'transaction': return Icons.arrow_circle_right_rounded;
      case 'account': return Icons.shield_rounded;
      case 'announcement': return Icons.campaign_rounded;
      case 'request': return Icons.request_page_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'transaction': return AppColors.primaryContainer;
      case 'account': return AppColors.success;
      case 'announcement': return AppColors.warning;
      case 'request': return AppColors.error;
      default: return AppColors.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            pinned: true,
            title: const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              Builder(builder: (context) {
                final notifications = _getSorted();
                final unreadCount = notifications.where((n) => !n.isRead).length;
                if (unreadCount == 0) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded,
                          color: AppColors.primary),
                      tooltip: 'Mark all as read',
                      onPressed: () async {
                        await _markAllAsRead(notifications);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('All notifications marked as read'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
          Builder(
            builder: (context) {
              if (_loading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryContainer),
                  ),
                );
              }

              final notifications = _getSorted();

              if (notifications.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              final Map<String, List<NotificationModel>> grouped = {};
              for (final n in notifications) {
                final section = n.dateTime != null
                    ? _getDateSection(n.dateTime!)
                    : 'Earlier';
                grouped.putIfAbsent(section, () => []);
                grouped[section]!.add(n);
              }

              final orderedSections = <String>[];
              if (grouped.containsKey('Today')) orderedSections.add('Today');
              if (grouped.containsKey('Yesterday')) orderedSections.add('Yesterday');
              if (grouped.containsKey('Earlier')) orderedSections.add('Earlier');

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, sectionIndex) {
                      final section = orderedSections[sectionIndex];
                      final sectionNotifications = grouped[section]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sectionIndex > 0) const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 4),
                            child: Text(
                              section.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ...sectionNotifications.map(_buildNotificationCard),
                        ],
                      );
                    },
                    childCount: orderedSections.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 36,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You're all caught up!\nWe'll notify you when something happens.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = !notification.isRead;
    final iconColor = _getIconColor(notification.type);

    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _deleteNotification(notification.notificationId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification dismissed'),
            backgroundColor: AppColors.primaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () {
          if (isUnread) _markAsRead(notification.notificationId);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.primaryContainer.withOpacity(0.06)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Unread accent bar
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? AppColors.primaryContainer
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIcon(notification.type),
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontWeight: isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 7,
                                      height: 7,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notification.body,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notification.dateTime != null
                                        ? _timeAgo(notification.dateTime!)
                                        : 'Just now',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isUnread)
                                    GestureDetector(
                                      onTap: () => _markAsRead(notification.notificationId),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Mark as read',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
          ),
        ),
      ),
    );
  }
}
