import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nabd/main.dart';
import 'package:nabd/features/reminders/presentation/reminders_screen.dart';

void main() {
  testWidgets('NabdApp smoke test builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NabdApp(),
      ),
    );
    expect(find.byType(NabdApp), findsOneWidget);
  });

  testWidgets('RemindersScreen builds and shows alarm banner', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RemindersScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(RemindersScreen), findsOneWidget);
    expect(find.text('منبه طبي عالي الصوت والأولوية'), findsOneWidget);
  });
}
