import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../widgets/common/common.dart';

class ProfileSlide extends StatelessWidget {
  final TextEditingController nameController;
  final DateTime? selectedDate;
  final TextEditingController heightController;
  final String? selectedGender;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<String?> onSelectGender;

  const ProfileSlide({
    super.key,
    required this.nameController,
    required this.selectedDate,
    required this.heightController,
    required this.selectedGender,
    required this.onSelectDate,
    required this.onSelectGender,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();

    return SingleChildScrollView(
      key: const Key('onboarding_profile_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignConstants.spacingXL),
          _StepTitle(title: l10n.onboardingNameTitle),
          const SizedBox(height: DesignConstants.spacingL),
          TextField(
            key: const Key('onboarding_name_text_field'),
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              prefixIcon: const Icon(LucideIcons.user),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          _StepTitle(title: l10n.onboardingDobTitle),
          const SizedBox(height: DesignConstants.spacingL),
          InkWell(
            onTap: () async {
              final picked = await showAdaptiveDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                onSelectDate(picked);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.onboardingDobLabel,
                prefixIcon: const Icon(LucideIcons.cake),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
              ),
              child: Text(
                selectedDate == null
                    ? 'DD.MM.YYYY'
                    : DateFormat.yMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(selectedDate!),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepTitle(
                      title: l10n.onboardingHeightLabel,
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    TextField(
                      key: const Key('onboarding_height_text_field'),
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '${l10n.onboardingHeightLabel} (${unitService.suffixFor(UnitDimension.height)})',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignConstants.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepTitle(
                      title: l10n.onboardingGenderLabel,
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    PlatformAdaptiveDropdownFormField<String>(
                      key: const Key('onboarding_gender_dropdown'),
                      initialValue: selectedGender,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingM,
                          vertical: DesignConstants.spacingL,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(l10n.genderMale),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(l10n.genderFemale),
                        ),
                        DropdownMenuItem(
                          value: 'diverse',
                          child: Text(l10n.genderDiverse),
                        ),
                      ],
                      onChanged: onSelectGender,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
            child: Text(
              l10n.onboardingBioDataInfo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  const _StepTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
