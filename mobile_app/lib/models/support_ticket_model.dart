import 'package:pocketbase/pocketbase.dart';

class SupportTicketModel {
  final String ticketId;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String category;
  final String description;
  final String status; // open, in-progress, resolved, closed
  final String? adminReply;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SupportTicketModel({
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.category,
    required this.description,
    required this.status,
    this.adminReply,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportTicketModel.fromRecord(RecordModel record) {
    final data = record.data;
    return SupportTicketModel(
      ticketId: record.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      subject: data['subject'] ?? '',
      category: data['category'] ?? 'Other',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      adminReply: data['adminReply'] as String?,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? ''),
    );
  }

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved';
  DateTime? get dateTime => createdAt;
}
