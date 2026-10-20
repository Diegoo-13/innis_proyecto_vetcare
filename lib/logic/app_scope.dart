import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Expone el [AppState] a todo el árbol de widgets (sin paquetes externos).
/// `AppScope.of(context)` también reconstruye el widget cuando algo cambia.
/// Con `listen: false` solo lee el estado (útil en initState y en callbacks).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context, {bool listen = true}) {
    final AppScope? scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró AppScope en el árbol de widgets');
    return scope!.notifier!;
  }
}
