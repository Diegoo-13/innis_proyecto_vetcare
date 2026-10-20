import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../logic/app_state.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// Panel del administrador: médicos, consultorios, choferes, servicios y contacto.
class AdminTab extends StatelessWidget {
  const AdminTab({super.key});

  void _delete(BuildContext context, String? Function() action, String okMsg) {
    final String? err = action();
    toast(context, err ?? okMsg);
  }

  Widget _row({
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    Widget? badge,
  }) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
                  if (badge != null) ...[const SizedBox(width: 6), badge],
                ]),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: C.muted)),
              ],
            ),
          ),
          IconBtn(icon: Icons.edit_outlined, onTap: onEdit, tooltip: 'Editar'),
          const SizedBox(width: 6),
          IconBtn(icon: Icons.delete_outline, color: C.bad, onTap: onDelete, tooltip: 'Eliminar'),
        ],
      ),
    );
  }

  Widget _header(String text, String addLabel, VoidCallback onAdd) {
    return Row(
      children: [
        Expanded(child: SectionLabel(text)),
        GestureDetector(
          onTap: onAdd,
          child: Text(addLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.primaryDark)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return TabPage(
      header: const RootBar(tag: 'Administrador'),
      children: [
        // ---------- Médicos ----------
        _header('Médicos', '+ Agregar', () => showAppSheet<void>(context, const _DoctorSheet())),
        for (final Doctor d in state.doctors)
          _row(
            title: d.name,
            subtitle: '${d.especialidad} · ${d.hours} · descansa ${d.rest == null ? 'variable' : kDayNames[d.rest!]}',
            badge: d.guardia ? const Pill('Guardia', kind: PillKind.bad) : null,
            onEdit: () => showAppSheet<void>(context, _DoctorSheet(doctor: d)),
            onDelete: () => _delete(context, () => state.deleteDoctor(d.id), 'Médico eliminado'),
          ),
        // ---------- Consultorios ----------
        const SectionLabel('Consultorios'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final String r in kRooms)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    const Icon(Icons.meeting_room_outlined, size: 17, color: C.primary),
                    const SizedBox(width: 8),
                    Text(r, style: const TextStyle(fontSize: 13)),
                    if (r == 'Consultorio 4') ...[
                      const SizedBox(width: 8),
                      const Text('Consulta · Visita · Retiro de puntos', style: TextStyle(fontSize: 11, color: C.muted)),
                    ],
                  ]),
                ),
            ],
          ),
        ),
        // ---------- Choferes ----------
        _header('Choferes', '+ Agregar', () => showAppSheet<void>(context, const _DriverSheet())),
        for (final Driver d in state.drivers)
          _row(
            title: d.name,
            subtitle: d.vehicle,
            onEdit: () => showAppSheet<void>(context, _DriverSheet(driver: d)),
            onDelete: () => _delete(context, () => state.deleteDriver(d.id), 'Chofer eliminado'),
          ),
        // ---------- Servicios ----------
        _header('Servicios y costos', '+ Agregar', () => showAppSheet<void>(context, const _ServiceSheet())),
        for (final Service s in state.services)
          _row(
            title: s.label,
            subtitle: '${money(s.price)} · ${s.minutes == 0 ? 'duración variable' : '${s.minutes} min'} · ${s.room ?? 'según disponibilidad'}',
            onEdit: () => showAppSheet<void>(context, _ServiceSheet(service: s)),
            onDelete: () => _delete(context, () => state.deleteService(s.id), 'Servicio eliminado'),
          ),
        AppButton('Aumento anual de precios',
            icon: Icons.trending_up, kind: BtnKind.ghost, onPressed: () => showAppSheet<void>(context, const _PriceSheet())),
        // ---------- Contacto ----------
        const SectionLabel('Contacto de la clínica'),
        AppCard(
          child: InfoList([
            InfoItem('Teléfono', state.clinic.phone),
            InfoItem('WhatsApp', state.clinic.whatsapp),
            InfoItem('Correo', state.clinic.email),
          ]),
        ),
        AppButton('Editar contacto',
            icon: Icons.edit_outlined, kind: BtnKind.ghost, onPressed: () => showAppSheet<void>(context, const _ClinicSheet())),
      ],
    );
  }
}

