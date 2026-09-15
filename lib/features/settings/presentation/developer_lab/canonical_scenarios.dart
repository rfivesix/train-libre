// lib/features/settings/presentation/developer_lab/canonical_scenarios.dart

import '../../../profile/domain/models/goal_model.dart';
import 'nutrition_sandbox_state.dart';

class CanonicalNutritionScenario {
  final String id;
  final String title;
  final String description;
  final String expectedOverallStatus;
  final String expectedMomentum;
  final String expectedAction;
  final void Function(NutritionSandboxState state) applyToSandbox;

  const CanonicalNutritionScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.expectedOverallStatus,
    required this.expectedMomentum,
    required this.expectedAction,
    required this.applyToSandbox,
  });
}

class CanonicalNutritionScenarios {
  static final List<CanonicalNutritionScenario> all = [
    CanonicalNutritionScenario(
      id: 'on_trajectory',
      title: 'Auf Zielkurs (Normalverlauf)',
      description:
          'Stetige Abnahme (-0.5 kg/Woche), Kalorienziel eingehalten, 5 Wiegungen, 7 Tage geloggt. Keine Anpassung nötig.',
      expectedOverallStatus: 'on_trajectory',
      expectedMomentum: 'matching_plan',
      expectedAction: 'keep_targets',
      applyToSandbox: (s) {
        s.loadScenarioValues(
          preset: GoalPreset.loseWeight,
          baselineWeight: 85.0,
          targetWeight: 78.0,
          totalWeeks: 14,
          elapsedWeeks: 6,
          currentWeight: 82.0, // Expected: 85 - (0.5 * 6) = 82.0
          recentRate: -0.50,
          operatingRate: -0.50,
          weightObservations: 5,
          loggedDays: 7,
          currentCalories: 2100,
          averageLoggedCalories: 2110,
          tdee: 2600.0,
        );
      },
    ),
    CanonicalNutritionScenario(
      id: 'behind_plateau',
      title: 'Plateau / Stoffwechsel-Stall',
      description:
          'Gewicht stagniert bei 83.5 kg trotz 100% Einhaltung des Kaloriendefizits (2100 kcal). Engine empfiehlt Kalorienreduktion.',
      expectedOverallStatus: 'behind',
      expectedMomentum: 'falling_further_behind',
      expectedAction: 'adjust_targets',
      applyToSandbox: (s) {
        s.loadScenarioValues(
          preset: GoalPreset.loseWeight,
          baselineWeight: 85.0,
          targetWeight: 78.0,
          totalWeeks: 14,
          elapsedWeeks: 6,
          currentWeight: 83.8, // Gap ~ -1.8 kg
          recentRate: -0.05, // Plateau
          operatingRate: -0.10,
          weightObservations: 6,
          loggedDays: 7,
          currentCalories: 2100,
          averageLoggedCalories: 2090, // Eingehalten!
          tdee: 2350.0,
          recommendedCalories: 1950,
        );
      },
    ),
    CanonicalNutritionScenario(
      id: 'behind_intake_gap',
      title: 'Abweichung durch Nahrungsaufnahme',
      description:
          'Gewicht stagniert, aber der Nutzer hat im Schnitt 400 kcal/Tag über dem Ziel gegessen. Keine Kaloriensenkung, sondern ehrlicher Hinweis.',
      expectedOverallStatus: 'behind',
      expectedMomentum: 'falling_further_behind',
      expectedAction: 'keep_targets_intake_differs',
      applyToSandbox: (s) {
        s.loadScenarioValues(
          preset: GoalPreset.loseWeight,
          baselineWeight: 85.0,
          targetWeight: 78.0,
          totalWeeks: 14,
          elapsedWeeks: 6,
          currentWeight: 83.8, // Gap ~ -1.8 kg
          recentRate: 0.0,
          operatingRate: 0.0,
          weightObservations: 5,
          loggedDays: 7,
          currentCalories: 2000,
          averageLoggedCalories: 2450, // Deutlich über Ziel!
          tdee: 2500.0,
        );
      },
    ),
    CanonicalNutritionScenario(
      id: 'behind_catching_up',
      title: 'Hinter Plan, aber holt auf',
      description:
          'Gesamtverlauf liegt noch hinter dem Zieldatum, aber die letzten 7 Tage waren mit -0.85 kg/Woche spürbar schneller als geplant.',
      expectedOverallStatus: 'behind',
      expectedMomentum: 'catching_up',
      expectedAction: 'adjust_targets',
      applyToSandbox: (s) {
        s.loadScenarioValues(
          preset: GoalPreset.loseWeight,
          baselineWeight: 85.0,
          targetWeight: 78.0,
          totalWeeks: 14,
          elapsedWeeks: 6,
          currentWeight: 83.0, // Expected: 82.0 (behind)
          recentRate: -0.85, // Rate faster than planned (-0.5)
          operatingRate: -0.60,
          weightObservations: 5,
          loggedDays: 6,
          currentCalories: 2100,
          averageLoggedCalories: 2080,
          tdee: 2600.0,
        );
      },
    ),
    CanonicalNutritionScenario(
      id: 'ahead_aggressive',
      title: 'Vor Zielkurs (Zu aggressiver Pace)',
      description:
          'Gewicht fällt zu schnell (-1.35 kg/Woche statt -0.5 kg). Engine warnt vor Muskelverlust und schlägt Kalorienerhöhung vor.',
      expectedOverallStatus: 'ahead',
      expectedMomentum: 'moving_faster',
      expectedAction: 'adjust_targets',
      applyToSandbox: (s) {
        s.loadScenarioValues(
          preset: GoalPreset.loseWeight,
          baselineWeight: 85.0,
          targetWeight: 78.0,
          totalWeeks: 14,
          elapsedWeeks: 5,
          currentWeight: 80.5, // Expected: 82.5 (2 kg ahead!)
          recentRate: -1.35,
          operatingRate: -1.20,
          weightObservations: 6,
          loggedDays: 7,
          currentCalories: 1900,
          averageLoggedCalories: 1750,
          tdee: 2700.0,
          recommendedCalories: 2150,
        );
      },
    ),
    CanonicalNutritionScenario(
      id: 'insufficient_data',
      title: 'Unvollständige Daten (Kalibriert noch)',
      description:
          'Nur 1 Wiegung und 2 geloggte Tage in der letzten Woche. Sufficiency Gate schlägt an: "Kalibriert noch", keine voreiligen Schlüsse.',
      expectedOverallStatus: 'behind',
      expectedMomentum: 'unclear',
      expectedAction: 'insufficient_data',
      applyToSandbox: (s) {
        s.loadScenarioValues(
          preset: GoalPreset.loseWeight,
          baselineWeight: 85.0,
          targetWeight: 78.0,
          totalWeeks: 14,
          elapsedWeeks: 4,
          currentWeight: 83.5,
          recentRate: -0.3,
          operatingRate: -0.3,
          weightObservations: 1, // Gate requires >= 3
          loggedDays: 2, // Gate requires >= 4
          currentCalories: 2100,
          averageLoggedCalories: 2100,
          tdee: 2600.0,
        );
      },
    ),
    CanonicalNutritionScenario(
      id: 'target_date_needs_review',
      title: 'Zieldatum prüfen (Termin verstrichen)',
      description:
          'Das ursprünglich gewählte Zieldatum liegt in der Vergangenheit oder ist rechnerisch unmöglich. Plananpassungs-Editor wird angeboten.',
      expectedOverallStatus: 'target_date_needs_review',
      expectedMomentum: 'moving_slower',
      expectedAction: 'trajectory_change_needed',
      applyToSandbox: (s) {
        s.loadScenarioValues(
          preset: GoalPreset.loseWeight,
          baselineWeight: 85.0,
          targetWeight: 78.0,
          totalWeeks: 8,
          elapsedWeeks: 10, // Elapsed > Total!
          currentWeight: 81.5,
          recentRate: -0.2,
          operatingRate: -0.2,
          weightObservations: 4,
          loggedDays: 5,
          currentCalories: 2100,
          averageLoggedCalories: 2100,
          tdee: 2500.0,
        );
      },
    ),
    CanonicalNutritionScenario(
      id: 'target_reached',
      title: 'Ziel erreicht!',
      description:
          'Zielgewicht von 78.0 kg wurde erreicht (aktuell 77.8 kg). Erfolgszustand: Übergang zur Gewichtserhaltung wird vorgeschlagen.',
      expectedOverallStatus: 'target_reached',
      expectedMomentum: 'matching_plan',
      expectedAction: 'keep_targets',
      applyToSandbox: (s) {
        s.loadScenarioValues(
          preset: GoalPreset.loseWeight,
          baselineWeight: 85.0,
          targetWeight: 78.0,
          totalWeeks: 14,
          elapsedWeeks: 12,
          currentWeight: 77.8, // Under target!
          recentRate: -0.45,
          operatingRate: -0.45,
          weightObservations: 6,
          loggedDays: 7,
          currentCalories: 2100,
          averageLoggedCalories: 2100,
          tdee: 2550.0,
        );
      },
    ),
  ];
}
