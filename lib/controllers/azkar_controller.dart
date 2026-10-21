import 'package:flutter/foundation.dart';

import '../models/azkar_models.dart';
import '../repositories/azkar_repository.dart';
import '../services/azkar_pdf_service.dart';

class AzkarController extends ChangeNotifier {
  AzkarController({
    required AzkarRepository repository,
    required AzkarPdfService pdfService,
  })  : _repository = repository,
        _pdfService = pdfService;

  final AzkarRepository _repository;
  final AzkarPdfService _pdfService;

  AzkarLibrary _library = const AzkarLibrary.empty();
  bool _initialized = false;
  bool _busy = false;

  AzkarLibrary get library => _library;
  List<AzkarPdfDocument> get pdfs => List.unmodifiable(_library.pdfs);
  List<DailyAzkarEntry> get dailyEntries =>
      List.unmodifiable(_library.dailyEntries);
  bool get isBusy => _busy;
  AzkarPdfService get pdfService => _pdfService;

  Future<void> initialize() async {
    if (_initialized) return;
    _library = await _repository.read();
    _initialized = true;
    notifyListeners();
  }

  AzkarPdfDocument? pdfFor(AzkarCategory category) => _library.pdfFor(category);

  Future<bool> uploadPdf(AzkarCategory category) async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      final picked = await _pdfService.pickAndStore(category);
      if (picked == null) return false;
      final previous = _library.pdfFor(category);
      final document = AzkarPdfDocument(
        category: category,
        localPath: picked.path,
        displayName: picked.displayName,
        pageCount: picked.pageCount,
        savedAt: DateTime.now(),
      );
      final pdfs = [
        for (final pdf in _library.pdfs)
          if (pdf.category != category) pdf,
        document,
      ];
      _library = AzkarLibrary(
        pdfs: pdfs,
        dailyEntries: _library.dailyEntries,
      );
      await _repository.write(_library);
      if (previous != null && previous.localPath != document.localPath) {
        await _pdfService.delete(previous.localPath);
      }
      return true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> removePdf(AzkarCategory category) async {
    final document = _library.pdfFor(category);
    if (document == null) return;
    _library = AzkarLibrary(
      pdfs: _library.pdfs
          .where((pdf) => pdf.category != category)
          .toList(growable: false),
      dailyEntries: _library.dailyEntries,
    );
    await _repository.write(_library);
    await _pdfService.delete(document.localPath);
    notifyListeners();
  }

  Future<void> saveDailyEntry({String? id, required String text}) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    final now = DateTime.now();
    final entryId = id ?? now.microsecondsSinceEpoch.toString();
    final existing = _library.dailyEntries.indexWhere(
      (entry) => entry.id == entryId,
    );
    final entry = DailyAzkarEntry(
      id: entryId,
      text: cleaned,
      savedAt: now,
    );
    final entries = [..._library.dailyEntries];
    if (existing == -1) {
      entries.add(entry);
    } else {
      entries[existing] = entry;
    }
    _library = AzkarLibrary(pdfs: _library.pdfs, dailyEntries: entries);
    await _repository.write(_library);
    notifyListeners();
  }

  Future<void> deleteDailyEntry(String id) async {
    _library = AzkarLibrary(
      pdfs: _library.pdfs,
      dailyEntries: _library.dailyEntries
          .where((entry) => entry.id != id)
          .toList(growable: false),
    );
    await _repository.write(_library);
    notifyListeners();
  }
}
