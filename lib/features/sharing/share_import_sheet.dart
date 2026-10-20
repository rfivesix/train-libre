import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../widgets/common/app_button.dart';
import '../app/presentation/widgets/glass_bottom_menu.dart';
import 'share_link_codec.dart';

/// Requests portable JSON, validates its type and structure, then asks the
/// user to confirm the exact action before returning the payload.
Future<ShareLinkPayload?> showShareImportSheet({
  required BuildContext context,
  required String expectedType,
  required String warning,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final raw = await showGlassBottomMenu<String>(
    context: context,
    title: l10n.shareImportSectionTitle,
    contentBuilder: (sheetContext, close) => _ShareJsonInput(
      l10n: l10n,
      onCancel: () => Navigator.of(sheetContext).pop(),
      onSubmit: (content) => Navigator.of(sheetContext).pop(content),
    ),
  );
  if (raw == null || !context.mounted) return null;

  late final ShareLinkPayload payload;
  try {
    payload = SharePortableCodec.decode(raw);
    if (payload.type != expectedType) {
      throw const FormatException('Unexpected shared content type');
    }
  } catch (_) {
    _showInvalid(context);
    return null;
  }

  final confirmed = await showGlassBottomMenu<bool>(
    context: context,
    title: payload.name,
    contentBuilder: (sheetContext, close) => Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignConstants.spacingL,
        DesignConstants.spacingM,
        DesignConstants.spacingL,
        DesignConstants.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_summary(payload, Localizations.localeOf(context).languageCode)),
          const SizedBox(height: DesignConstants.spacingM),
          Text(warning),
          const SizedBox(height: DesignConstants.spacingL),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              label: l10n.shareImportConfirm,
              tooltip: l10n.shareImportConfirm,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              label: l10n.cancel,
              tooltip: l10n.cancel,
            ),
          ),
        ],
      ),
    ),
  );
  return confirmed == true ? payload : null;
}

void _showInvalid(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(AppLocalizations.of(context)!.shareImportInvalid),
  ));
}

String _summary(ShareLinkPayload payload, String languageCode) {
  final german = languageCode == 'de';
  switch (payload.type) {
    case 'routine':
      return '${german ? 'Routine' : 'Routine'} · '
          '${(payload.data['exercises'] as List).length} '
          '${german ? 'Übungen' : 'exercises'}';
    case 'plan':
      final days = payload.data['days'] as List;
      return '${german ? 'Trainingsplan' : 'Training plan'} · '
          '${days.length} ${german ? 'Tage' : 'days'}';
    case 'recipe':
      return '${german ? 'Rezept' : 'Recipe'} · '
          '${(payload.data['items'] as List).length} '
          '${german ? 'Zutaten' : 'ingredients'}';
    default:
      return payload.type;
  }
}

class _ShareJsonInput extends StatefulWidget {
  const _ShareJsonInput({
    required this.l10n,
    required this.onCancel,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  @override
  State<_ShareJsonInput> createState() => _ShareJsonInputState();
}

class _ShareJsonInputState extends State<_ShareJsonInput> {
  final TextEditingController _controller = TextEditingController();
  bool _readingFile = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (result.isEmpty || result.single.path == null || !mounted) return;
    setState(() => _readingFile = true);
    try {
      final file = File(result.single.path!);
      if (await file.length() > SharePortableCodec.maxFileBytes) {
        throw const FormatException('Shared file is too large');
      }
      final text = await file.readAsString();
      if (mounted) setState(() => _controller.text = text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.l10n.shareImportInvalid),
        ));
      }
    } finally {
      if (mounted) setState(() => _readingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignConstants.spacingL,
        DesignConstants.spacingM,
        DesignConstants.spacingL,
        DesignConstants.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.shareImportPasteDescription),
          const SizedBox(height: DesignConstants.spacingM),
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 9,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.shareImportPasteHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              onPressed: _readingFile ? null : _chooseFile,
              label: l10n.shareImportFile,
              tooltip: l10n.shareImportFile,
              icon: LucideIcons.file_down,
              isLoading: _readingFile,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              onPressed: _controller.text.trim().isEmpty || _readingFile
                  ? null
                  : () => widget.onSubmit(_controller.text),
              label: l10n.shareImportConfirm,
              tooltip: l10n.shareImportConfirm,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              onPressed: widget.onCancel,
              label: l10n.cancel,
              tooltip: l10n.cancel,
            ),
          ),
        ],
      ),
    );
  }
}
