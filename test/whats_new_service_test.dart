import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/whats_new/data/whats_new_service.dart';
import 'package:train_libre/features/whats_new/domain/whats_new_content.g.dart';
import 'package:train_libre/features/whats_new/domain/whats_new_release.dart';

WhatsNewRelease _release(String version) => WhatsNewRelease(
      version: version,
      releasedOn: '2026-08-11',
      entries: [
        WhatsNewEntry(
          icon: const IconData(0x1, fontFamily: 'test'),
          title: 'Title $version',
          body: 'Body $version',
        ),
      ],
    );

/// Catalog newest first, exactly as the generator emits it.
final _catalog = {
  'en': [_release('1.0.4'), _release('1.0.3'), _release('1.0.2')],
  'de': [_release('1.0.3'), _release('1.0.2')],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = WhatsNewService.instance;

  void configure({required String version, Object? lastSeen}) {
    SharedPreferences.setMockInitialValues(
      lastSeen == null
          ? <String, Object>{}
          : <String, Object>{WhatsNewService.lastSeenVersionKey: lastSeen},
    );
    service.resetForTesting();
    service.alwaysShow = false;
    service.catalogOverride = _catalog;
    service.versionLoaderOverride = () async => version;
  }

  tearDown(service.resetForTesting);

  group('AppVersion', () {
    test('orders numerically, not lexicographically', () {
      expect(AppVersion.parse('1.0.10') > AppVersion.parse('1.0.9'), isTrue);
      expect(AppVersion.parse('2.0.0') > AppVersion.parse('1.99.99'), isTrue);
    });

    test('a pre-release sorts below the final release', () {
      expect(
        AppVersion.parse('1.0.2-beta.1') < AppVersion.parse('1.0.2'),
        isTrue,
      );
      expect(
        AppVersion.parse('1.0.2-beta.2') > AppVersion.parse('1.0.2-beta.1'),
        isTrue,
      );
    });

    test('ignores the build number', () {
      expect(AppVersion.parse('1.0.2+1000016'), AppVersion.parse('1.0.2'));
    });

    test('never throws on malformed input', () {
      expect(AppVersion.parse('').toString(), '0.0.0');
      expect(AppVersion.parse('not-a-version').major, 0);
      expect(AppVersion.parse('1.x.3').minor, 0);
    });
  });

  group('pendingReleases', () {
    test('nothing stored yet shows only the running version', () async {
      configure(version: '1.0.3', lastSeen: null);

      final pending = await service.pendingReleases('en');

      expect(pending.map((r) => r.version), ['1.0.3']);
    });

    test('nothing stored and no notes for the running version shows nothing',
        () async {
      configure(version: '1.0.9', lastSeen: null);

      expect(await service.pendingReleases('en'), isEmpty);
    });

    test('already seen the running version shows nothing', () async {
      configure(version: '1.0.3', lastSeen: '1.0.3');

      expect(await service.pendingReleases('en'), isEmpty);
    });

    test('a skipped update shows every release in between', () async {
      configure(version: '1.0.4', lastSeen: '1.0.2');

      final pending = await service.pendingReleases('en');

      expect(pending.map((r) => r.version), ['1.0.4', '1.0.3']);
    });

    test('notes for an unreleased version stay hidden', () async {
      // 1.0.4 is already written in the Markdown but this build is 1.0.3.
      configure(version: '1.0.3', lastSeen: '1.0.2');

      final pending = await service.pendingReleases('en');

      expect(pending.map((r) => r.version), ['1.0.3']);
    });

    test('an unknown language falls back to English', () async {
      configure(version: '1.0.4', lastSeen: '1.0.2');

      final pending = await service.pendingReleases('pt');

      expect(pending.map((r) => r.version), ['1.0.4', '1.0.3']);
    });

    test('a translated language uses its own notes', () async {
      configure(version: '1.0.3', lastSeen: '1.0.2');

      final pending = await service.pendingReleases('de');

      expect(pending.map((r) => r.version), ['1.0.3']);
    });

    test('a failing version lookup degrades to showing nothing', () async {
      configure(version: '1.0.3', lastSeen: '1.0.2');
      service.versionLoaderOverride = () async => throw StateError('boom');

      expect(await service.pendingReleases('en'), isEmpty);
    });
  });

  group('markSeen', () {
    test('stores the marketing version without the build number', () async {
      configure(version: '1.0.3', lastSeen: '1.0.2');

      await service.markSeen();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WhatsNewService.lastSeenVersionKey), '1.0.3');
    });

    test('suppresses the sheet on the next launch', () async {
      configure(version: '1.0.3', lastSeen: '1.0.2');

      await service.markSeen();

      expect(await service.pendingReleases('en'), isEmpty);
    });

    test('seedForFreshInstall never shows anything afterwards', () async {
      configure(version: '1.0.3', lastSeen: null);

      await service.seedForFreshInstall();

      expect(await service.pendingReleases('en'), isEmpty);
    });
  });

  group('generated catalog', () {
    test('every shipped language has entries for the generated version', () {
      expect(kWhatsNewContent, isNotEmpty);
      expect(kWhatsNewContent.containsKey(kWhatsNewFallbackLanguage), isTrue);

      for (final entry in kWhatsNewContent.entries) {
        final releases = entry.value;
        expect(releases, isNotEmpty, reason: 'no releases for ${entry.key}');
        expect(
          releases.any((r) => r.version == kWhatsNewGeneratedForVersion),
          isTrue,
          reason: '${entry.key} has no notes for $kWhatsNewGeneratedForVersion',
        );
      }
    });

    test('releases are ordered newest first and versions are parsable', () {
      for (final entry in kWhatsNewContent.entries) {
        final versions =
            entry.value.map((r) => AppVersion.parse(r.version)).toList();
        for (var i = 1; i < versions.length; i++) {
          expect(
            versions[i - 1] > versions[i],
            isTrue,
            reason: '${entry.key} is not sorted newest first',
          );
        }
        for (final release in entry.value) {
          expect(
            AppVersion.parse(release.version).toString(),
            isNot('0.0.0'),
            reason: 'unparsable version "${release.version}" in ${entry.key}',
          );
          expect(release.entries, isNotEmpty);
        }
      }
    });
  });
}
