import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../controllers/azkar_controller.dart';
import '../models/azkar_models.dart';
import '../navigation.dart';
import '../services/azkar_pdf_service.dart';

class MorningEveningAzkarScreen extends StatefulWidget {
  const MorningEveningAzkarScreen({
    super.key,
    required this.controller,
  });

  final AzkarController controller;

  @override
  State<MorningEveningAzkarScreen> createState() =>
      _MorningEveningAzkarScreenState();
}

class _MorningEveningAzkarScreenState
    extends State<MorningEveningAzkarScreen> {
  Future<void> _upload() async {
    bool uploaded;
    try {
      uploaded = await widget.controller.uploadPdf(
        AzkarCategory.morningEvening,
      );
    } catch (_) {
      if (mounted) {
        showMessage(context, 'The PDF could not be opened. Choose a valid PDF.');
      }
      return;
    }
    if (!mounted) return;
    if (uploaded) showMessage(context, 'PDF saved on this device');
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove saved PDF?'),
        content: const Text(
          'The local PDF will be removed from this device. You can upload it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.controller.removePdf(AzkarCategory.morningEvening);
      } catch (_) {
        if (mounted) showMessage(context, 'The saved PDF could not be removed');
        return;
      }
      if (mounted) showMessage(context, 'PDF removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final document = widget.controller.pdfFor(
          AzkarCategory.morningEvening,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(AzkarCategory.morningEvening.arabicLabel),
            actions: [
              if (document != null)
                PopupMenuButton<String>(
                  tooltip: 'PDF actions',
                  onSelected: (value) {
                    if (value == 'replace') unawaited(_upload());
                    if (value == 'remove') unawaited(_remove());
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'replace',
                      child: Text('Replace PDF'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove PDF'),
                    ),
                  ],
                ),
            ],
          ),
          body: document == null
              ? _PdfEmptyState(
                  busy: widget.controller.isBusy,
                  onUpload: _upload,
                )
              : AzkarPdfViewer(
                  document: document,
                  service: widget.controller.pdfService,
                ),
        );
      },
    );
  }
}

class _PdfEmptyState extends StatelessWidget {
  const _PdfEmptyState({required this.busy, required this.onUpload});

  final bool busy;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 34,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Add your local Azkar PDF',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a PDF from your phone. It will be copied into Tasbeh storage and will remain available offline.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: busy ? null : onUpload,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(busy ? 'Saving PDF…' : 'Upload PDF'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AzkarPdfViewer extends StatefulWidget {
  const AzkarPdfViewer({
    super.key,
    required this.document,
    required this.service,
  });

  final AzkarPdfDocument document;
  final AzkarPdfService service;

  @override
  State<AzkarPdfViewer> createState() => _AzkarPdfViewerState();
}

class _AzkarPdfViewerState extends State<AzkarPdfViewer> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final pageCount = widget.document.pageCount.clamp(1, 10000).toInt();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.document.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text('${_page + 1} / $pageCount'),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth.floor().clamp(240, 1800)
                  : 720;
              final renderWidth = width.toInt();
              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: pageCount,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => _PdfPage(
                  key: ValueKey<String>(
                    '${widget.document.localPath}-$index-$renderWidth',
                  ),
                  service: widget.service,
                  path: widget.document.localPath,
                  pageIndex: index,
                  maxWidth: renderWidth,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PdfPage extends StatelessWidget {
  const _PdfPage({
    super.key,
    required this.service,
    required this.path,
    required this.pageIndex,
    required this.maxWidth,
  });

  final AzkarPdfService service;
  final String path;
  final int pageIndex;
  final int maxWidth;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: service.renderPage(
        path: path,
        pageIndex: pageIndex,
        maxWidth: maxWidth,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'This PDF page could not be displayed. Try replacing the PDF.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return InteractiveViewer(
          minScale: 0.85,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: Image.memory(
              snapshot.requireData,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text('Unable to decode this PDF page.'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DailyAzkarScreen extends StatefulWidget {
  const DailyAzkarScreen({
    super.key,
    required this.controller,
  });

  final AzkarController controller;

  @override
  State<DailyAzkarScreen> createState() => _DailyAzkarScreenState();
}

class _DailyAzkarScreenState extends State<DailyAzkarScreen> {
  late TextEditingController _textController;
  int _page = 0;

  List<DailyAzkarEntry> get _entries => widget.controller.dailyEntries;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _textForPage(0));
  }

  String _textForPage(int page) {
    return page < _entries.length ? _entries[page].text : '';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _setPage(int page) {
    _textController.value = TextEditingValue(
      text: _textForPage(page),
      selection: TextSelection.collapsed(offset: _textForPage(page).length),
    );
    setState(() => _page = page);
  }

  Future<bool> _saveCurrent({bool showConfirmation = true}) async {
    if (_textController.text.trim().isEmpty) {
      if (mounted) showMessage(context, 'Paste some Azkar text before saving');
      return false;
    }
    final id = _page < _entries.length ? _entries[_page].id : null;
    await widget.controller.saveDailyEntry(
      id: id,
      text: _textController.text,
    );
    if (mounted && showConfirmation) showMessage(context, 'Azkar text saved');
    return true;
  }

  Future<void> _next() async {
    if (!await _saveCurrent(showConfirmation: false)) return;
    _setPage(_page + 1);
  }

  Future<void> _back() async {
    if (_page == 0) return;
    _setPage(_page - 1);
  }

  @override
  Widget build(BuildContext context) {
    final total = _entries.length > _page ? _entries.length : _page + 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(AzkarCategory.daily.arabicLabel),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) => SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DailyAzkarHeader(page: _page + 1, total: total),
                      const SizedBox(height: 14),
                      TextField(
                        key: const ValueKey<String>('daily-azkar-editor'),
                        controller: _textController,
                        minLines: constraints.maxHeight < 700 ? 10 : 15,
                        maxLines: 22,
                        keyboardType: TextInputType.multiline,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          hintText: 'Paste your Azkar text here',
                          alignLabelWithHint: true,
                        ),
                        style: const TextStyle(
                          height: 1.8,
                          fontFamilyFallback: [
                            'Noto Naskh Arabic',
                            'Noto Sans Arabic',
                            'sans',
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        key: const ValueKey<String>('save-daily-azkar'),
                        onPressed: () => unawaited(_saveCurrent()),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save text'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PageArrowButton(
                            key: const ValueKey<String>('daily-azkar-back'),
                            icon: Icons.arrow_back_rounded,
                            label: 'Previous Azkar page',
                            enabled: _page > 0,
                            onPressed: _back,
                          ),
                          Text(
                            'Page ${_page + 1} of $total',
                            key: const ValueKey<String>(
                              'daily-azkar-footer-page',
                            ),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          _PageArrowButton(
                            key: const ValueKey<String>('daily-azkar-next'),
                            icon: Icons.arrow_forward_rounded,
                            label: 'Next Azkar page',
                            enabled: true,
                            onPressed: _next,
                          ),
                        ],
                      ),
                      if (_entries.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Saved pages stay on this device and can be edited later.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyAzkarHeader extends StatelessWidget {
  const _DailyAzkarHeader({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.menu_book_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rozana ke Azkar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Page $page of $total',
                    key: const ValueKey<String>('daily-azkar-header-page'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageArrowButton extends StatelessWidget {
  const _PageArrowButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 56,
            child: Icon(
              icon,
              color: enabled ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
