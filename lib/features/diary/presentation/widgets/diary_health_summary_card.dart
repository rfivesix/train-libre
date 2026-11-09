import 'package:flutter/material.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/morph_source.dart';
import '../../../../widgets/common/summary_card.dart';

/// Diary health cards share the training card's spacing and morph handover.
class DiaryHealthSummaryCard extends StatelessWidget {
  const DiaryHealthSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.destinationBuilder,
    this.routeSettings,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final WidgetBuilder? destinationBuilder;
  final RouteSettings? routeSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget card({VoidCallback? onTap}) => SummaryCard(
          padding: EdgeInsets.zero,
          margin:
              const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingM,
                vertical: DesignConstants.spacingM,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: DesignConstants.spacingXS),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: DesignConstants.spacingM),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        );

    if (destinationBuilder == null) return card();
    return RepaintBoundary(
      child: MorphSourceScope(
        builder: (context, setHidden) => Builder(
          builder: (sourceContext) => card(
            onTap: () => Navigator.of(sourceContext).push(
              CardMorphRoute<void>(
                sourceContext: sourceContext,
                sourceBuilder: (_) => card(),
                onSourceVisibilityChanged: setHidden,
                settings: routeSettings,
                builder: destinationBuilder!,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
