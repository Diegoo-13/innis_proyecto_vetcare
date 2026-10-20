import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../logic/app_state.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/pet_avatar.dart';

/// Agendado en 3 pasos (mascota y servicio → fecha y médico → horario) + pantalla de éxito.
/// Con [rescheduleId] reprograma una cita existente y empieza en el paso 2.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.petId, this.rescheduleId});
  final String? petId;
  final String? rescheduleId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  bool _done = false;
  String? _petId;
  Service? _service;
  Doctor? _doctor; // null = primer médico disponible
  DateTime? _date;
  int? _minutes;

  // Datos de la cita confirmada (para la pantalla de éxito).
  String _okDoctor = '';
  String _okRoom = '';

  bool get _isReschedule => widget.rescheduleId != null;

  @override
  void initState() {
    super.initState();
    _petId = widget.petId;
    if (_isReschedule) {
      final state = AppScope.of(context, listen: false);
      final Appointment? a = state.appointmentById(widget.rescheduleId!);
      if (a != null) {
        _petId = a.petId;
        _service = state.serviceById(a.serviceId);
        _doctor = state.doctorById(a.doctorId);
      }
      _step = 1;
    }
  }

  void _back() {
    final int min = _isReschedule ? 1 : 0;
    if (_step > min) {
      setState(() {
        _step--;
        _minutes = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  String _slotSub(SlotState s) {
    if (s == SlotState.rest) return 'Descanso';
    if (s == SlotState.outOfHours) return 'Fuera de horario';
    if (s == SlotState.busy) return 'Ocupado';
    if (s == SlotState.surgery) return 'Cirugía';
    if (s == SlotState.past) return 'Pasado';
    return 'Libre';
  }

  /// Médico que atendería en ese horario y el estado resultante.
  SlotState _stateAt(int m, List<Doctor> out) {
    final state = AppScope.of(context, listen: false);
    final Service s = _service!;
    final List<Doctor> candidates = _doctor != null ? <Doctor>[_doctor!] : state.doctors;
    SlotState last = SlotState.busy;
    for (final Doctor d in candidates) {
      final SlotState st = state.slotState(
        doctor: d,
        date: _date!,
        minutes: m,
        durationMin: s.effectiveMinutes,
        room: state.roomFor(s, d),
        ignoreApptId: widget.rescheduleId,
      );
      last = st;
      if (st == SlotState.ok) {
        out.add(d);
        return st;
      }
    }
    return last;
  }

  void _confirm() {
    final state = AppScope.of(context, listen: false);
    final List<Doctor> found = <Doctor>[];
    final SlotState st = _stateAt(_minutes!, found);
    if (st != SlotState.ok || found.isEmpty) {
      toast(context, 'Ese horario ya no está disponible. Elige otro.');
      setState(() => _minutes = null);
      return;
    }
    final Doctor d = found.first;
    final String? err = state.bookAppointment(
      petId: _petId!,
      service: _service!,
      doctor: d,
      date: _date!,
      minutes: _minutes!,
      rescheduleId: widget.rescheduleId,
    );
    if (err != null) {
      toast(context, err);
      setState(() => _minutes = null);
      return;
    }
    setState(() {
      _okDoctor = d.name;
      _okRoom = state.roomFor(_service!, d);
      _done = true;
    });
  }

  // ---------------- Pasos ----------------

  Widget _stepIndicator() {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= _step ? C.primary : C.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
      ],
    );
  }

  List<Widget> _step0(BuildContext context) {
    final state = AppScope.of(context);
    final pets = state.clientPets;
    final services = state.services;
    return [
      const SectionLabel('¿Quién será atendido?'),
      if (pets.isEmpty)
        const AppBanner(text: 'Primero registra una mascota en la pestaña Mascotas.', warn: true, icon: Icons.pets)
      else
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            for (final Pet p in pets)
              ChipSelect(
                label: p.name,
                leading: PetAvatar(species: p.species, size: 34),
                selected: _petId == p.id,
                onTap: () => setState(() => _petId = p.id),
              ),
          ],
        ),
      const SectionLabel('Servicio'),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.95,
        children: [
          for (final Service s in services)
            ChipSelect(
              label: s.label,
              icon: s.icon,
              sub: money(s.price),
              selected: _service?.id == s.id,
              onTap: () => setState(() {
                _service = s;
                _minutes = null;
              }),
            ),
        ],
      ),
    ];
  }

  List<Widget> _step1(BuildContext context) {
    final state = AppScope.of(context);
    return [
      const SectionLabel('Médico'),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.05,
        children: [
          ChipSelect(
            label: 'Primero disponible',
            icon: Icons.auto_awesome,
            selected: _doctor == null,
            onTap: () => setState(() {
              _doctor = null;
              _minutes = null;
            }),
          ),
          for (final Doctor d in state.doctors)
            ChipSelect(
              label: d.name,
              icon: Icons.medical_services_outlined,
              sub: d.especialidad,
              selected: _doctor?.id == d.id,
              onTap: () => setState(() {
                _doctor = d;
                _minutes = null;
              }),
            ),
        ],
      ),
      const SectionLabel('Fecha'),
      MonthCalendar(
        selected: _date,
        onPick: (DateTime d) => setState(() {
          _date = d;
          _minutes = null;
        }),
      ),
    ];
  }

  List<Widget> _step2(BuildContext context) {
    final state = AppScope.of(context);
    final Service s = _service!;
    final List<Widget> cells = <Widget>[];
    int free = 0;
    for (final int m in clinicSlotMinutes()) {
      final List<Doctor> found = <Doctor>[];
      final SlotState st = _stateAt(m, found);
      final bool ok = st == SlotState.ok;
      if (ok) free++;
      cells.add(ChipSelect(
        label: minutesLabel(m),
        sub: ok ? 'Libre' : _slotSub(st),
        subColor: ok ? C.good : C.muted,
        selected: _minutes == m,
        disabled: !ok,
        onTap: () => setState(() => _minutes = m),
      ));
    }
    final SlotSuggestion? sug = free == 0 ? state.autoAssign(service: s, from: addDays(_date!, 1)) : null;
    return [
      AppCard(
        child: Text(
          '${s.label} · ${state.petName(_petId!)}\n${formatDateLong(_date!)} · ${_doctor?.name ?? 'primer médico disponible'}',
          style: const TextStyle(fontSize: 12.5, height: 1.5, color: C.inkSoft),
        ),
      ),
      const SectionLabel('Horario'),
      if (free == 0)
        AppBanner(
          warn: true,
          icon: Icons.event_busy,
          text: sug == null
              ? 'No hay horarios libres ese día. Elige otra fecha.'
              : 'No hay horarios libres ese día. El siguiente espacio es ${formatDateShort(sug.date)} a las ${minutesLabel(sug.minutes)} con ${sug.doctor.name}.',
        ),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.7,
        children: cells,
      ),
    ];
  }

  Widget _success(BuildContext context) {
    final state = AppScope.of(context);
    return DetailScaffold(
      title: _isReschedule ? 'Cita reprogramada' : 'Cita agendada',
      showBack: false,
      bottom: AppButton('Listo', onPressed: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst)),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: C.goodSoft, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 38, color: C.good),
          ),
        ),
        Text(
          _isReschedule ? '¡Tu cita fue reprogramada!' : '¡Tu cita quedó confirmada!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.ink),
        ),
        AppCard(
          child: InfoList([
            InfoItem('Mascota', state.petName(_petId!)),
            InfoItem('Servicio', _service!.label),
            InfoItem('Fecha', formatDateLong(_date!)),
            InfoItem('Hora', minutesLabel(_minutes!)),
            InfoItem('Médico', _okDoctor),
            InfoItem('Consultorio', _okRoom),
          ]),
        ),
        const AppBanner(text: 'Recepción te enviará un recordatorio por WhatsApp.', icon: Icons.chat_bubble_outline),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _success(context);

    bool canContinue = false;
    String label = 'Continuar';
    List<Widget> body;
    String title = _isReschedule ? 'Reprogramar cita' : 'Agendar cita';
    String subtitle;
    if (_step == 0) {
      canContinue = _petId != null && _service != null;
      body = _step0(context);
      subtitle = 'Paso 1 de 3 · Mascota y servicio';
    } else if (_step == 1) {
      canContinue = _date != null;
      body = _step1(context);
      subtitle = 'Paso 2 de 3 · Médico y fecha';
    } else {
      canContinue = _minutes != null;
      label = _isReschedule ? 'Confirmar nuevo horario' : 'Confirmar cita';
      body = _step2(context);
      subtitle = 'Paso 3 de 3 · Horario';
    }

    return DetailScaffold(
      title: title,
      subtitle: subtitle,
      onBack: _back,
      bottom: AppButton(
        label,
        onPressed: canContinue
            ? () {
                if (_step < 2) {
                  setState(() => _step++);
                } else {
                  _confirm();
                }
              }
            : null,
      ),
      children: [_stepIndicator(), ...body],
    );
  }
}
