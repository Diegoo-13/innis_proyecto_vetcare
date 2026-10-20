# VetCare (Flutter)

App de la clínica veterinaria con 4 roles: Cliente, Recepción, Chofer y Administrador.

## Cómo correrla en VS Code
1. Copia `lib/`, `assets/`, `test/` y `pubspec.yaml` dentro de tu proyecto `vetcare_innis`
   (el que ya tiene las carpetas android/ios/web). Reemplaza lo existente.
   Si tu proyecto no tiene carpetas de plataforma, corre antes `flutter create .`
2. `flutter pub get`
3. `flutter run` (elige Chrome, Windows o un emulador)

## Cuentas de prueba
- Cliente: mariana.lopez@correo.com / 123456
- Recepción, Chofer y Administrador: elige el rol en el login (la demo valida el rol, no una base de datos real).

## Arquitectura
- `lib/screens`, `lib/widgets`: presentación
- `lib/logic/app_state.dart`: reglas de negocio (empalmes, horarios, domingos cerrados, asignación, etc.)
- `lib/data/repository.dart`: datos en memoria (patrón Repository)
- `lib/models`: entidades

Los datos viven en memoria (se reinician al cerrar la app). Teléfonos, precios y cédulas son de ejemplo.
