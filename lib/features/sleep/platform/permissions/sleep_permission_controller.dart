import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/permission_dialogs.dart';
import 'sleep_permission_models.dart';
import 'sleep_permissions_service.dart';

class SleepPermissionController {
  SleepPermissionController(this._service)
      : state = ValueNotifier<SleepPermissionStatus>(
          const SleepPermissionStatus(state: SleepPermissionState.loading),
        );

  final SleepPermissionsService _service;
  final ValueNotifier<SleepPermissionStatus> state;

  Future<void> refresh() async {
    final outcome = await _service.checkStatus();
    state.value = SleepPermissionStatus(
      state: outcome.state,
      error: outcome.error,
      message: outcome.message,
    );
  }

  Future<void> requestAccess(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showPrePermissionDialog(
      context: context,
      title: l10n.sleepRequestAccessTitle,
      body: l10n.sleepRequestAccessSubtitle,
      continueLabel: l10n.health_permission_continue,
      cancelLabel: '',
    );

    if (confirmed != true) return;

    final outcome = await _service.requestAccess();
    state.value = SleepPermissionStatus(
      state: outcome.state,
      error: outcome.error,
      message: outcome.message,
    );
  }
}
