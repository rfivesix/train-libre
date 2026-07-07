import 'package:intl/intl.dart';
import '../features/statistics/domain/timeframe_block.dart';
import '../generated/app_localizations.dart';

class TimeframeLabelFormatter {
  static String format(TimeframeBlock block, DateTime anchorDate, AppLocalizations l10n) {
    if (block == TimeframeBlock.maxBlock) {
      return l10n.filterMax;
    }
    
    final range = block.getBounds(anchorDate, DateTime(2020));
    final locale = l10n.localeName;
    
    switch (block) {
      case TimeframeBlock.day:
        return DateFormat.yMMMd(locale).format(range.start);
      case TimeframeBlock.week:
        return "${DateFormat('dd. MMM', locale).format(range.start)} - ${DateFormat('dd. MMM yyyy', locale).format(range.end)}";
      case TimeframeBlock.month:
        return DateFormat('MMMM yyyy', locale).format(range.start);
      case TimeframeBlock.threeMonths:
      case TimeframeBlock.sixMonths:
        return "${DateFormat('MMM', locale).format(range.start)} - ${DateFormat('MMM yyyy', locale).format(range.end)}";
      case TimeframeBlock.year:
        return DateFormat('yyyy', locale).format(range.start);
      default:
        return "";
    }
  }
}
