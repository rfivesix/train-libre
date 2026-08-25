// lib/widgets/common/app_restart.dart

import 'package:flutter/material.dart';

import '../../main.dart' as app_main;

/// Restarts the app in place, rebuilding everything `main` sets up.
///
/// Needed after the two operations that pull the ground out from under a
/// running app: deleting all local data, and restoring a backup. Both leave
/// services, view models and cached preferences holding state that no longer
/// matches what is on disk, and there is no way to hand every one of them the
/// news. Rebuilding from `main` is the only honest reset.
///
/// A placeholder goes up first because `main` is asynchronous — shader warm-up,
/// date formatting, a keychain migration, preferences — and until it reaches
/// `runApp` the *old* tree is still on screen. Without this the user watches
/// the screen they just acted on sit there as if nothing had happened.
void restartApp() {
  runApp(const _Restarting());
  app_main.main();
}

class _Restarting extends StatelessWidget {
  const _Restarting();

  @override
  Widget build(BuildContext context) {
    // Deliberately tiny: at this moment there is no database, no provider and
    // no localisation to lean on.
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
