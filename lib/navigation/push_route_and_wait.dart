import 'package:flutter/widgets.dart';

/// Pushes [route] and waits until its exit transition has removed its overlay.
///
/// A pushed route's result future completes as soon as it starts popping. When
/// the caller also pops its own route in response, the two reverse transitions
/// can overlap and leave the destination temporarily covered by outgoing
/// routes. Waiting for [Route.completed] keeps return navigation sequential.
Future<T?> pushRouteAndWaitForCompletion<T>(
  BuildContext context,
  PageRoute<T> route,
) async {
  final result = await Navigator.of(context).push<T>(route);
  await route.completed;
  return result;
}
