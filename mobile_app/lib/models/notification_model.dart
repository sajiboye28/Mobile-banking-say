import 'package:pocketbase/pocketbase.dart';

class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String body;
  final String type; // transaction, account, announcement, request
  final bool isRead;
  final String? relatedId;
  final DateTime? createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.relatedId,
    this.createdAt,
  });

  factory NotificationModel.fromRecord(RecordModel record) {
    final data = record.data;

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return NotificationModel(
      notificationId: record.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'account',
      isRead: data['isRead'] as bool? ?? false,
      relatedId: data['relatedId'] as String?,
      createdAt: parseDate(data['createdAt']) ?? parseDate(record.created),
    );
  }

  DateTime? get dateTime => createdAt;

  IconType get iconType {
    switch (type) {
      case 'transaction':
        return IconType.transaction;
      case 'request':
        return IconType.request;
      case 'announcement':
        return IconType.announcement;
      default:
        return IconType.account;
    }
  }
}

enum IconType { transaction, account, announcement, request }
