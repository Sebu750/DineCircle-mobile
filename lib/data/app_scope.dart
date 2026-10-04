import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Makes the [AppState] store available to the whole widget tree.
///
/// Uses [InheritedNotifier] so any widget calling `context.app` rebuilds when
/// the store changes — no third-party state package needed.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'No AppScope found above this widget.');
    return scope!.notifier!;
  }
}

extension AppScopeX on BuildContext {
  /// The DineCircle store.
  AppState get app => AppScope.of(this);
}
