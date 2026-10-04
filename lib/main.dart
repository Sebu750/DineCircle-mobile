import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'data/app_scope.dart';
import 'data/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final api = ApiClient();
  final state = AppState(api);

  // Kick off the bootstrap (token restore + initial data load) but don't
  // block the first frame — the splash screen covers the network round-trip.
  state.bootstrap();

  runApp(AppScope(state: state, child: const DineCircleApp()));
}
