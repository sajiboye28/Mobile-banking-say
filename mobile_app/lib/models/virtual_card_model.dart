import 'package:pocketbase/pocketbase.dart';

class VirtualCardModel {
  final String cardId;
  final String userId;
  final String cardNumber;
  final String cvv;
  final int expiryMonth;
  final int expiryYear;
  final String cardholderName;
  final bool isFrozen;
  final double dailyLimit;
  final double monthlyLimit;
  final DateTime? createdAt;

  VirtualCardModel({
    required this.cardId,
    required this.userId,
    required this.cardNumber,
    required this.cvv,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
    required this.isFrozen,
    this.dailyLimit = 0,
    this.monthlyLimit = 0,
    this.createdAt,
  });

  factory VirtualCardModel.fromRecord(RecordModel record) {
    final data = record.data;
    return VirtualCardModel(
      cardId: record.id,
      userId: data['userId'] as String? ?? '',
      cardNumber: data['cardNumber'] as String? ?? '',
      cvv: data['cvv'] as String? ?? '',
      expiryMonth: (data['expiryMonth'] as num?)?.toInt() ?? 1,
      expiryYear: (data['expiryYear'] as num?)?.toInt() ?? 2028,
      cardholderName: data['cardholderName'] as String? ?? '',
      isFrozen: data['isFrozen'] as bool? ?? false,
      dailyLimit: (data['dailyLimit'] ?? 0).toDouble(),
      monthlyLimit: (data['monthlyLimit'] ?? 0).toDouble(),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  String get maskedNumber {
    if (cardNumber.length < 16) return cardNumber;
    return '\u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 ${cardNumber.substring(12)}';
  }

  String get formattedNumber {
    if (cardNumber.length < 16) return cardNumber;
    return '${cardNumber.substring(0, 4)} ${cardNumber.substring(4, 8)} ${cardNumber.substring(8, 12)} ${cardNumber.substring(12)}';
  }

  String get expiryFormatted =>
      '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';
}
