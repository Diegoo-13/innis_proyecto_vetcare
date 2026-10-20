import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';
import 'appt_detail_screen.dart';
import 'booking_screen.dart';

/// Tarjeta de cita reutilizable (lista de citas y detalle de mascota).
class ApptListCard extends StatelessWidget {
  const ApptListCard({super.key, required this.appt});
  final Appointment appt;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final Pet? pet = state.petById(appt.petId);
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ClienteApptDetailScreen(apptId: appt.id)),
      ),
      child: Row(
        children: [
          PetAvatar(species: pet?.species ?? 'Perro', size: 42, square: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${state.petName(appt.petId)} · ${state.serviceLabel(appt.serviceId)}',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: C.ink)),
                const SizedBox(height: 2),
                Text('${formatDateShort(appt.start)} · ${timeLabel(appt.start)}',
                    style: const TextStyle(fontSize: 12, color: C.muted)),
                Text(state.doctorName(appt.doctorId), style: const TextStyle(fontSize: 12, color: C.muted)),
              ],
            ),
          ),
          Pill(appt.status.label, kind: apptPillKind(appt.status)),
        ],
      ),
    );
  }
}

class ClienteApptsTab extends StatefulWidget {
  const ClienteApptsTab({super.key});

  @override
  State<ClienteApptsTab> createState() => _ClienteApptsTabState();
}

class _ClienteApptsTabState extends State<ClienteApptsTab> {
  int _seg = 0; // 0 = próximas, 1 = historial

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final List<Appointment> list = state.clientAppointments(upcoming: _seg == 0);
    return TabPage(
      header: const RootBar(title: 'Mis citas'),
      children: [
        AppSegmented(
          options: const ['Próximas', 'Historial'],
          index: _seg,
          onChanged: (int i) => setState(() => _seg = i),
        ),
        if (list.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_seg == 0 ? 'No tienes citas próximas.' : 'Aún no tienes historial de citas.',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: C.muted)),
                if (_seg == 0) ...[
                  const SizedBox(height: 10),
                  AppButton('Agendar una cita', small: true, onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BookingScreen()));
                  }),
                ],
              ],
            ),
          ),
        for (final Appointment a in list) ApptListCard(appt: a),
      ],
    );
  }
}
