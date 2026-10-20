import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

const List<String> _kReasons = [
  'Consulta general',
  'Vacunación',
  'Curación / retiro de puntos',
  'Traslado a la clínica',
  'Otro',
];

/// Solicitud de servicio a domicilio y seguimiento en vivo del estado.
class HomeServiceScreen extends StatefulWidget {
  const HomeServiceScreen({super.key, this.petId});
  final String? petId;

  @override
  State<HomeServiceScreen> createState() => _HomeServiceScreenState();
}

class _HomeServiceScreenState extends State<HomeServiceScreen> {
  String? _petId;
  DateTime? _date;
  int? _time;
  String _reason = _kReasons.first;
  int _qty = 1;
  bool _returnHome = true;
  bool _companion = false;
  final TextEditingController _addr = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _petId = widget.petId;
  }

  @override
  void dispose() {
    _addr.dispose();
    _notes.dispose();
    super.dispose();
  }

  List<int> _timesFor(DateTime? d) {
    if (d == null) return kHomeServiceTimes;
    final DateTime now = DateTime.now();
    return kHomeServiceTimes.where((int m) => atMinutes(d, m).isAfter(now)).toList();
  }

  void _submit() {
    final state = AppScope.of(context, listen: false);
    final String? err = state.requestHomeService(
      petId: _petId ?? '',
      addr: _addr.text,
      date: _date,
      timeMinutes: _time,
      notes: _notes.text,
      reason: _reason,
      qty: _qty,
      returnHome: _returnHome,
      companion: _companion,
    );
    if (err != null) {
      toast(context, err);
      return;
    }
    toast(context, 'Solicitud enviada. Recepción asignará un chofer.');
    setState(() {
      _addr.clear();
      _notes.clear();
      _date = null;
      _time = null;
      _qty = 1;
    });
  }

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

  List<Widget> _form(BuildContext context) {
    final state = AppScope.of(context);
    final List<Pet> pets = state.clientPets;
    final List<int> times = _timesFor(_date);
    final int? timeValue = (_time != null && times.contains(_time)) ? _time : null;
    if (pets.isEmpty) {
      return const [AppBanner(text: 'Registra una mascota para solicitar el servicio a domicilio.', warn: true, icon: Icons.pets)];
    }
    final Pet? selectedPet = _petId == null ? null : state.petById(_petId!);
    return [
      const AppBanner(
        text: 'Un chofer de la clínica recoge a tu mascota (o la atiende en tu domicilio) en la fecha y hora que elijas.',
        icon: Icons.local_shipping_outlined,
      ),
      AppDropdown<Pet>(
        label: 'Mascota',
        value: selectedPet,
        items: pets,
        labelOf: (Pet p) => '${p.name} · ${p.species}',
        onChanged: (Pet? p) => setState(() => _petId = p?.id),
      ),
      AppField(label: 'Dirección', controller: _addr, hint: 'Calle, número, colonia', prefixIcon: Icons.place_outlined),
      const SectionLabel('Fecha'),
      MonthCalendar(selected: _date, onPick: (DateTime d) => setState(() => _date = d)),
      AppDropdown<int>(
        label: 'Hora',
        value: timeValue,
        items: times,
        labelOf: (int m) => minutesLabel(m),
        onChanged: (int? m) => setState(() => _time = m),
      ),
      AppDropdown<String>(
        label: 'Motivo',
        value: _reason,
        items: _kReasons,
        labelOf: (String s) => s,
        onChanged: (String? v) => setState(() => _reason = v ?? _reason),
      ),
      Row(
        children: [
          const Expanded(
            child: Text('Cantidad de mascotas', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          IconBtn(icon: Icons.remove, onTap: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$_qty', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          IconBtn(icon: Icons.add, onTap: () => setState(() => _qty = _qty < 5 ? _qty + 1 : 5)),
        ],
      ),
      AppCard(
        child: Column(
          children: [
            _switchRow('Regreso a domicilio', 'El chofer devuelve a tu mascota a casa', _returnHome,
                (bool v) => setState(() => _returnHome = v)),
            const Divider(color: C.line),
            _switchRow('Voy acompañando', 'Viajo con el chofer', _companion, (bool v) => setState(() => _companion = v)),
          ],
        ),
      ),
      AppField(label: 'Notas (opcional)', controller: _notes, hint: 'Referencias, indicaciones…', maxLines: 3),
    ];
  }

  Widget _stepRow(int n, String label, int progress, {String? sub}) {
    final bool done = n < progress || (n == progress && progress == 4);
    final bool current = n == progress && !done;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? C.good : (current ? C.primary : C.surface2),
            border: Border.all(color: done ? C.good : (current ? C.primary : C.line)),
          ),
          child: done
              ? const Icon(Icons.check, size: 15, color: Colors.white)
              : Text('$n',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: current ? Colors.white : C.muted)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: (done || current) ? C.ink : C.muted)),
                if (sub != null) Text(sub, style: const TextStyle(fontSize: 11.5, color: C.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _tracking(BuildContext context, HomeRequest r) {
    final state = AppScope.of(context);
    final int p = r.status.progress;
    String step3 = 'En camino';
    if (r.status == HomeStatus.enServicio) step3 = 'En servicio';
    final bool hasDriver = r.driverId != null;
    return [
      HeroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(HomeRequest.serviceType,
                style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(state.petName(r.petId),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${formatDateShort(r.date)} · ${minutesLabel(r.timeMinutes)}',
                style: const TextStyle(color: Colors.white, fontSize: 12.5)),
            Text(r.addr, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 12.5)),
          ],
        ),
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: spaced([
            _stepRow(1, 'Solicitud enviada', p, sub: 'Recepción la está revisando'),
            _stepRow(2, 'Chofer asignado', p, sub: hasDriver ? '${state.driverName(r.driverId)} · ${state.vehicleOf(r.driverId)}' : 'Pendiente'),
            _stepRow(3, step3, p, sub: 'El chofer va hacia tu domicilio'),
            _stepRow(4, 'Concluido', p),
          ], 14),
        ),
      ),
      AppCard(
        child: InfoList([
          InfoItem('Estado', r.status.label),
          InfoItem('Motivo', r.reason),
          InfoItem('Mascotas', '${r.qty}'),
          InfoItem('Regreso a domicilio', r.returnHome ? 'Sí' : 'No'),
          InfoItem('Distancia estimada', r.trip.distanceLabel),
          InfoItem('Tiempo estimado', r.trip.durationLabel),
        ]),
      ),
      if (r.status == HomeStatus.concluido)
        AppButton('Solicitar otro servicio', icon: Icons.add, onPressed: state.finishHomeTracking),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final HomeRequest? current = state.currentHomeRequest;
    final bool tracking = current != null;
    return DetailScaffold(
      title: 'Servicio a domicilio',
      subtitle: tracking ? 'Seguimiento de tu solicitud' : 'Solicita una recolección',
      bottom: tracking || state.clientPets.isEmpty ? null : AppButton('Enviar solicitud', onPressed: _submit),
      children: tracking ? _tracking(context, current) : _form(context),
    );
  }
}
