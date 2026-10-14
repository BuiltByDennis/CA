import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ca_receipt/main.dart';

void main() {
  testWidgets('CA opens on account creation when no profile exists', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: CaApp()));
      // Let the real-async local DB check finish (it fails gracefully in the
      // test environment — no platform storage — and is treated as no profile).
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump();
    });
    expect(find.text('Create account'), findsOneWidget);
  });
}
