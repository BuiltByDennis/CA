import 'package:go_router/go_router.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/role_picker_screen.dart';
import '../features/buyer/buyer_dashboard.dart';
import '../features/buyer/scan_screen.dart';
import '../features/seller_integrated/integrated_dashboard.dart';
import '../features/seller_integrated/capture_screen.dart';
import '../features/seller_manual/manual_dashboard.dart';
import '../features/seller_manual/new_receipt_screen.dart';
import '../features/shared/history_screen.dart';

final caRouter = GoRouter(routes: [
  GoRoute(path: '/', builder: (context, state) => const AuthGate()),
  GoRoute(path: '/home', builder: (context, state) => const RolePickerScreen()),
  GoRoute(path: '/buyer', builder: (context, state) => const BuyerDashboard()),
  GoRoute(path: '/buyer/scan', builder: (context, state) => const ScanScreen()),
  GoRoute(path: '/buyer/history', builder: (context, state) => const HistoryScreen(title: 'My Receipts', direction: 'saved')),
  GoRoute(path: '/seller-integrated', builder: (context, state) => const IntegratedDashboard()),
  GoRoute(path: '/seller-integrated/capture', builder: (context, state) => const CaptureScreen()),
  GoRoute(path: '/seller-integrated/history', builder: (context, state) => const HistoryScreen(title: 'Receipt History', direction: 'issued')),
  GoRoute(path: '/seller-manual', builder: (context, state) => const ManualDashboard()),
  GoRoute(path: '/seller-manual/new', builder: (context, state) => const NewReceiptScreen()),
  GoRoute(path: '/seller-manual/design', builder: (context, state) => const DesignReceiptScreen()),
  GoRoute(path: '/seller-manual/key', builder: (context, state) => const SellerKeyScreen()),
  GoRoute(path: '/seller-manual/history', builder: (context, state) => const HistoryScreen(title: 'Receipt History', direction: 'issued')),
]);