// Guarda y cierra la hoja; avisa con el messenger capturado antes de cerrar.
void _finish(BuildContext context, String? err, String okMsg) {
  final ScaffoldMessengerState msg = ScaffoldMessenger.of(context);
  if (err != null) {
    msg.hideCurrentSnackBar();
    msg.showSnackBar(SnackBar(content: Text(err)));
    return;
  }
  Navigator.pop(context);
  msg.hideCurrentSnackBar();
  msg.showSnackBar(SnackBar(content: Text(okMsg)));
}

// ======================= MÉDICO =======================

class _DoctorSheet extends StatefulWidget {
  const _DoctorSheet({this.doctor});
  final Doctor? doctor;

  @override
  State<_DoctorSheet> createState() => _DoctorSheetState();
}

class _DoctorSheetState extends State<_DoctorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _esp;
  late final TextEditingController _ced;
  late int _start;
  late int _end;
  int? _rest;
  late bool _guardia;

  @override
  void initState() {
    super.initState();
    final Doctor? d = widget.doctor;
    _name = TextEditingController(text: d?.name ?? '');
    _esp = TextEditingController(text: d?.especialidad ?? '');
    _ced = TextEditingController(text: d?.cedula ?? '');
    _start = d?.startH ?? 9;
    _end = d?.endH ?? 17;
    _rest = d?.rest;
    _guardia = d?.guardia ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _esp.dispose();
    _ced.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<int> hours = <int>[for (int h = 6; h <= 21; h++) h];
    return SheetBody(
      title: widget.doctor == null ? 'Nuevo médico' : 'Editar médico',
      children: [
        AppField(label: 'Nombre', controller: _name, hint: 'Dr. / Dra.'),
        AppField(label: 'Especialidad', controller: _esp),
        AppField(label: 'Cédula profesional', controller: _ced),
        Row(
          children: [
            Expanded(
              child: AppDropdown<int>(
                label: 'Entrada',
                value: _start,
                items: hours,
                labelOf: (int h) => hourLabel(h),
                onChanged: (int? v) => setState(() => _start = v ?? _start),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppDropdown<int>(
                label: 'Salida',
                value: _end,
                items: hours,
                labelOf: (int h) => hourLabel(h),
                onChanged: (int? v) => setState(() => _end = v ?? _end),
              ),
            ),
          ],
        ),
        AppDropdown<int?>(
          label: 'Día de descanso',
          value: _rest,
          items: const <int?>[null, 0, 1, 2, 3, 4, 5, 6],
          labelOf: (int? v) => v == null ? 'Sin descanso fijo' : capitalize(kDayNames[v]),
          onChanged: (int? v) => setState(() => _rest = v),
        ),
        Row(
          children: [
            const Expanded(child: Text('Médico de guardia (urgencias)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
            Switch(value: _guardia, activeColor: C.primary, onChanged: (bool v) => setState(() => _guardia = v)),
          ],
        ),
        AppButton('Guardar', onPressed: () {
          final String? err = state.saveDoctor(
            id: widget.doctor?.id,
            name: _name.text,
            especialidad: _esp.text,
            cedula: _ced.text,
            startH: _start,
            endH: _end,
            rest: _rest,
            guardia: _guardia,
          );
          _finish(context, err, 'Médico guardado');
        }),
      ],
    );
  }
}

// ======================= CHOFER =======================

class _DriverSheet extends StatefulWidget {
  const _DriverSheet({this.driver});
  final Driver? driver;

  @override
  State<_DriverSheet> createState() => _DriverSheetState();
}

class _DriverSheetState extends State<_DriverSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.driver?.name ?? '');
  late final TextEditingController _vehicle = TextEditingController(text: widget.driver?.vehicle ?? '');

  @override
  void dispose() {
    _name.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return SheetBody(
      title: widget.driver == null ? 'Nuevo chofer' : 'Editar chofer',
      children: [
        AppField(label: 'Nombre', controller: _name),
        AppField(label: 'Vehículo', controller: _vehicle, hint: 'Marca, modelo y placas'),
        AppButton('Guardar', onPressed: () {
          final String? err = state.saveDriver(id: widget.driver?.id, name: _name.text, vehicle: _vehicle.text);
          _finish(context, err, 'Chofer guardado');
        }),
      ],
    );
  }
}

