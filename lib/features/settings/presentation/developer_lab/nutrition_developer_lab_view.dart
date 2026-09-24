// lib/features/settings/presentation/developer_lab/nutrition_developer_lab_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../diary/presentation/nutrition_hub_screen.dart';
import '../../../profile/presentation/create_goal_flow.dart';
import '../../../profile/presentation/my_goals_screen.dart';
import '../../../profile/presentation/weekly_goal_review_screen.dart';
import 'canonical_scenarios.dart';
import 'notification_test_view.dart';
import 'nutrition_sandbox_state.dart';
import 'nutrition_sandbox_widget.dart';
import 'nutrition_test_data_seeder.dart';

class NutritionDeveloperLabView extends StatefulWidget {
  const NutritionDeveloperLabView({super.key});

  @override
  State<NutritionDeveloperLabView> createState() =>
      _NutritionDeveloperLabViewState();
}

class _NutritionDeveloperLabViewState extends State<NutritionDeveloperLabView> {
  final NutritionSandboxState _sandboxState = NutritionSandboxState();
  int _selectedSectionIndex =
      0; // 0: Overview, 1: Scenarios, 2: Controls, 3: Screens & alerts
  bool _isSeedingDb = false;

  final List<String> _sections = [
    'Overview',
    'Scenarios',
    'Controls',
    'Screens & Alerts',
  ];

  Future<void> _injectScenarioIntoDb(
      CanonicalNutritionScenario scenario) async {
    setState(() => _isSeedingDb = true);
    try {
      await NutritionTestDataSeeder.seedScenario(scenario);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Szenario "${scenario.title}" erfolgreich in SQLite-DB injiziert!'),
            action: SnackBarAction(
              label: 'Hub öffnen',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NutritionHubScreen()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Injizieren: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeedingDb = false);
    }
  }

  Future<void> _clearTestDb() async {
    setState(() => _isSeedingDb = true);
    try {
      await NutritionTestDataSeeder.clearNutritionTestData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Alle DevLab-Testdaten aus SQLite gelöscht')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeedingDb = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: DesignConstants.cardPadding,
      children: [
        // Section Selector Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_sections.length, (index) {
              final isSelected = _selectedSectionIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: DesignConstants.spacingS),
                child: ChoiceChip(
                  label: Text(_sections[index]),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedSectionIndex = index);
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        // 0: Live Sandbox
        if (_selectedSectionIndex == 0) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return NutritionSandboxWidget(
                  state: _sandboxState,
                  showControls: false,
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: NutritionSandboxWidget(
                      state: _sandboxState,
                      showControls: false,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingL),
                  Expanded(
                    child: NutritionSandboxWidget(
                      state: _sandboxState,
                      showOverview: false,
                    ),
                  ),
                ],
              );
            },
          ),
        ],

        // 1: Canonical Scenarios
        if (_selectedSectionIndex == 1) ...[
          AppSectionHeader(title: 'Vorkonfigurierte Standardszenarien'),
          Text(
            'Lade ein Szenario mit einem Klick in die Live Sandbox (nur Speicher) oder injiziere es direkt in die echte App-Datenbank (SQLite).',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SummaryCard(
            useSecondarySurface: true,
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Row(
                children: [
                  Icon(LucideIcons.shield_check,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: DesignConstants.spacingM),
                  const Expanded(
                    child: Text(
                      'Preview is in-memory only. Database mode writes clearly marked test fixtures and can be cleaned below.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...CanonicalNutritionScenarios.all
              .map((scenario) => _buildScenarioCard(scenario)),
          const SizedBox(height: DesignConstants.spacingL),
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Echte Datenbank zurücksetzen',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Text(
                    'Entfernt alle mit [DevLab] markierten Test-Ziele, Test-Wiegungen und Test-Reviews rückstandslos.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  AppButton.secondary(
                    label: _isSeedingDb
                        ? 'Bereinige...'
                        : 'Testdaten aus DB löschen',
                    onPressed: _isSeedingDb ? null : _clearTestDb,
                  ),
                ],
              ),
            ),
          ),
        ],

        // 2: Exact engine controls
        if (_selectedSectionIndex == 2) ...[
          NutritionSandboxWidget(
            state: _sandboxState,
            showOverview: false,
          ),
        ],

        // 3: Product screen launcher and notification tester
        if (_selectedSectionIndex == 3) ...[
          AppSectionHeader(title: 'Alle neuen Screens & Flows direkt öffnen'),
          SummaryCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.clipboard_check),
                  title: const Text('Wöchentlicher Review Screen'),
                  subtitle: const Text(
                      'Öffnet WeeklyGoalReviewScreen mit aktuellem Sandbox-Model'),
                  trailing: const Icon(LucideIcons.chevron_right),
                  onTap: () {
                    final goal = _sandboxState.buildSyntheticGoal();
                    final review = _sandboxState.buildSyntheticReviewRecord();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            WeeklyGoalReviewScreen(goal: goal, review: review),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.compass),
                  title: const Text('Nutrition Hub Screen'),
                  subtitle: const Text(
                      'Öffnet den vollen Nutrition Hub (liest aktuelle DB)'),
                  trailing: const Icon(LucideIcons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const NutritionHubScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(LucideIcons.plus),
                  title: const Text('Zielerstellung (CreateGoalFlow)'),
                  subtitle: const Text(
                      'Öffnet die Zielreise mit vier klaren Kapiteln'),
                  trailing: const Icon(LucideIcons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateGoalFlow()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.target),
                  title: const Text('Meine Ziele (MyGoalsScreen)'),
                  subtitle: const Text('Übersicht aktiver und beendeter Ziele'),
                  trailing: const Icon(LucideIcons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyGoalsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          const NotificationTestView(),
        ],

        const SizedBox(height: DesignConstants.spacingXXL),
      ],
    );
  }

  Widget _buildScenarioCard(CanonicalNutritionScenario scenario) {
    final theme = Theme.of(context);

    return SummaryCard(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    scenario.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(DesignConstants.borderRadiusS),
                  ),
                  child: Text(
                    scenario.expectedOverallStatus,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              scenario.description,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'In Sandbox laden',
                    tooltip: 'Lädt Werte in die Sandbox (nur Speicher)',
                    onPressed: () {
                      scenario.applyToSandbox(_sandboxState);
                      setState(() => _selectedSectionIndex = 0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('"${scenario.title}" in Sandbox geladen')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.primary(
                    label: _isSeedingDb ? '...' : 'In echte DB',
                    tooltip:
                        'Injiziert Zeitreihendaten in die SQLite-Datenbank',
                    onPressed: _isSeedingDb
                        ? null
                        : () => _injectScenarioIntoDb(scenario),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
