import 'package:pocketbase/pocketbase.dart';
import 'package:real_banking/services/pb_service.dart';
import 'package:real_banking/models/user_model.dart';

class AuthService {
  PocketBase get _pb => PbService.instance.pb;

  // ── Auth state helpers ────────────────────────────────────────────────────

  bool get isLoggedIn => PbService.instance.isLoggedIn;

  String? get currentUserId => PbService.instance.currentUserId;

  RecordModel? get currentRecord => PbService.instance.currentUser;

  // ── Email / password sign-in ──────────────────────────────────────────────

  Future<RecordAuth> signIn({
    required String email,
    required String password,
  }) async {
    return await _pb.collection('users').authWithPassword(email, password);
  }

  // ── Registration ──────────────────────────────────────────────────────────

  Future<RecordModel> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Deterministic account number + TCC code from a temp random id
    // (will be replaced once we have the real PocketBase id).
    final tempSeed = DateTime.now().millisecondsSinceEpoch.toString();
    final accountNumber = _deriveAccountNumber(tempSeed);
    final tccCode = _deriveTccCode(tempSeed);

    final record = await _pb.collection('users').create(body: {
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'fullName': fullName,
      'balance': 0.0,
      'accountStatus': 'pending',
      'canTransact': false,
      'kycStatus': 'not_submitted',
      'accountNumber': accountNumber,
      'tccCode': tccCode,
    });

    // Immediately authenticate so the app gets a valid auth token
    await _pb.collection('users').authWithPassword(email, password);

    // Patch the account number / tcc with values derived from the real id
    try {
      await _pb.collection('users').update(record.id, body: {
        'accountNumber': _deriveAccountNumber(record.id),
        'tccCode': _deriveTccCode(record.id),
      });
    } catch (_) {
      // Non-critical — the temp values still work
    }

    return record;
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await PbService.instance.signOut();
  }

  // ── Password reset ────────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    await _pb.collection('users').requestPasswordReset(email);
  }

  // ── Real-time user stream (simulate with polling + subscribe) ─────────────
  // PocketBase uses subscribe/unsubscribe rather than Dart streams.
  // Screens that need live updates should call PbService.instance.pb
  // .collection('users').subscribe(userId, callback) directly.

  Future<UserModel?> getUserOnce(String userId) async {
    try {
      final record = await _pb.collection('users').getOne(userId);
      return UserModel.fromRecord(record);
    } catch (_) {
      return null;
    }
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<RecordModel>> getTransactions(String userId,
      {int page = 1, int perPage = 50}) async {
    final result = await _pb.collection('transactions').getList(
          page: page,
          perPage: perPage,
          filter: 'userId = "$userId"',
          sort: '-created',
        );
    return result.items;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _deriveAccountNumber(String seed) {
    int h = 0;
    for (int i = 0; i < seed.length; i++) {
      h = ((h * 31) + seed.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return (10000000 + (h % 89999999)).toString();
  }

  static String _deriveTccCode(String seed) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (i) => chars[(seed.codeUnitAt(i % seed.length) + i * 7) % chars.length],
    ).join();
  }
}
