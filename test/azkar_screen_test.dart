import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/controllers/azkar_controller.dart';
import 'package:tasbeh/repositories/azkar_repository.dart';
import 'package:tasbeh/screens/azkar_screen.dart';
import 'package:tasbeh/models/azkar_models.dart';

import 'azkar_controller_test.dart' show FakeAzkarPdfService;

void main() {
  testWidgets('daily Azkar saves pages and moves with arrows', (tester) async {
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

    expect(find.byKey(const ValueKey<String>('daily-azkar-back')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey<String>('daily-azkar-editor')),
      'Page one Azkar',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-daily-azkar')));
    await tester.pump();
    expect(controller.dailyEntries.single.text, 'Page one Azkar');

    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-next')));
    await tester.pump();
    expect(find.text('Page 2 of 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('daily-azkar-editor')),
      'Page two Azkar',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-daily-azkar')));
    await tester.pump();
    expect(controller.dailyEntries, hasLength(2));

    await tester.tap(find.byKey(const ValueKey<String>('daily-azkar-back')));
    await tester.pump();
    expect(find.text('Page 1 of 2'), findsOneWidget);
    final editor = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('daily-azkar-editor')),
    );
    expect(editor.controller?.text, 'Page one Azkar');
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
