import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/profile_service.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/common.dart';

class NameSlide extends StatelessWidget {
  const NameSlide({super.key, required this.nameController});
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ProfileService? profileService;
    try {
      final service = context.watch<ProfileService>();
      if (!service.isDisposed) {
        profileService = service;
      }
    } catch (_) {
      // Widget tests and minimal app shells can omit the optional service.
    }
    return _OnboardingStepPage(
      pageKey: const Key('onboarding_name_page'),
      title: l10n.onboardingNameTitle,
      subtitle: l10n.onboardingProfilePhotoSubtitle,
      child: Column(
        children: [
          Center(
            child: Semantics(
              button: true,
              label: l10n.onboardingProfilePhotoAdd,
              child: InkWell(
                key: const Key('onboarding_profile_photo_button'),
                borderRadius: BorderRadius.circular(56),
                onTap: profileService?.pickAndSaveProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      key: ValueKey(profileService?.cacheBuster ?? 0),
                      radius: 48,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: profileService?.profileImagePath == null
                          ? null
                          : FileImage(File(profileService!.profileImagePath!)),
                      child: profileService?.profileImagePath == null
                          ? Icon(LucideIcons.user_round,
                              size: 44,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(LucideIcons.camera,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(l10n.onboardingProfilePhotoAdd,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: DesignConstants.spacingXL),
          TextField(
            key: const Key('onboarding_name_text_field'),
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(context,
                label: l10n.onboardingNameLabel, icon: LucideIcons.user),
          ),
        ],
      ),
    );
  }
}

class BioDataSlide extends StatelessWidget {
  const BioDataSlide({
    super.key,
    required this.selectedDate,
    required this.selectedGender,
    required this.onSelectDate,
    required this.onSelectGender,
    this.dobError,
    this.genderError,
  });
  final DateTime? selectedDate;
  final String? selectedGender;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<String?> onSelectGender;
  final String? dobError;
  final String? genderError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _OnboardingStepPage(
      pageKey: const Key('onboarding_bio_data_page'),
      title: l10n.onboardingAgeTitle,
      subtitle: l10n.onboardingBioDataInfo,
      child: Column(children: [
        InkWell(
          onTap: () async {
            final picked = await showAdaptiveDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              initialView: AdaptiveDatePickerView.wheel,
            );
            if (picked != null) onSelectDate(picked);
          },
          child: InputDecorator(
            decoration: _inputDecoration(context,
                    label: l10n.onboardingDobLabel, icon: LucideIcons.cake)
                .copyWith(errorText: dobError),
            child: Text(
              selectedDate == null
                  ? l10n.onboardingDobPlaceholder
                  : DateFormat.yMMMd(Localizations.localeOf(context).toString())
                      .format(selectedDate!),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),
        PlatformAdaptiveDropdownFormField<String>(
          key: const Key('onboarding_gender_dropdown'),
          initialValue: selectedGender,
          errorText: genderError,
          decoration: _inputDecoration(context,
              label: l10n.onboardingGenderLabel, icon: LucideIcons.user_round),
          items: [
            DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
            DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
            DropdownMenuItem(value: 'diverse', child: Text(l10n.genderDiverse)),
          ],
          onChanged: onSelectGender,
        ),
      ]),
    );
  }
}

class HeightSlide extends StatefulWidget {
  const HeightSlide({
    super.key,
    required this.heightController,
    this.heightError,
    this.heightWarning,
  });
  final TextEditingController heightController;
  final String? heightError;
  final String? heightWarning;

  @override
  State<HeightSlide> createState() => _HeightSlideState();
}

class _HeightSlideState extends State<HeightSlide> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.heightController.text.trim().isEmpty) {
      widget.heightController.text =
          context.read<UnitService>().isImperial ? '67' : '170';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();
    final isImperial = unitService.isImperial;
    final min = isImperial ? 39.0 : 100.0;
    final max = isImperial ? 98.0 : 250.0;
    final current =
        (double.tryParse(widget.heightController.text.replaceAll(',', '.')) ??
                (isImperial ? 67.0 : 170.0))
            .clamp(min, max);
    final suffix = unitService.suffixFor(UnitDimension.height);

    return _OnboardingStepPage(
      pageKey: const Key('onboarding_height_page'),
      title: l10n.onboardingHeightTitle,
      subtitle: l10n.onboardingHeightSubtitle,
      child: Column(children: [
        Text('${current.toStringAsFixed(0)} $suffix',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
        const SizedBox(height: DesignConstants.spacingL),
        SizedBox(
          height: 320,
          child: _VerticalHeightRuler(
            value: current,
            min: min,
            max: max,
            onChanged: (value) {
              widget.heightController.text = value.toStringAsFixed(1);
              setState(() {});
            },
            onChangeEnd: (value) {
              widget.heightController.text = value.toStringAsFixed(0);
              setState(() {});
            },
          ),
        ),
        if (widget.heightError != null || widget.heightWarning != null) ...[
          const SizedBox(height: DesignConstants.spacingS),
          Text(widget.heightError ?? widget.heightWarning!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.heightError != null
                        ? Theme.of(context).colorScheme.error
                        : Colors.orange.shade800,
                  )),
        ],
      ]),
    );
  }
}

class _VerticalHeightRuler extends StatefulWidget {
  const _VerticalHeightRuler({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  State<_VerticalHeightRuler> createState() => _VerticalHeightRulerState();
}

class _VerticalHeightRulerState extends State<_VerticalHeightRuler> {
  double _dragValue = 0;

  void _update(double value) {
    final clamped = value.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
  }

  void _finish() {
    final snapped = widget.value.roundToDouble().clamp(widget.min, widget.max);
    HapticFeedback.selectionClick();
    widget.onChangeEnd(snapped);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AppLocalizations.of(context)!.onboardingHeightLabel,
      value: widget.value.toStringAsFixed(0),
      increasedValue:
          (widget.value + 1).clamp(widget.min, widget.max).toStringAsFixed(0),
      decreasedValue:
          (widget.value - 1).clamp(widget.min, widget.max).toStringAsFixed(0),
      onIncrease: () => _update(widget.value + 1),
      onDecrease: () => _update(widget.value - 1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _dragValue = widget.value,
        onVerticalDragUpdate: (details) {
          _dragValue += details.delta.dy / 5;
          _update(_dragValue);
        },
        onVerticalDragEnd: (_) => _finish(),
        child: CustomPaint(
          size: const Size(double.infinity, 320),
          painter: _VerticalRulerPainter(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            tickColor: colorScheme.onSurface,
            markerColor: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _VerticalRulerPainter extends CustomPainter {
  const _VerticalRulerPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.tickColor,
    required this.markerColor,
  });
  final double value;
  final double min;
  final double max;
  final Color tickColor;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    const pixelsPerUnit = 5.0;
    final center = size.height / 2;
    final radius = (center / pixelsPerUnit).ceil() + 2;
    final paint = Paint()..strokeWidth = 1.5;
    final centerValue = value.round();
    for (var i = centerValue - radius; i <= centerValue + radius; i++) {
      if (i < min || i > max) continue;
      final y = center - (i - value) * pixelsPerUnit;
      final isMajor = i % 5 == 0;
      final fade = (1 - ((y - center).abs() / center)).clamp(0.0, 1.0);
      paint.color = tickColor.withValues(alpha: fade * (isMajor ? .8 : .4));
      final length = isMajor ? 46.0 : 26.0;
      canvas.drawLine(Offset(size.width / 2 - length / 2, y),
          Offset(size.width / 2 + length / 2, y), paint);
      if (isMajor) {
        final label = TextPainter(
          text: TextSpan(
            text: i.toString(),
            style: TextStyle(
              color: tickColor.withValues(alpha: fade),
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        label.paint(canvas, Offset(size.width / 2 + 34, y - label.height / 2));
        label.dispose();
      }
    }
    paint
      ..color = markerColor
      ..strokeWidth = 3;
    canvas.drawLine(Offset(size.width / 2 - 58, center),
        Offset(size.width / 2 + 58, center), paint);
  }

  @override
  bool shouldRepaint(covariant _VerticalRulerPainter oldDelegate) =>
      value != oldDelegate.value ||
      min != oldDelegate.min ||
      max != oldDelegate.max ||
      tickColor != oldDelegate.tickColor ||
      markerColor != oldDelegate.markerColor;
}

class _OnboardingStepPage extends StatelessWidget {
  const _OnboardingStepPage({
    required this.pageKey,
    required this.title,
    required this.child,
    this.subtitle,
  });
  final Key pageKey;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        key: pageKey,
        padding: const EdgeInsets.all(DesignConstants.spacingXL),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: DesignConstants.spacingXL),
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          if (subtitle != null) ...[
            const SizedBox(height: DesignConstants.spacingS),
            Text(subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
          const SizedBox(height: DesignConstants.spacingXL),
          child,
        ]),
      );
}

InputDecoration _inputDecoration(BuildContext context,
        {required String label, required IconData icon}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
      ),
    );
