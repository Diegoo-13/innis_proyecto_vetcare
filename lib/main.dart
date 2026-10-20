import 'package:flutter/material.dart';

import 'logic/app_scope.dart';
import 'logic/app_state.dart';
import 'models/models.dart';
import 'screens/login_screen.dart';
import 'screens/role_shell.dart';
import 'theme.dart';

void main() {
  runApp(const VetCareApp());
}

class VetCareApp extends StatefulWidget {
  const VetCareApp({super.key});

  @override
  State<VetCareApp> createState() => _VetCareAppState();
}

class _VetCareAppState extends State<VetCareApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'VetCare',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // En escritorio / web la app se ve como una columna tipo teléfono.
        builder: (BuildContext context, Widget? child) {
          return Container(
            color: const Color(0xFFEEF1F8),
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final Role? role = state.role;
    if (role == null) return const LoginScreen();
    return RoleShell(key: ValueKey<Role>(role), role: role);
  }
}
