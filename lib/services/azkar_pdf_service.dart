import 'package:flutter/services.dart';

import '../models/azkar_models.dart';

class PickedAzkarPdf {
  const PickedAzkarPdf({
    required this.path,
    required this.displayName,
    required this.pageCount,
  });

  final String path;
  final String displayName;
  final int pageCount;
}

abstract interface class AzkarPdfService {
  Future<PickedAzkarPdf?> pickAndStore(AzkarCategory category);

  Future<Uint8List> renderPage({
    required String path,
    required int pageIndex,
    required int maxWidth,
  });

  Future<void> delete(String path);
}

class MethodChannelAzkarPdfService implements AzkarPdfService {
  const MethodChannelAzkarPdfService({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const _channelName = 'com.gityy34.tasbeh/azkar_pdf';
  final MethodChannel _channel;

  @override
  Future<PickedAzkarPdf?> pickAndStore(AzkarCategory category) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'pickPdf',
      <String, Object?>{'category': category.key},
    );
    if (result == null) return null;
    return PickedAzkarPdf(
      path: result['path'] as String,
      displayName: result['displayName'] as String,
      pageCount: (result['pageCount'] as num).toInt(),
    );
  }

  @override
  Future<Uint8List> renderPage({
    required String path,
    required int pageIndex,
    required int maxWidth,
  }) async {
    final bytes = await _channel.invokeMethod<Uint8List>(
      'renderPage',
      <String, Object?>{
        'path': path,
        'pageIndex': pageIndex,
        'maxWidth': maxWidth,
      },
    );
    if (bytes == null || bytes.isEmpty) {
      throw StateError('The selected PDF page could not be rendered.');
    }
    return bytes;
  }

  @override
  Future<void> delete(String path) async {
    await _channel.invokeMethod<void>('deletePdf', <String, Object?>{
      'path': path,
    });
  }
}
