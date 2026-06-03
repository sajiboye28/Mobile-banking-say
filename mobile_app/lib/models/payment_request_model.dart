import 'package:pocketbase/pocketbase.dart';

class PaymentRequestModel {
  final String requestId;
  final String fromUid;
  final String fromName;
  final String fromEmail;
  final String toUid;
  final String toName;
  final String toEmail;
  final double amount;
  final String note;
  final String status; // pending, accepted, declined, cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentRequestModel({
    required this.requestId,
    required this.fromUid,
    required this.fromName,
    required this.fromEmail,
    required this.toUid,
    required this.toName,
    required this.toEmail,
    required this.amount,
    required this.note,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentRequestModel.fromRecord(RecordModel record) {
    final data = record.data;
    return PaymentRequestModel(
      requestId: record.id,
      fromUid: data['fromUid'] ?? '',
      fromName: data['fromName'] ?? '',
      fromEmail: data['fromEmail'] ?? '',
      toUid: data['toUid'] ?? '',
      toName: data['toName'] ?? '',
      toEmail: data['toEmail'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      note: data['note'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? ''),
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  DateTime? get dateTime => createdAt;
}
