import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/global_app_bar.dart';
import '../app/presentation/widgets/glass_bottom_menu.dart';
import 'share_link_codec.dart';
import 'share_link_repository.dart';

/// Entry point for an incoming web or app link. Import only happens after the
/// user has inspected the content and explicitly confirmed it.
class ShareLinkPreviewScreen extends StatefulWidget {
  const ShareLinkPreviewScreen({super.key, this.payload, this.error});

  final ShareLinkPayload? payload;
  final String? error;

  @override
  State<ShareLinkPreviewScreen> createState() => _ShareLinkPreviewScreenState();
}

class _ShareLinkPreviewScreenState extends State<ShareLinkPreviewScreen> {
  bool _started = false;
  bool _busy = false;
  bool _importFailed = false;

  String _copy(String en, String de) =>
      Localizations.localeOf(context).languageCode == 'de' ? de : en;

  void _leavePreview() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || widget.payload == null) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPreview());
  }

  Future<void> _showPreview() async {
    if (!mounted) return;
    final payload = widget.payload!;
    final accepted = await showGlassBottomMenu<bool>(
      context: context,
      title: AppLocalizations.of(context)!.shareImportPreview,
      contentBuilder: (sheetContext, close) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(payload.name,
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_summary(payload)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView(
                children: _previewLines(payload)
                    .map((line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(line),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: AppLocalizations.of(context)!.shareImportConfirm,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (accepted != true) {
      _leavePreview();
      return;
    }
    setState(() {
      _busy = true;
      _importFailed = false;
    });
    try {
      await const ShareLinkRepository().import(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.shareImportSuccess),
      ));
      _leavePreview();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _importFailed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.shareImportInvalid),
      ));
    }
  }

  String _summary(ShareLinkPayload payload) {
    if (payload.type == 'routine') {
      final count = (payload.data['exercises'] as List).length;
      return _copy('Routine · $count exercises', 'Routine · $count Übungen');
    }
    if (payload.type == 'plan') {
      final days = payload.data['days'] as List;
      final workouts = days.where((day) => day != null).length;
      return _copy('Training plan · ${days.length} days · $workouts workouts',
          'Trainingsplan · ${days.length} Tage · $workouts Einheiten');
    }
    if (payload.type == 'workout') {
      final date = DateTime.parse(payload.data['start'] as String);
      final formatted =
          DateFormat.yMMMd(Localizations.localeOf(context).toString())
              .format(date);
      final count = (payload.data['sets'] as List).length;
      return _copy('Workout · $formatted · $count sets',
          'Training · $formatted · $count Sätze');
    }
    final items = payload.data['items'] as List;
    double total(String key) => items.fold<double>(0, (sum, raw) {
          final item = raw as Map;
          return sum +
              ((item[key] as num?)?.toDouble() ?? 0) *
                  ((item['grams'] as num).toDouble()) /
                  100;
        });
    final portions = payload.data['portions'] as int? ?? 1;
    final macros =
        '${total('kcal').round()} kcal · P ${total('protein').round()} g · C ${total('carbs').round()} g · F ${total('fat').round()} g';
    return _copy('Recipe · $portions portion(s) · $macros',
        'Rezept · $portions Portion(en) · $macros');
  }

  List<String> _previewLines(ShareLinkPayload payload) {
    if (payload.type == 'routine') {
      return (payload.data['exercises'] as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final count = (row['sets'] as List).length;
        final targets = (row['sets'] as List).map((raw) {
          final set = raw as Map;
          final reps = set['reps'];
          final weight = set['weight'];
          if (reps == null && weight == null) return '–';
          return '${reps ?? '–'}${weight == null ? '' : ' × $weight kg'}';
        }).join(', ');
        return '${row['name']} · $count ${_copy('sets', 'Sätze')} · $targets';
      }).toList();
    }
    if (payload.type == 'plan') {
      return (payload.data['days'] as List).asMap().entries.map((entry) {
        final raw = entry.value;
        final name = raw == null
            ? _copy('Rest day', 'Ruhetag')
            : (raw as Map)['n'] as String;
        return '${entry.key + 1}. $name';
      }).toList();
    }
    if (payload.type == 'workout') {
      return (payload.data['sets'] as List).map((raw) {
        final set = raw as Map;
        return '${set['exercise_name']} · ${set['weight_kg'] ?? '–'} kg × ${set['reps'] ?? '–'} · RIR ${set['rir'] ?? '–'}';
      }).toList();
    }
    return (payload.data['items'] as List).map((raw) {
      final item = raw as Map;
      return '${item['name']} · ${item['grams']} ${item['unit'] ?? 'g'}';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(title: AppLocalizations.of(context)!.share),
      body: Center(
        child: widget.error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context)!.shareImportInvalid),
                    const SizedBox(height: 16),
                    AppButton.secondary(
                      label: AppLocalizations.of(context)!.appTitle,
                      onPressed: _leavePreview,
                    ),
                  ],
                ),
              )
            : _busy
                ? const CircularProgressIndicator()
                : _importFailed
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: AppButton.primary(
                          label: AppLocalizations.of(context)!.shareImportRetry,
                          onPressed: _showPreview,
                        ),
                      )
                    : const SizedBox.shrink(),
      ),
    );
  }
}
