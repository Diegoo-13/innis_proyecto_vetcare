import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/clinic_sheets.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';
import 'appt_detail_screen.dart';
import 'booking_screen.dart';
import 'home_service_screen.dart';
import 'pet_detail_screen.dart';

class ClienteHomeTab extends StatelessWidget {
  const ClienteHomeTab({super.key, required this.onGoTab});

  /// Cambia de pestaña desde los accesos rápidos (0 Inicio, 1 Citas, 2 Mascotas, 3 Perfil).
  final ValueChanged<int> onGoTab;

  void _openReminders(BuildContext context) {
    final state = AppScope.of(context);
    final List<String> notes = state.clientNotifications();
    state.markNotificationsRead();
    showAppSheet<void>(
      context,
      Builder(builder: (BuildContext ctx) {
        return SheetBody(
          title: 'Recordatorios',
          children: [
            if (notes.isEmpty)
              const Text('No tienes recordatorios pendientes.', style: TextStyle(fontSize: 13, color: C.muted)),
            for (final String n in notes)
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.notifications_none, color: C.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(n, style: const TextStyle(fontSize: 12.5, height: 1.4, color: C.ink)),
                    ),
                  ],
                ),
              ),
            AppButton('Cerrar', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx)),
          ],
        );
      }),
    );
  }

  Widget _nextCard(BuildContext context, Appointment? a) {
    final state = AppScope.of(context);
    if (a == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('No tienes citas próximas.', style: TextStyle(fontSize: 12.5, color: C.muted)),
            const SizedBox(height: 10),
            AppButton('Agendar una cita', small: true, onPressed: () => _book(context)),
          ],
        ),
      );
    }
    final Pet? pet = state.petById(a.petId);
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PetAvatar(species: pet?.species ?? 'Perro', size: 44, square: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet?.name ?? 'Mascota',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(state.serviceLabel(a.serviceId),
                        style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 12.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(999)),
                child: Text(
                  a.status.label + (a.status == ApptStatus.confirmada ? ' ✓' : ''),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x2EFFFFFF), height: 24),
          Row(children: [
            const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.white),
            const SizedBox(width: 7),
            Text('${formatDateShort(a.start)} · ${timeLabel(a.start)}',
                style: const TextStyle(color: Colors.white, fontSize: 12.5)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: Colors.white),
            const SizedBox(width: 7),
            Text('${state.doctorName(a.doctorId)} · ${a.room}',
                style: const TextStyle(color: Colors.white, fontSize: 12.5)),
          ]),
          const SizedBox(height: 12),
          AppButton('Ver cita', onPressed: () => _openAppt(context, a.id)),
        ],
      ),
    );
  }

  void _openAppt(BuildContext context, String id) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClienteApptDetailScreen(apptId: id)));
  }

  void _book(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BookingScreen()));
  }

  Widget _action(BuildContext context, IconData icon, String title, String desc, VoidCallback onTap) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: C.primarySoft, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 17, color: C.primaryDark),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.ink)),
                Text(desc, style: const TextStyle(fontSize: 10.5, color: C.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final client = state.currentClient;
    final pets = state.clientPets;
    final Appointment? next = state.nextClientAppointment;
    final bool hasNotes = state.clientNotifUnread && state.clientNotifications().isNotEmpty;

    return TabPage(
      header: RootBar(
        trailing: GestureDetector(
          onTap: () => _openReminders(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              InitialsAvatar(client.initials, size: 38),
              if (hasNotes)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: C.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${client.firstName} 👋', style: const TextStyle(fontSize: 13, color: C.muted)),
            const SizedBox(height: 2),
            const Text('Bienvenido/a a VetCare', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Próxima cita'),
            const SizedBox(height: 8),
            _nextCard(context, next),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionLabel('Mis mascotas'),
                GestureDetector(
                  onTap: () => onGoTab(2),
                  child: const Text('Ver todas', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.primaryDark)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (pets.isEmpty)
              const AppCard(child: Text('Aún no registras mascotas. Agrégalas en la pestaña Mascotas.', style: TextStyle(fontSize: 12.5, color: C.muted)))
            else
              SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final Pet p in pets)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 132,
                          child: AppCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => PetDetailScreen(petId: p.id)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PetAvatar(species: p.species, size: 44),
                                const SizedBox(height: 6),
                                Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                Text(p.species, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: C.muted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Accesos rápidos'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                _action(context, Icons.calendar_month_outlined, 'Agendar cita', 'Consulta, vacuna…', () => _book(context)),
                _action(context, Icons.event_note_outlined, 'Mis citas', 'Ver historial', () => onGoTab(1)),
                _action(context, Icons.local_shipping_outlined, 'A domicilio', 'Solicitar recolección', () {
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HomeServiceScreen()));
                }),
                _action(context, Icons.pets, 'Mis mascotas', 'Ver perfiles', () => onGoTab(2)),
                _action(context, Icons.notifications_active_outlined, 'Urgencias', 'Médico de guardia', () => showUrgenciasSheet(context)),
                _action(context, Icons.phone_outlined, 'Contacto', 'Teléfono, WhatsApp, correo', () => showClinicContactSheet(context)),
              ],
            ),
          ],
        ),
        AppButton('Agendar nueva cita', icon: Icons.add, onPressed: () => _book(context)),
      ],
    );
  }
}
