import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../logic/app_state.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/clinic_sheets.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';
import 'appt_detail_screen.dart';

class RecepAgendaTab extends StatefulWidget {
  const RecepAgendaTab({super.key});

  @override
  State<RecepAgendaTab> createState() => _RecepAgendaTabState();
}

class _RecepAgendaTabState extends State<RecepAgendaTab> {
  DateTime? _day;
  String? _room;
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _shift(int delta) {
    DateTime d = addDays(_day!, delta);
    if (isClinicClosed(d)) d = addDays(d, delta);
    setState(() => _day = d);
  }

  Widget _apptCard(BuildContext context, AppState state, Appointment a) {
    final Pet? pet = state.petById(a.petId);
    final bool conflict = state.hasConflict(a);
    return AppCard(
      borderColor: conflict ? C.bad : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => RecepApptDetailScreen(apptId: a.id)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeLabel(a.start), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: C.primaryDark)),
                Text('${a.durationMin} min', style: const TextStyle(fontSize: 10.5, color: C.muted)),
              ],
            ),
          ),
          PetAvatar(species: pet?.species ?? 'Perro', size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pet?.name ?? 'Mascota'} · ${state.serviceLabel(a.serviceId)}',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                Text('${state.doctorName(a.doctorId)} · ${a.room}', style: const TextStyle(fontSize: 11.5, color: C.muted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Pill(a.status.label, kind: apptPillKind(a.status)),
                    if (conflict) const Pill('Conflicto', kind: PillKind.bad),
                    if (a.checkedIn && a.isActive) const Pill('En sala', kind: PillKind.good),
                    if (a.isNewPatient) const Pill('Paciente nuevo', kind: PillKind.info),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _surgeryCard(AppState state, Surgery s) {
    return AppCard(
      color: C.warnSoft,
      borderColor: C.warn,
      child: Row(
        children: [
          const Icon(Icons.healing, color: C.warn),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cirugía · ${state.doctorName(s.doctorId)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text('${timeLabel(s.start)} – ${timeLabel(s.end)}', style: const TextStyle(fontSize: 12, color: C.inkSoft)),
              ],
            ),
          ),
          IconBtn(icon: Icons.close, color: C.bad, tooltip: 'Quitar bloqueo', onTap: () => state.removeSurgery(s.id)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _day ??= state.firstOpenDate;
    final DateTime day = _day!;
    final List<Appointment> appts = state.agendaFor(day, room: _room, query: _search.text);
    final List<Surgery> surgeries = state.surgeriesOn(day);
    final int conflicts = state.conflictCountOn(day);

    return TabPage(
      header: RootBar(
        tag: 'Recepción',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBtn(icon: Icons.notifications_active_outlined, tooltip: 'Urgencias', onTap: () => showUrgenciasSheet(context)),
            const SizedBox(width: 8),
            IconBtn(
              icon: Icons.add,
              tooltip: 'Nueva cita',
              onTap: () => showAppSheet<void>(context, _ManualApptSheet(day: day)),
            ),
          ],
        ),
      ),
      children: [
        Row(
          children: [
            IconBtn(icon: Icons.chevron_left, onTap: () => _shift(-1)),
            Expanded(
              child: Column(
                children: [
                  Text(formatDateLong(day), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(sameDay(day, state.today) ? 'Hoy · ${appts.length} cita${appts.length == 1 ? '' : 's'}' : '${appts.length} cita${appts.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 11.5, color: C.muted)),
                ],
              ),
            ),
            IconBtn(icon: Icons.chevron_right, onTap: () => _shift(1)),
          ],
        ),
        AppField(
          label: '',
          controller: _search,
          hint: 'Buscar por mascota, código, dueño, teléfono, raza o médico',
          prefixIcon: Icons.search,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _roomChip('Todos', null),
              for (final String r in kRooms) _roomChip(r, r),
            ],
          ),
        ),
        if (conflicts > 0)
          AppBanner(
            warn: true,
            icon: Icons.warning_amber_rounded,
            bold: '$conflicts cita${conflicts == 1 ? '' : 's'} en conflicto.',
            text: 'Abre las marcadas para reasignar médico o consultorio.',
          ),
        for (final Surgery s in surgeries) _surgeryCard(state, s),
        if (appts.isEmpty)
          const AppCard(
            child: Text('No hay citas para este filtro.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: C.muted)),
          ),
        for (final Appointment a in appts) _apptCard(context, state, a),
        AppButton('Registrar cirugía',
            icon: Icons.healing, kind: BtnKind.ghost, onPressed: () => showAppSheet<void>(context, _SurgerySheet(day: day))),
      ],
    );
  }

  Widget _roomChip(String label, String? value) {
    final bool sel = _room == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _room = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? C.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: sel ? C.primary : C.line),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : C.inkSoft)),
        ),
      ),
    );
  }
}

// ======================= HOJA: CITA MANUAL =======================

class _ManualApptSheet extends StatefulWidget {
  const _ManualApptSheet({required this.day});
  final DateTime day;

  @override
  State<_ManualApptSheet> createState() => _ManualApptSheetState();
}

class _ManualApptSheetState extends State<_ManualApptSheet> {
  int _mode = 0; // 0 = paciente existente, 1 = nuevo
  Pet? _pet;
  Service? _service;
  Doctor? _doctor;
  int _minutes = 540;
  String? _room;
  String _species = 'Perro';
  final TextEditingController _name = TextEditingController();
  final TextEditingController _breed = TextEditingController();
  final TextEditingController _owner = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _owner.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _syncRoom(AppState state) {
    if (_service != null && _doctor != null) _room = state.roomFor(_service!, _doctor!);
  }

