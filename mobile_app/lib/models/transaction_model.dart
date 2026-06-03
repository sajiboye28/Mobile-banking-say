import 'package:pocketbase/pocketbase.dart';

class TransactionModel {
  final String transactionId;
  final String userId;
  final double amount;
  final String type; // 'Credit' or 'Debit'
  final DateTime? timestamp;
  final String description;
  final String status; // 'Success', 'Pending', 'Failed'
  final String? relatedUserId;
  final String? relatedUserName;
  final String? relatedUserEmail;
  final String? note;

  TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.type,
    this.timestamp,
    required this.description,
    required this.status,
    this.relatedUserId,
    this.relatedUserName,
    this.relatedUserEmail,
    this.note,
  });

  /// Build from a PocketBase [RecordModel].
  factory TransactionModel.fromRecord(RecordModel record) {
    final d = record.data;

    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    return TransactionModel(
      transactionId: d['transactionId'] as String? ?? record.id,
      userId: d['userId'] as String? ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      type: d['type'] as String? ?? 'Debit',
      timestamp: _parseDate(d['timestamp']) ?? _parseDate(d['created']),
      description: d['description'] as String? ?? '',
      status: d['status'] as String? ?? 'Pending',
      relatedUserId: d['relatedUserId'] as String?,
      relatedUserName: d['relatedUserName'] as String?,
      relatedUserEmail: d['relatedUserEmail'] as String?,
      note: d['note'] as String?,
    );
  }

  bool get isCredit => type == 'Credit';
  bool get isDebit => type == 'Debit';
  bool get isSuccess => status == 'Success';

  DateTime? get dateTime => timestamp;
}
