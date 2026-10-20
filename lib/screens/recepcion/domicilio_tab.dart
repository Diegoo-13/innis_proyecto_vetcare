import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../logic/app_state.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// Recepción asigna chofer a las solicitudes de servicio a domicilio.
class RecepDomicilioTab extends StatefulWidget {
  const RecepDomicilioTab({super.key});

  @override
  State<RecepDomicilioTab> createState() => _RecepDomicilioTabState();
}

class _RecepDomicilioTabState extends State<RecepDomicilioTab> {
  final Map<String, String> _chosen = <String, String>{}; // solicitud -> chofer

  Widget _requestHeader(AppState state, HomeRequest r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${state.petName(r.petId)} · ${r.reason}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            Pill(r.status.label, kind: r.status == HomeStatus.concluido ? PillKind.good : (r.status == HomeStatus.porAsignar ? PillKind.warn : PillKind.info)),
          ],
        ),
        const SizedBox(height: 4),
        Text('${formatDateShort(r.date)} · ${minutesLabel(r.timeMinutes)}', style: const TextStyle(fontSize: 12, color: C.inkSoft)),
        Text(r.addr, style: const TextStyle(fontSize: 12, color: C.muted)),
      ],
    );
  }

  Widget _pendingCard(BuildContext context, AppState state, HomeRequest r) {
    final String? driverId = _chosen[r.id];
    final Driver? driver = driverId == null ? null : state.driverById(driverId);
    return AppCard(
      borderColor: C.warn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: spaced([
          _requestHeader(state, r),
          InfoList([
            InfoItem('Distancia estimada', r.trip.distanceLabel),
            InfoItem('Tiempo estimado', r.trip.durationLabel),
            InfoItem('Regreso a domicilio', r.returnHome ? 'Sí' : 'No'),
            InfoItem('Acompañante', r.companion ? 'Sí' : 'No'),
          ]),
          if (r.notes.isNotEmpty) Text('Notas: ${r.notes}', style: const TextStyle(fontSize: 12, color: C.inkSoft)),
          AppDropdown<Driver>(
            label: 'Chofer',
            value: driver,
            items: state.drivers,
            labelOf: (Driver d) => '${d.name} · ${state.driverAvailability(d.id)}',
            onChanged: (Driver? d) => setState(() {
              if (d != null) _chosen[r.id] = d.id;
            }),
          ),
          if (driver != null)
            Text('Vehículo: ${driver.vehicle}', style: const TextStyle(fontSize: 12, color: C.inkSoft)),
          AppButton('Asignar chofer', small: true, onPressed: driver == null
              ? null
              : () {
                  final String? err = state.assignDriver(r.id, driver.id);
                  if (err != null) {
                    toast(context, err);
                  } else {
                    _chosen.remove(r.id);
                    toast(context, 'Asignado a ${driver.name}');
                  }
                }),
        ], 10),
      ),
    );
  }

  Widget _assignedCard(AppState state, HomeRequest r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: spaced([
          _requestHeader(state, r),
          Text('Chofer: ${state.driverName(r.driverId)} · ${state.vehicleOf(r.driverId)}',
              style: const TextStyle(fontSize: 12, color: C.inkSoft)),
        ], 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final List<HomeRequest> all = state.repo.homeRequests;
    final List<HomeRequest> pending = all.where((HomeRequest r) => r.status == HomeStatus.porAsignar).toList();
    final List<HomeRequest> active =
        all.where((HomeRequest r) => r.status != HomeStatus.porAsignar && r.status != HomeStatus.concluido).toList();
    final List<HomeRequest> done = all.where((HomeRequest r) => r.status == HomeStatus.concluido).toList();

    return TabPage(
      header: const RootBar(title: 'Servicio a domicilio'),
      children: [
        if (all.isEmpty)
          const AppCard(
            child: Text('No hay solicitudes todavía.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: C.muted)),
          ),
        if (pending.isNotEmpty) const SectionLabel('Por asignar'),
        for (final HomeRequest r in pending) _pendingCard(context, state, r),
        if (active.isNotEmpty) const SectionLabel('En curso'),
        for (final HomeRequest r in active) _assignedCard(state, r),
        if (done.isNotEmpty) const SectionLabel('Concluidas'),
        for (final HomeRequest r in done) _assignedCard(state, r),
      ],
    );
  }
}
