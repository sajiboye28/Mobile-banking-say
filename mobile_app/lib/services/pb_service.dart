import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_banking/services/app_config.dart';

class PbService {
  static PbService? _instance;
  late final PocketBase pb;

  PbService._(String? initialAuth) {
    pb = PocketBase(
      kPbUrl,
      authStore: AsyncAuthStore(
        save: (String data) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pb_auth', data);
        },
        clear: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pb_auth');
        },
        initial: initialAuth,
      ),
    );
  }

  static PbService get instance {
    _instance ??= PbService._(null);
    return _instance!;
  }

  /// Call once at startup to restore a persisted auth session.
  static Future<PbService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAuth = prefs.getString('pb_auth');
    final instance = PbService._(savedAuth);
    _instance = instance;
    return instance;
  }

  /// Sign the user out and wipe the persisted token.
  Future<void> signOut() async {
    pb.authStore.clear();
  }

  bool get isLoggedIn => pb.authStore.isValid;

  RecordModel? get currentUser => pb.authStore.record;

  String? get currentUserId => pb.authStore.record?.id;

  String? get authToken => pb.authStore.token;
}
