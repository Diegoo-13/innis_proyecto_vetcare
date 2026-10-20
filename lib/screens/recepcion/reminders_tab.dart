import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';

/// Recordatorios por WhatsApp para el siguiente día hábil.
class RecepRemindersTab extends StatelessWidget {
  const RecepRemindersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final DateTime day = state.reminderDay;
    final List<Appointment> list = state.remindersFor(day);
    final int pending = list.where((Appointment a) => !a.reminderSent).length;

    return TabPage(
      header: const RootBar(title: 'Avisos', tag: null),
      children: [
        AppBanner(
          bold: 'Recordatorios para ${formatDateLong(day)}.',
          text: 'Los domingos la clínica cierra, así que se avisa para el siguiente día abierto.',
          icon: Icons.chat_bubble_outline,
        ),
        if (list.isEmpty)
          const AppCard(
            child: Text('No hay citas con recordatorio activo para ese día.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: C.muted)),
          ),
        for (final Appointment a in list)
          AppCard(
            child: Row(
              children: [
                PetAvatar(species: state.petById(a.petId)?.species ?? 'Perro', size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${state.petName(a.petId)} · ${timeLabel(a.start)}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      Text('${state.petById(a.petId)?.ownerName ?? ''} · ${state.petById(a.petId)?.phone ?? ''}',
                          style: const TextStyle(fontSize: 11.5, color: C.muted)),
                    ],
                  ),
                ),
                Pill(a.reminderSent ? 'Enviado' : 'Pendiente', kind: a.reminderSent ? PillKind.good : PillKind.warn),
              ],
            ),
          ),
        if (list.isNotEmpty)
          AppButton(
            pending == 0 ? 'Todos enviados' : 'Enviar $pending por WhatsApp',
            icon: Icons.send,
            onPressed: pending == 0
                ? null
                : () {
                    final int n = state.sendReminders(day);
                    toast(context, '$n recordatorio${n == 1 ? '' : 's'} enviado${n == 1 ? '' : 's'} (simulado)');
                  },
          ),
      ],
    );
  }
}