  void _save(AppState state) {
    final ManualApptResult r = state.addManualAppointment(
      day: widget.day,
      minutes: _minutes,
      serviceId: _service?.id ?? '',
      doctorId: _doctor?.id ?? '',
      room: _room ?? kRooms.first,
      existingPetId: _mode == 0 ? _pet?.id : null,
      newName: _name.text,
      newSpecies: _species,
      newBreed: _breed.text,
      newOwner: _owner.text,
      newPhone: _phone.text,
    );
    if (r.error != null) {
      toast(context, r.error!);
      return;
    }
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState msg = ScaffoldMessenger.of(context);
    nav.pop();
    msg.hideCurrentSnackBar();
    String text = 'Cita registrada';
    if (r.newPatient && r.pet != null) text = 'Paciente nuevo registrado: ${r.pet!.code}';
    if (r.conflict) text = '$text · Quedó en conflicto, revísala';
    msg.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final List<Pet> pets = state.repo.pets;
    return SheetBody(
      title: 'Nueva cita',
      subtitle: formatDateLong(widget.day),
      children: [
        AppSegmented(
          options: const ['Paciente existente', 'Paciente nuevo'],
          index: _mode,
          onChanged: (int i) => setState(() => _mode = i),
        ),
        if (_mode == 0)
          AppDropdown<Pet>(
            label: 'Paciente',
            value: _pet,
            items: pets,
            labelOf: (Pet p) => '${p.name} · ${p.code} · ${p.ownerName}',
            onChanged: (Pet? p) => setState(() => _pet = p),
          )
        else ...[
          AppField(label: 'Nombre de la mascota', controller: _name),
          AppDropdown<String>(
            label: 'Especie',
            value: _species,
            items: kSpecies,
            labelOf: (String s) => s,
            onChanged: (String? v) => setState(() => _species = v ?? _species),
          ),
          AppField(label: 'Raza', controller: _breed),
          AppField(label: 'Dueño', controller: _owner),
          AppField(label: 'Teléfono', controller: _phone, keyboardType: TextInputType.phone),
        ],
        AppDropdown<Service>(
          label: 'Servicio',
          value: _service,
          items: state.services,
          labelOf: (Service s) => s.label,
          onChanged: (Service? s) => setState(() {
            _service = s;
            _syncRoom(state);
          }),
        ),
        AppDropdown<Doctor>(
          label: 'Médico',
          value: _doctor,
          items: state.doctors,
          labelOf: (Doctor d) => '${d.name} (${d.hours})',
          onChanged: (Doctor? d) => setState(() {
            _doctor = d;
            _syncRoom(state);
          }),
        ),
        AppDropdown<int>(
          label: 'Hora',
          value: _minutes,
          items: clinicSlotMinutes(),
          labelOf: (int m) => minutesLabel(m),
          onChanged: (int? m) => setState(() => _minutes = m ?? _minutes),
        ),
        AppDropdown<String>(
          label: 'Consultorio',
          value: _room,
          items: kRooms,
          labelOf: (String r) => r,
          onChanged: (String? r) => setState(() => _room = r),
        ),
        const AppBanner(
          text: 'Si el horario choca con otra cita, se registra igual y queda marcada como conflicto para resolverla.',
          icon: Icons.info_outline,
        ),
        AppButton('Guardar cita', onPressed: () => _save(state)),
      ],
    );
  }
}

// ======================= HOJA: CIRUGÍA =======================

class _SurgerySheet extends StatefulWidget {
  const _SurgerySheet({required this.day});
  final DateTime day;

  @override
  State<_SurgerySheet> createState() => _SurgerySheetState();
}

class _SurgerySheetState extends State<_SurgerySheet> {
  Doctor? _doctor;
  int _start = 600;
  int _duration = 60;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final List<Appointment> affected =
        _doctor == null ? <Appointment>[] : state.surgeryAffected(_doctor!.id, widget.day, _start, _duration);
    return SheetBody(
      title: 'Registrar cirugía',
      subtitle: '${formatDateLong(widget.day)}. El médico queda bloqueado y no recibe citas durante la cirugía.',
      children: [
        AppDropdown<Doctor>(
          label: 'Médico',
          value: _doctor,
          items: state.doctors,
          labelOf: (Doctor d) => d.name,
          onChanged: (Doctor? d) => setState(() => _doctor = d),
        ),
        AppDropdown<int>(
          label: 'Inicio',
          value: _start,
          items: clinicSlotMinutes(),
          labelOf: (int m) => minutesLabel(m),
          onChanged: (int? m) => setState(() => _start = m ?? _start),
        ),
        AppDropdown<int>(
          label: 'Duración',
          value: _duration,
          items: const [30, 60, 90, 120, 180, 240],
          labelOf: (int m) => '$m min',
          onChanged: (int? m) => setState(() => _duration = m ?? _duration),
        ),
        if (affected.isNotEmpty)
          AppBanner(
            warn: true,
            icon: Icons.warning_amber_rounded,
            bold: 'Se cancelarán ${affected.length} cita${affected.length == 1 ? '' : 's'}:',
            text: affected.map((Appointment a) => '${state.petName(a.petId)} (${timeLabel(a.start)})').join(', '),
          ),
        AppButton('Registrar cirugía', onPressed: _doctor == null
            ? null
            : () {
                final int n = state.registerSurgery(_doctor!.id, widget.day, _start, _duration);
                final ScaffoldMessengerState msg = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                msg.hideCurrentSnackBar();
                msg.showSnackBar(SnackBar(
                  content: Text(n == 0 ? 'Cirugía registrada' : 'Cirugía registrada · $n cita${n == 1 ? '' : 's'} cancelada${n == 1 ? '' : 's'}'),
                ));
              }),
      ],
    );
  }
}
