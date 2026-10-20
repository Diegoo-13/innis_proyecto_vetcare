import 'package:flutter/material.dart';

import '../logic/app_scope.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Acceso con selector de rol (para la demo de los 4 roles) y registro de clientes.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _mode = 0; // 0 = iniciar sesión, 1 = registrarme
  Role _role = Role.cliente;

  final TextEditingController _email = TextEditingController(text: 'mariana.lopez@correo.com');
  final TextEditingController _pass = TextEditingController(text: '123456');
  final TextEditingController _regName = TextEditingController();
  final TextEditingController _regEmail = TextEditingController();
  final TextEditingController _regPhone = TextEditingController();
  final TextEditingController _regPass = TextEditingController();
  final TextEditingController _regPass2 = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPhone.dispose();
    _regPass.dispose();
    _regPass2.dispose();
    super.dispose();
  }

  void _doLogin() {
    final state = AppScope.of(context);
    final String? err = state.login(_role, _email.text, _pass.text);
    if (err != null) {
      toast(context, err);
    }
  }

  void _doRegister() {
    final state = AppScope.of(context);
    final String? err = state.register(_regName.text, _regEmail.text, _regPhone.text, _regPass.text, _regPass2.text);
    if (err != null) {
      toast(context, err);
    }
  }

  Widget _roleChip(Role r, IconData icon) {
    final bool sel = _role == r;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = r),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? C.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: sel ? C.primary : C.line, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: sel ? C.primaryDark : C.inkSoft),
              const SizedBox(width: 6),
              Text(
                r.label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? C.primaryDark : C.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: C.line)),
      ),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x2416213E), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: ClipOval(child: Image.asset('assets/logo_innis.png', fit: BoxFit.cover)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 23,
                height: 23,
                decoration: const BoxDecoration(color: C.primary, shape: BoxShape.circle),
                child: const Icon(Icons.pets, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 7),
              const Text('VetCare', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: C.ink)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Un acceso, cuatro roles: cada quien ve solo su parte del flujo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: C.inkSoft, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _loginPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: spaced([
        const SectionLabel('Ingresar como'),
        Column(
          children: [
            Row(children: [
              _roleChip(Role.cliente, Icons.person_outline),
              const SizedBox(width: 8),
              _roleChip(Role.recepcion, Icons.apartment_outlined),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _roleChip(Role.chofer, Icons.local_shipping_outlined),
              const SizedBox(width: 8),
              _roleChip(Role.admin, Icons.settings_outlined),
            ]),
          ],
        ),
        AppField(label: 'Correo electrónico', controller: _email, hint: 'correo@vetcare.mx', keyboardType: TextInputType.emailAddress),
        AppField(label: 'Contraseña', controller: _pass, hint: '••••••••', obscure: true),
        AppButton('Iniciar sesión', onPressed: _doLogin),
        const Text(
          'El sistema valida el rol y redirige al panel correspondiente.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: C.muted),
        ),
      ], 12),
    );
  }

  Widget _registerPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: spaced([
        const AppBanner(
          text: 'El registro es para dueños de mascota (rol Cliente). Recepción, Chofer y Administrador reciben su acceso directamente de la clínica.',
        ),
        AppField(label: 'Nombre completo', controller: _regName, hint: 'Ej. Mariana López'),
        AppField(label: 'Correo electrónico', controller: _regEmail, hint: 'correo@ejemplo.com', keyboardType: TextInputType.emailAddress),
        AppField(label: 'Teléfono', controller: _regPhone, hint: 'Ej. 477 123 4567', keyboardType: TextInputType.phone),
        AppField(label: 'Contraseña', controller: _regPass, hint: 'Mínimo 6 caracteres', obscure: true),
        AppField(label: 'Confirmar contraseña', controller: _regPass2, hint: 'Repite tu contraseña', obscure: true),
        AppButton('Crear cuenta', onPressed: _doRegister),
        const Text(
          'Al crear tu cuenta aceptas recibir recordatorios de citas por WhatsApp.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: C.muted),
        ),
      ], 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _hero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: spaced([
                    AppSegmented(
                      options: const ['Iniciar sesión', 'Registrarme'],
                      index: _mode,
                      onChanged: (int i) => setState(() => _mode = i),
                    ),
                    _mode == 0 ? _loginPane() : _registerPane(),
                  ], 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
