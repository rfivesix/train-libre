import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/services/experience_level_service.dart';

/// The level decides how much vocabulary the app shows. Its default is the
/// only thing standing between a shipped app and a silently simplified one, so
/// it is asserted here rather than trusted.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to pro, which is the behaviour that shipped before it', () {
    SharedPreferences.setMockInitialValues({});
    final service = ExperienceLevelService();

    expect(service.level, ExperienceLevel.pro);
    expect(service.showsIntensity, isTrue);
    expect(service.usesCoarseMuscleNames, isFalse);
  });

  test('reads a stored level back', () async {
    SharedPreferences.setMockInitialValues({
      'experience_level': ExperienceLevel.beginner.name,
    });
    final service = ExperienceLevelService();
    await service.reload();

    expect(service.level, ExperienceLevel.beginner);
    expect(service.showsIntensity, isFalse);
    expect(service.usesCoarseMuscleNames, isTrue);
  });

  test('a value it does not recognise falls back to pro, not to silence', () {
    SharedPreferences.setMockInitialValues({'experience_level': 'olympian'});

    expect(ExperienceLevelService().level, ExperienceLevel.pro);
  });

  test('advanced hides the column but keeps nothing else from pro', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ExperienceLevelService();
    await service.setLevel(ExperienceLevel.advanced);

    expect(service.showsIntensity, isFalse);
    expect(service.usesCoarseMuscleNames, isTrue);
    expect(
      SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('experience_level'),
      ),
      completion(ExperienceLevel.advanced.name),
    );
  });

  test('notifies only when the level actually moves', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ExperienceLevelService();
    var notifications = 0;
    service.addListener(() => notifications++);

    await service.setLevel(ExperienceLevel.pro);
    expect(notifications, 0);

    await service.setLevel(ExperienceLevel.beginner);
    expect(notifications, 1);
  });
}
