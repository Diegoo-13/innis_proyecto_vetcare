import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';
import 'booking_screen.dart';

class ClienteApptDetailScreen extends StatelessWidget {
  const ClienteApptDetailScreen({super.key, required this.apptId});
  final String apptId;

  void _confirmCancel(BuildContext context) {
    final state = AppScope.of(context);
    showAppSheet<void>(
      context,
      Builder(builder: (BuildContext ctx) {
        return SheetBody(
          title: '¿Cancelar esta cita?',
          subtitle: 'El horario quedará libre para otros pacientes. Podrás agendar una nueva cuando quieras.',
          children: [
            AppButton('Sí, cancelar cita', kind: BtnKind.danger, onPressed: () {
              state.cancelAppointment(apptId);
              Navigator.pop(ctx);
              toast(context, 'Cita cancelada');
            }),
            AppButton('Mantener cita', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx)),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final Appointment? a = state.appointmentById(apptId);
    if (a == null) {
      return const DetailScaffold(title: 'Cita', children: [Text('La cita ya no existe.')]);
    }
    final Pet? pet = state.petById(a.petId);
    final Service? service = state.serviceById(a.serviceId);
    final bool editable = a.isActive;

    return DetailScaffold(
      title: 'Detalle de la cita',
      subtitle: formatDateLong(a.start),
      bottom: editable
          ? Row(
              children: [
                Expanded(
                  child: AppButton('Cancelar', kind: BtnKind.danger, onPressed: () => _confirmCancel(context)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton('Reprogramar', onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => BookingScreen(rescheduleId: a.id)),
                    );
                  }),
                ),
              ],
            )
          : null,
      children: [
        HeroCard(
          child: Row(
            children: [
              PetAvatar(species: pet?.species ?? 'Perro', size: 52, square: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet?.name ?? 'Mascota',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(state.serviceLabel(a.serviceId),
                        style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 12.5)),
                  ],
                ),
              ),
              Pill(a.status.label, kind: apptPillKind(a.status)),
            ],
          ),
        ),
        AppCard(
          child: InfoList([
            InfoItem('Fecha', formatDateLong(a.start)),
            InfoItem('Hora', '${timeLabel(a.start)} – ${timeLabel(a.end)}'),
            InfoItem('Médico', state.doctorName(a.doctorId)),
            InfoItem('Consultorio', a.room),
            if (service != null) InfoItem('Costo', money(service.price)),
          ]),
        ),
        if (editable)
          AppCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recordarme esta cita', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      Text('Recepción te avisa por WhatsApp', style: TextStyle(fontSize: 11.5, color: C.muted)),
                    ],
                  ),
                ),
                Switch(
                  value: a.reminderOn,
                  activeColor: C.primary,
                  onChanged: (bool v) => state.setApptReminder(a.id, v),
                ),
              ],
            ),
          ),
        if (!editable)
          const AppBanner(text: 'Esta cita ya no admite cambios.', icon: Icons.info_outline),
      ],
    );
  }
}
