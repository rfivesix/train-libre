import 'package:flutter/material.dart';

import '../../../../util/design_constants.dart';
import '../workout_history_screen.dart';

/// A circular calendar action button for the Workout Hub header matching the
/// profile button's solid style, that navigates to the workout history.
class WorkoutHistoryAppBarButton extends StatelessWidget {
  /// Optional callback to override navigation (e.g. for testing).
  final VoidCallback? onPressed;

  const WorkoutHistoryAppBarButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = colorScheme.onSurface;
    final iconColor = colorScheme.surface;
    const String tooltip = 'Workout-Historie';

    return Padding(
      padding: const EdgeInsets.only(
        right: DesignConstants.spacingS,
      ),
      child: Center(
        child: Tooltip(
          message: tooltip,
          child: Semantics(
            label: tooltip,
            button: true,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Material(
                color: backgroundColor,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  splashColor: colorScheme.surface.withValues(alpha: 0.15),
                  highlightColor: colorScheme.surface.withValues(alpha: 0.08),
                  onTap: onPressed ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WorkoutHistoryScreen(),
                          ),
                        );
                      },
                  child: Center(
                    child: Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
