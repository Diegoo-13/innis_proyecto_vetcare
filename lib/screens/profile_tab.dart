import 'package:flutter/material.dart';

import '../logic/app_scope.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/clinic_sheets.dart';
import '../widgets/common.dart';

/// Perfil compartido: cambia según el rol.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Widget _switchRow(String title, String desc, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              Text(desc, style: const TextStyle(fontSize: 11.5, color: C.muted)),
            ],
          ),
        ),
        Switch(value: value, activeColor: C.primary, onChanged: onChanged),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final Role role = state.role ?? Role.cliente;

    String name;
    String line1;
    String line2 = '';
    String initials;
    if (role == Role.cliente) {
      final c = state.currentClient;
      name = c.name;
      line1 = c.email;
      line2 = '${state.clientPets.length} mascota${state.clientPets.length == 1 ? '' : 's'} registrada${state.clientPets.length == 1 ? '' : 's'}';
      initials = c.initials;
    } else if (role == Role.chofer) {
      name = state.currentDriver.name;
      line1 = 'Chofer';
      line2 = state.currentDriver.vehicle;
      initials = name.split(' ').map((w) => w[0]).take(2).join();
    } else if (role == Role.recepcion) {
      name = 'Recepción VetCare';
      line1 = 'Mostrador';
      initials = 'RV';
    } else {
      name = 'Admin VetCare';
      line1 = 'Administrador';
      initials = 'AV';
    }

    return TabPage(
      header: const RootBar(title: 'Perfil'),
      children: [
        AppCard(
          child: Row(
            children: [
              InitialsAvatar(initials, size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(line1, style: const TextStyle(fontSize: 12.5, color: C.muted)),
                    if (line2.isNotEmpty) Text(line2, style: const TextStyle(fontSize: 12.5, color: C.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (role == Role.cliente) ...[
          const SectionLabel('Recordatorios'),
          AppCard(
            child: Column(
              children: [
                _switchRow('Un día antes, por WhatsApp', 'Recepción te escribe para confirmar tu cita',
                    state.currentClient.remindDayBefore, (bool v) => state.setClientReminder(dayBefore: v)),
                const Divider(color: C.line),
                _switchRow('La mañana de la cita', 'Aviso final antes de salir de casa',
                    state.currentClient.remindMorning, (bool v) => state.setClientReminder(morning: v)),
              ],
            ),
          ),
          AppButton('Contactar a la clínica',
              icon: Icons.phone_outlined, kind: BtnKind.ghost, onPressed: () => showClinicContactSheet(context)),
        ],
        AppButton('Cerrar sesión', small: true, kind: BtnKind.danger, onPressed: state.logout),
      ],
    );
  }
}
