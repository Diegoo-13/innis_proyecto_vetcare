import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../logic/app_state.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/clinic_sheets.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';

class RecepApptDetailScreen extends StatelessWidget {
  const RecepApptDetailScreen({super.key, required this.apptId});
  final String apptId;

  void _pickRoom(BuildContext context, Appointment a) {
    final state = AppScope.of(context, listen: false);
    showAppSheet<void>(
      context,
      Builder(builder: (BuildContext ctx) {
        return SheetBody(
          title: 'Reasignar consultorio',
          subtitle: 'Actual: ${a.room}',
          children: [
            for (final String r in kRooms)
              AppButton(r, kind: r == a.room ? BtnKind.primary : BtnKind.ghost, onPressed: () {
                final String? err = state.reassignRoom(a.id, r);
                if (err != null) {
                  toast(ctx, err);
                } else {
                  Navigator.pop(ctx);
                  toast(context, 'Consultorio actualizado');
                }
              }),
          ],
        );
      }),
    );
  }

  void _pickDoctor(BuildContext context, Appointment a) {
    final state = AppScope.of(context, listen: false);
    showAppSheet<void>(
      context,
      Builder(builder: (BuildContext ctx) {
        return SheetBody(
          title: 'Reasignar médico',
          subtitle: 'Actual: ${state.doctorName(a.doctorId)}',
          children: [
            for (final Doctor d in state.doctors)
              AppButton('${d.name} · ${d.hours}', kind: d.id == a.doctorId ? BtnKind.primary : BtnKind.ghost, onPressed: () {
                final String? err = state.reassignDoctor(a.id, d.id);
                if (err != null) {
                  toast(ctx, err);
                } else {
                  Navigator.pop(ctx);
                  toast(context, 'Médico actualizado');
                }
              }),
          ],
        );
      }),
    );
  }

  void _confirmCancel(BuildContext context, Appointment a) {
    final state = AppScope.of(context, listen: false);
    showAppSheet<void>(
      context,
      Builder(builder: (BuildContext ctx) {
        return SheetBody(
          title: '¿Cancelar esta cita?',
          subtitle: 'Es un estado final: la cita ya no podrá modificarse.',
          children: [
            AppButton('Sí, cancelar', kind: BtnKind.danger, onPressed: () {
              state.cancelAppointment(a.id);
              Navigator.pop(ctx);
              toast(context, 'Cita cancelada');
            }),
            AppButton('Volver', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx)),
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
    final List<String> reasons = state.conflictReasons(a);
    final bool open = !a.isFinal;

    return DetailScaffold(
      title: 'Detalle de cita',
      subtitle: '${formatDateLong(a.start)} · ${timeLabel(a.start)}',
      bottom: AppButton('Salir a la agenda', kind: BtnKind.ghost, onPressed: () => Navigator.of(context).pop()),
      children: [
        if (reasons.isNotEmpty)
          AppBanner(
            warn: true,
            icon: Icons.warning_amber_rounded,
            bold: 'Conflicto de horario.',
            text: reasons.join(' '),
          ),
        AppCard(
          child: Row(
            children: [
              PetAvatar(species: pet?.species ?? 'Perro', size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet?.name ?? 'Mascota', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('${pet?.code ?? ''} · ${pet?.species ?? ''} · ${pet?.breed ?? ''}',
                        style: const TextStyle(fontSize: 12, color: C.muted)),
                    Text('Dueño: ${pet?.ownerName ?? ''}', style: const TextStyle(fontSize: 12, color: C.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: InfoList([
            InfoItem('Servicio', state.serviceLabel(a.serviceId)),
            InfoItem('Horario', '${timeLabel(a.start)} – ${timeLabel(a.end)}'),
            InfoItem('Médico', state.doctorName(a.doctorId)),
            InfoItem('Consultorio', a.room),
            InfoItem('Estado', a.status.label),
            InfoItem('Llegada', a.checkedIn ? 'En sala' : 'Sin registrar'),
          ]),
        ),
        if (open) ...[
          Row(
            children: [
              Expanded(child: AppButton('Cambiar consultorio', small: true, kind: BtnKind.ghost, onPressed: () => _pickRoom(context, a))),
              const SizedBox(width: 10),
              Expanded(child: AppButton('Cambiar médico', small: true, kind: BtnKind.ghost, onPressed: () => _pickDoctor(context, a))),
            ],
          ),
          AppButton('Contactar al dueño',
              icon: Icons.phone_outlined,
              kind: BtnKind.ghost,
              onPressed: () => showOwnerContactSheet(context,
                  petName: pet?.name ?? 'Mascota', phone: pet?.phone ?? '', extra: 'Cita ${formatDateShort(a.start)} · ${timeLabel(a.start)}')),
          AppButton(a.checkedIn ? 'Quitar llegada' : 'Registrar llegada',
              icon: Icons.login, kind: BtnKind.success, onPressed: () => state.toggleCheckin(a.id)),
          AppButton('Concluir cita', icon: Icons.check_circle_outline, onPressed: () {
            state.concludeAppointment(a.id);
            toast(context, 'Cita concluida');
          }),
          AppButton('Cancelar cita', kind: BtnKind.danger, onPressed: () => _confirmCancel(context, a)),
        ] else
          const AppBanner(text: 'Esta cita está en un estado final y ya no admite cambios.', icon: Icons.lock_outline),
      ],
    );
  }
}
