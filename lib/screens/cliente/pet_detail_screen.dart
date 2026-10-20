import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';
import 'appts_tab.dart';
import 'booking_screen.dart';
import 'home_service_screen.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final Pet? p = state.petById(petId);
    if (p == null) {
      return const DetailScaffold(title: 'Mascota', children: [Text('No se encontró la mascota.')]);
    }
    final List<Appointment> appts = state.appointmentsOfPet(p.id);
    return DetailScaffold(
      title: p.name,
      subtitle: p.code,
      bottom: Row(
        children: [
          Expanded(
            child: AppButton('A domicilio', icon: Icons.local_shipping_outlined, kind: BtnKind.ghost, onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HomeServiceScreen(petId: p.id)));
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton('Agendar cita', icon: Icons.calendar_month_outlined, onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BookingScreen(petId: p.id)));
            }),
          ),
        ],
      ),
      children: [
        Center(child: PetAvatar(species: p.species, size: 84)),
        Center(child: Pill(p.category.label, kind: PillKind.info)),
        AppCard(
          child: InfoList([
            InfoItem('Código', p.code),
            InfoItem('Especie', p.species),
            InfoItem('Raza', p.breed),
            InfoItem('Color', p.color),
            InfoItem('Edad', p.age),
            InfoItem('Dueño', p.ownerName),
            InfoItem('Teléfono', p.phone),
          ]),
        ),
        const SectionLabel('Citas'),
        if (appts.isEmpty)
          const AppCard(child: Text('Todavía no tiene citas.', style: TextStyle(fontSize: 13, color: C.muted))),
        for (final Appointment a in appts) ApptListCard(appt: a),
      ],
    );
  }
}
