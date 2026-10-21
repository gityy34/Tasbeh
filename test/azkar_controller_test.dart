import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/controllers/azkar_controller.dart';
import 'package:tasbeh/models/azkar_models.dart';
import 'package:tasbeh/repositories/azkar_repository.dart';
import 'package:tasbeh/services/azkar_pdf_service.dart';

void main() {
  test('PDF metadata and daily Azkar text persist and restore', () async {
    final repository = MemoryAzkarRepository();
    final first = AzkarController(
      repository: repository,
      pdfService: FakeAzkarPdfService(),
    );
    await first.initialize();

    expect(await first.uploadPdf(AzkarCategory.morningEvening), isTrue);
    await first.saveDailyEntry(text: 'صبح کے اذکار');
    await first.saveDailyEntry(text: 'شام کے اذکار');

    final restored = AzkarController(
      repository: repository,
      pdfService: FakeAzkarPdfService(),
    );
    await restored.initialize();

    expect(restored.pdfFor(AzkarCategory.morningEvening)?.pageCount, 3);
    expect(restored.dailyEntries.map((entry) => entry.text), [
      'صبح کے اذکار',
      'شام کے اذکار',
    ]);
  });

  test('editing and deleting daily Azkar entries updates persistence', () async {
    final repository = MemoryAzkarRepository();
    final controller = AzkarController(
      repository: repository,
      pdfService: FakeAzkarPdfService(),
    );
    await controller.initialize();
    await controller.saveDailyEntry(text: 'Original text');

    final id = controller.dailyEntries.single.id;
    await controller.saveDailyEntry(id: id, text: 'Edited text');
    expect(controller.dailyEntries.single.text, 'Edited text');

    await controller.deleteDailyEntry(id);
    expect(controller.dailyEntries, isEmpty);
  });
}

class FakeAzkarPdfService implements AzkarPdfService {
  @override
  Future<PickedAzkarPdf?> pickAndStore(AzkarCategory category) async {
    return PickedAzkarPdf(
      path: '/private/azkar/${category.key}.pdf',
      displayName: '${category.key}.pdf',
      pageCount: 3,
    );
  }

  @override
  Future<Uint8List> renderPage({
    required String path,
    required int pageIndex,
    required int maxWidth,
  }) async => Uint8List.fromList(const <int>[1, 2, 3]);

  @override
  Future<void> delete(String path) async {}
}
