import 'package:pocketbase/pocketbase.dart';

class UserModel {
  final String id; // PocketBase record id (replaces Firebase uid)
  final String email;
  final String fullName;
  final double balance;
  final String? accountNumber;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final String accountType; // savings, checking, premium, business, student, joint
  final String accountStatus; // active, pending, suspended, closed, frozen
  final bool canTransact;
  final String tccCode;
  final String kycStatus; // not_submitted, pending, approved, rejected, unverified
  final String profilePicUrl;
  final bool twoFaEnabled;
  final bool loginAlertsEnabled;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.balance,
    this.accountNumber,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.accountType = 'savings',
    this.accountStatus = 'pending',
    this.canTransact = false,
    this.tccCode = '',
    this.kycStatus = 'not_submitted',
    this.profilePicUrl = '',
    this.twoFaEnabled = false,
    this.loginAlertsEnabled = false,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  /// Build a UserModel from a PocketBase [RecordModel].
  factory UserModel.fromRecord(RecordModel record) {
    final d = record.data;

    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    return UserModel(
      id: record.id,
      email: d['email'] as String? ?? '',
      fullName: d['fullName'] as String? ?? '',
      balance: (d['balance'] ?? 0).toDouble(),
      accountNumber: d['accountNumber'] as String?,
      phone: d['phone'] as String?,
      address: d['address'] as String?,
      city: d['city'] as String?,
      country: d['country'] as String?,
      postalCode: d['postalCode'] as String?,
      accountType: d['accountType'] as String? ?? 'savings',
      accountStatus: d['accountStatus'] as String? ?? 'pending',
      canTransact: d['canTransact'] as bool? ?? false,
      tccCode: d['tccCode'] as String? ?? '',
      kycStatus: d['kycStatus'] as String? ?? 'not_submitted',
      profilePicUrl: d['profilePicUrl'] as String? ?? '',
      twoFaEnabled: d['two_fa_enabled'] as bool? ?? false,
      loginAlertsEnabled: d['login_alerts_enabled'] as bool? ?? false,
      fcmToken: d['fcmToken'] as String?,
      createdAt: _parseDate(d['created']),
      updatedAt: _parseDate(d['updated']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'balance': balance,
        'accountNumber': accountNumber,
        'phone': phone,
        'address': address,
        'city': city,
        'country': country,
        'postalCode': postalCode,
        'accountType': accountType,
        'accountStatus': accountStatus,
        'canTransact': canTransact,
        'tccCode': tccCode,
        'kycStatus': kycStatus,
        'profilePicUrl': profilePicUrl,
        'two_fa_enabled': twoFaEnabled,
        'login_alerts_enabled': loginAlertsEnabled,
        'fcmToken': fcmToken,
      };

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get isActive => accountStatus == 'active';
  bool get isSuspended => accountStatus == 'suspended';
  bool get isPending => accountStatus == 'pending';
  bool get isClosed => accountStatus == 'closed';
  bool get isFrozen => accountStatus == 'frozen';

  bool get isKycVerified => kycStatus == 'approved';
  bool get isKycPending => kycStatus == 'pending';
  bool get isKycRejected => kycStatus == 'rejected';

  /// Backwards-compat alias so existing code using `.uid` still compiles.
  String get uid => id;

  String get accountTypeDisplay {
    switch (accountType) {
      case 'checking':
        return 'Checking Account';
      case 'premium':
        return 'Premium Account';
      case 'business':
        return 'Business Account';
      case 'student':
        return 'Student Account';
      case 'joint':
        return 'Joint Account';
      default:
        return 'Savings Account';
    }
  }

  /// Deterministic 8-digit account number derived from [id] (used when
  /// the [accountNumber] field is absent from the PocketBase record).
  String get accountNumberDisplay {
    if (accountNumber != null && accountNumber!.isNotEmpty) {
      return accountNumber!;
    }
    int h = 0;
    for (int i = 0; i < id.length; i++) {
      h = ((h * 31) + id.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return (10000000 + (h % 89999999)).toString();
  }

  /// Alias kept for screens that reference `.accountNumber` as a getter.
  String get accountNumberValue => accountNumberDisplay;

  String get maskedAccount {
    final n = accountNumberDisplay;
    return '••••• ${n.substring(n.length - 3)}';
  }

  /// Fixed routing number for Nexus Bank.
  static const String routingNumber = '026073150';
}