// ======================= SERVICIO =======================

class _ServiceSheet extends StatefulWidget {
  const _ServiceSheet({this.service});
  final Service? service;

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  late final TextEditingController _label = TextEditingController(text: widget.service?.label ?? '');
  late final TextEditingController _minutes = TextEditingController(text: '${widget.service?.minutes ?? 30}');
  late final TextEditingController _price = TextEditingController(text: '${widget.service?.price ?? 0}');
  late String? _room = widget.service?.room;

  @override
  void dispose() {
    _label.dispose();
    _minutes.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return SheetBody(
      title: widget.service == null ? 'Nuevo servicio' : 'Editar servicio',
      children: [
        AppField(label: 'Nombre', controller: _label),
        AppField(label: 'Duración en minutos (0 = variable)', controller: _minutes, keyboardType: TextInputType.number),
        AppField(label: 'Costo', controller: _price, keyboardType: TextInputType.number),
        AppDropdown<String?>(
          label: 'Consultorio',
          value: _room,
          items: <String?>[null, ...kRooms],
          labelOf: (String? r) => r ?? 'Según disponibilidad del médico',
          onChanged: (String? r) => setState(() => _room = r),
        ),
        AppButton('Guardar', onPressed: () {
          final int? mins = int.tryParse(_minutes.text.trim());
          final int? price = int.tryParse(_price.text.trim());
          if (mins == null || price == null) {
            toast(context, 'Duración y costo deben ser números');
            return;
          }
          final String? err = state.saveService(
            id: widget.service?.id,
            label: _label.text,
            minutes: mins,
            price: price,
            room: _room,
          );
          _finish(context, err, 'Servicio guardado');
        }),
      ],
    );
  }
}

// ======================= AUMENTO DE PRECIOS =======================

class _PriceSheet extends StatefulWidget {
  const _PriceSheet();

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  final TextEditingController _pct = TextEditingController(text: '5');

  @override
  void dispose() {
    _pct.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return SheetBody(
      title: 'Aumento anual de precios',
      subtitle: 'Se aplica el mismo porcentaje a todos los servicios con costo.',
      children: [
        AppField(label: 'Porcentaje (%)', controller: _pct, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        AppButton('Aplicar aumento', onPressed: () {
          final double? pct = double.tryParse(_pct.text.trim().replaceAll(',', '.'));
          final String? err = state.applyPriceIncrease(pct ?? double.nan);
          _finish(context, err, 'Precios actualizados');
        }),
      ],
    );
  }
}

// ======================= CONTACTO =======================

class _ClinicSheet extends StatefulWidget {
  const _ClinicSheet();

  @override
  State<_ClinicSheet> createState() => _ClinicSheetState();
}

class _ClinicSheetState extends State<_ClinicSheet> {
  TextEditingController? _phone;
  TextEditingController? _wa;
  TextEditingController? _mail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phone == null) {
      final ClinicInfo c = AppScope.of(context).clinic;
      _phone = TextEditingController(text: c.phone);
      _wa = TextEditingController(text: c.whatsapp);
      _mail = TextEditingController(text: c.email);
    }
  }

  @override
  void dispose() {
    _phone?.dispose();
    _wa?.dispose();
    _mail?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return SheetBody(
      title: 'Contacto de la clínica',
      children: [
        AppField(label: 'Teléfono', controller: _phone, keyboardType: TextInputType.phone),
        AppField(label: 'WhatsApp', controller: _wa, keyboardType: TextInputType.phone),
        AppField(label: 'Correo', controller: _mail, keyboardType: TextInputType.emailAddress),
        AppButton('Guardar', onPressed: () {
          final String? err = state.updateClinic(phone: _phone!.text, whatsapp: _wa!.text, email: _mail!.text);
          _finish(context, err, 'Contacto actualizado');
        }),
      ],
    );
  }
}
