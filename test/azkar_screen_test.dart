import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/controllers/azkar_controller.dart';
import 'package:tasbeh/models/azkar_models.dart';
import 'package:tasbeh/repositories/azkar_repository.dart';
import 'package:tasbeh/screens/azkar_screen.dart';

import 'azkar_controller_test.dart' show FakeAzkarPdfService;

void main() {
  testWidgets('daily Azkar starts read-only and saves a weekly page',
      (tester) async {
    final controller = AzkarController(
      repository: MemoryAzkarRepository(),
      pdfService: FakeAzkarPdfService(),
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: DailyAzkarScreen(controller: controller),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('daily-azkar-read-only')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('daily-azkar-text-input')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-edit')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('daily-azkar-text-input')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('daily-azkar-text-input')),
      'Monday Azkar',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('daily-azkar-title')),
      'Morning Monday',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('daily-azkar-save')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-save')));
    await tester.pumpAndSettle();

    expect(controller.dailyEntries.single.text, 'Monday Azkar');
    expect(controller.dailyEntries.single.weekday, 1);
    expect(
      find.byKey(const ValueKey<String>('daily-azkar-read-only')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('daily-azkar-text-input')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-next')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-edit')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('daily-azkar-text-input')),
      'Tuesday Azkar',
    );
    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-save')));
    await tester.pumpAndSettle();

    expect(controller.dailyEntries, hasLength(2));
    expect(controller.dailyEntryForWeekday(2)?.text, 'Tuesday Azkar');

    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-back')));
    await tester.pump();
    expect(find.text('Monday Azkar'), findsOneWidget);
  });

  testWidgets('notification editor exposes weekly morning and evening times',
      (tester) async {
    final controller = AzkarController(
      repository: MemoryAzkarRepository(),
      pdfService: FakeAzkarPdfService(),
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: DailyAzkarScreen(controller: controller),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-edit')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('daily-azkar-notifications')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('daily-azkar-notifications')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push Notifications'), findsOneWidget);
    expect(find.text('Morning notification'), findsOneWidget);
    expect(find.text('Evening notification'), findsOneWidget);
    expect(find.text('5:00 AM'), findsOneWidget);
    expect(find.text('5:00 PM'), findsOneWidget);

    await tester.tap(find.text('Save notification settings'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('daily-azkar-notifications')),
      findsOneWidget,
    );
  });

  testWidgets('morning and evening screen starts with local PDF upload',
      (tester) async {
    final controller = AzkarController(
      repository: MemoryAzkarRepository(),
      pdfService: FakeAzkarPdfService(),
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: MorningEveningAzkarScreen(controller: controller),
      ),
    );
    expect(find.text('Upload PDF'), findsOneWidget);

    await tester.tap(find.text('Upload PDF'));
    await tester.pump();
    expect(find.text('morning-evening.pdf'), findsOneWidget);
    expect(controller.pdfFor(AzkarCategory.morningEvening), isNotNull);
  });
}
