import 'package:flutter/widgets.dart';

/// A single user-facing highlight inside a [WhatsNewRelease].
///
/// Authored in `metadata/whats_new/<locale>.md`, not here.
class WhatsNewEntry {
  /// Lucide icon shown next to the headline.
  final IconData icon;

  /// Short headline, e.g. "Live Activity & Dynamic Island".
  final String title;

  /// One or two sentences of detail. May be empty.
  final String body;

  const WhatsNewEntry({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// The highlights of one released app version.
class WhatsNewRelease {
  /// Marketing version exactly as in `pubspec.yaml`, without the build number
  /// (`1.0.2`, not `1.0.2+1000016`).
  final String version;

  /// ISO date (`2026-08-11`) or empty when the Markdown omitted it.
  final String releasedOn;

  final List<WhatsNewEntry> entries;

  const WhatsNewRelease({
    required this.version,
    required this.releasedOn,
    required this.entries,
  });

  /// Parsed [releasedOn], or `null` when absent or malformed.
  DateTime? get releaseDate => DateTime.tryParse(releasedOn);
}

/// Comparable representation of a marketing version string.
///
/// Tolerates the pre-release suffixes used in `CHANGELOG.md` (`1.0.2-beta.1`)
/// and never throws on unparsable input — a malformed version must not be able
/// to break app startup, so it degrades to `0.0.0`.
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;

  /// Empty for a final release. A non-empty suffix sorts *below* the same
  /// version without one, so `1.0.2-beta.1` < `1.0.2`.
  final String suffix;

  const AppVersion(this.major, this.minor, this.patch, [this.suffix = '']);

  static final RegExp _leadingDigits = RegExp(r'^\d+');

  /// Parses `1.0.2`, `1.0.2+1000016` and `1.0.2-beta.1`.
  factory AppVersion.parse(String raw) {
    final withoutBuild = raw.trim().split('+').first;
    final dashIndex = withoutBuild.indexOf('-');
    final core =
        dashIndex == -1 ? withoutBuild : withoutBuild.substring(0, dashIndex);
    final suffix = dashIndex == -1 ? '' : withoutBuild.substring(dashIndex + 1);

    final parts = core.split('.');
    int at(int index) {
      if (index >= parts.length) return 0;
      final match = _leadingDigits.firstMatch(parts[index]);
      return match == null ? 0 : int.parse(match.group(0)!);
    }

    return AppVersion(at(0), at(1), at(2), suffix);
  }

  @override
  int compareTo(AppVersion other) {
    final byMajor = major.compareTo(other.major);
    if (byMajor != 0) return byMajor;
    final byMinor = minor.compareTo(other.minor);
    if (byMinor != 0) return byMinor;
    final byPatch = patch.compareTo(other.patch);
    if (byPatch != 0) return byPatch;

    final hasSuffix = suffix.isNotEmpty;
    final otherHasSuffix = other.suffix.isNotEmpty;
    if (hasSuffix != otherHasSuffix) return hasSuffix ? -1 : 1;
    return suffix.compareTo(other.suffix);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, suffix);

  @override
  String toString() =>
      suffix.isEmpty ? '$major.$minor.$patch' : '$major.$minor.$patch-$suffix';
}
