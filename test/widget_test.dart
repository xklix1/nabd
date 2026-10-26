import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nabd/main.dart';

void main() {
  testWidgets('NabdApp smoke test builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NabdApp(),
      ),
    );
    expect(find.byType(NabdApp), findsOneWidget);
  });
}
