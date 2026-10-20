import 'package:flutter/material.dart';

import '../../logic/app_scope.dart';
import '../../logic/app_state.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/clinic_sheets.dart';
import '../../widgets/common.dart';

/// El chofer ve "Pendiente" mientras la ruta está asignada y aún no sale.
String _driverStatusLabel(HomeStatus s) => s == HomeStatus.asignado ? 'Pendiente' : s.label;

PillKind _driverPillKind(HomeStatus s) {
  if (s == HomeStatus.concluido) return PillKind.good;
  if (s == HomeStatus.asignado) return PillKind.warn;
  return PillKind.info;
}

class ChoferRoutesTab extends StatelessWidget {
  const ChoferRoutesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final List<HomeRequest> routes = state.driverRoutes;
    final List<HomeRequest> active = routes.where((HomeRequest r) => r.status != HomeStatus.concluido).toList();
    final List<HomeRequest> done = routes.where((HomeRequest r) => r.status == HomeStatus.concluido).toList();

    Widget card(HomeRequest r) {
      return AppCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ChoferRouteDetailScreen(reqId: r.id)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: C.primarySoft, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.local_shipping_outlined, color: C.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${state.petName(r.petId)} · ${r.reason}',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  Text('${formatDateShort(r.date)} · ${minutesLabel(r.timeMinutes)}',
                      style: const TextStyle(fontSize: 12, color: C.inkSoft)),
                  Text(r.addr, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: C.muted)),
                ],
              ),
            ),
            Pill(_driverStatusLabel(r.status), kind: _driverPillKind(r.status)),
          ],
        ),
      );
    }

    return TabPage(
      header: RootBar(tag: 'Chofer', trailing: Text(state.currentDriver.name, style: const TextStyle(fontSize: 12, color: C.muted))),
      children: [
        const Text('Mis rutas', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
        if (routes.isEmpty)
          const AppCard(
            child: Text('Recepción aún no te asigna rutas.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: C.muted)),
          ),
        if (active.isNotEmpty) const SectionLabel('Activas'),
        for (final HomeRequest r in active) card(r),
        if (done.isNotEmpty) const SectionLabel('Concluidas'),
        for (final HomeRequest r in done) card(r),
      ],
    );
  }
}

class ChoferRouteDetailScreen extends StatelessWidget {
  const ChoferRouteDetailScreen({super.key, required this.reqId});
  final String reqId;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final HomeRequest? r = state.homeRequestById(reqId);
    if (r == null) {
      return const DetailScaffold(title: 'Ruta', children: [Text('La ruta ya no existe.')]);
    }
    final Pet? pet = state.petById(r.petId);
    final bool finished = r.status == HomeStatus.concluido;

    return DetailScaffold(
      title: 'Ruta a domicilio',
      subtitle: '${formatDateShort(r.date)} · ${minutesLabel(r.timeMinutes)}',
      bottom: AppButton(
        state.driverActionLabel(r.status),
        icon: finished ? Icons.check_circle_outline : Icons.arrow_forward,
        onPressed: finished ? null : () => state.advanceHomeStatus(r.id),
      ),
      children: [
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(pet?.name ?? 'Mascota',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  Pill(_driverStatusLabel(r.status), kind: _driverPillKind(r.status)),
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.place_outlined, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Expanded(child: Text(r.addr, style: const TextStyle(color: Colors.white, fontSize: 13))),
              ]),
            ],
          ),
        ),
        const SectionLabel('Detalles del viaje'),
        AppCard(
          child: InfoList([
            InfoItem('Motivo', r.reason),
            InfoItem('Mascotas', '${r.qty}'),
            InfoItem('Distancia estimada', r.trip.distanceLabel),
            InfoItem('Tiempo estimado', r.trip.durationLabel),
            InfoItem('Regreso a domicilio', r.returnHome ? 'Sí' : 'No'),
            InfoItem('Acompañante', r.companion ? 'Sí' : 'No'),
            InfoItem('Vehículo', state.vehicleOf(r.driverId)),
            if (r.notes.isNotEmpty) InfoItem('Notas', r.notes),
          ]),
        ),
        AppButton('Contactar al cliente',
            icon: Icons.phone_outlined,
            kind: BtnKind.ghost,
            onPressed: () => showOwnerContactSheet(context,
                petName: pet?.name ?? 'Mascota', phone: pet?.phone ?? '', extra: r.addr)),
        AppButton('Llamar a recepción',
            icon: Icons.support_agent, kind: BtnKind.ghost, onPressed: () => showClinicContactSheet(context)),
      ],
    );
  }
}
