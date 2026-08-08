import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

class SleepDataUnavailableCard extends StatelessWidget {
  const SleepDataUnavailableCard({
    super.key,
    required this.message,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
  });

  final String message;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignConstants.cardPaddingInternal,
        vertical: margin.resolve(Directionality.of(context)).top,
      ),
      child: Text(message),
    );
  }
}
