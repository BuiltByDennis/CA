import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ca_receipt/main.dart';

void main() {
  testWidgets('CA opens on the role picker', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CaApp()));
    await tester.pumpAndSettle();
    expect(find.text('How will you use CA?'), findsOneWidget);
    expect(find.text('Buyer'), findsOneWidget);
  });
}
