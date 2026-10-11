import 'db/app_db.dart';

/// Simple service holder for Phase 1 (Riverpod providers wrap these in Phase 4
/// if/when state management needs it — screens must not build their own DB).
class AppServices {
  static final AppDb db = AppDb();
}
