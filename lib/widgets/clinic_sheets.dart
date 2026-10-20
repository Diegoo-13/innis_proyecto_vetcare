import 'package:flutter/material.dart';

import '../logic/app_scope.dart';
import '../theme.dart';
import 'common.dart';

/// Hoja de "Urgencias y guardia": médicos de guardia y contacto directo a la clínica.
void showUrgenciasSheet(BuildContext context) {
  final state = AppScope.of(context);
  final guards = state.doctors.where((d) => d.guardia).toList();
  showAppSheet<void>(
    context,
    Builder(builder: (BuildContext ctx) {
      return SheetBody(
        title: 'Urgencias y guardia',
        subtitle: 'Médico(s) de guardia ahora:',
        children: [
          if (guards.isEmpty)
            const Text('Hoy no hay médico de guardia registrado.', style: TextStyle(fontSize: 12.5, color: C.muted)),
          for (final d in guards)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: C.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Text('${d.especialidad} · ${d.hours}', style: const TextStyle(fontSize: 12, color: C.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          AppButton(
            'Llamar a urgencias · ${state.clinic.phone}',
            icon: Icons.phone_outlined,
            onPressed: () {
              toast(ctx, 'Llamando a urgencias: ${state.clinic.phone}');
              Navigator.pop(ctx);
            },
          ),
          AppButton(
            'WhatsApp · ${state.clinic.whatsapp}',
            icon: Icons.send,
            kind: BtnKind.accent,
            onPressed: () {
              toast(ctx, 'Abriendo WhatsApp: ${state.clinic.whatsapp}');
              Navigator.pop(ctx);
            },
          ),
          AppButton('Cerrar', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx)),
        ],
      );
    }),
  );
}

/// Hoja con teléfono, WhatsApp y correo de la clínica (editables desde Administrador).
void showClinicContactSheet(BuildContext context) {
  final state = AppScope.of(context);
  showAppSheet<void>(
    context,
    Builder(builder: (BuildContext ctx) {
      return SheetBody(
        title: 'Contactar a la clínica',
        children: [
          AppCard(
            child: InfoList([
              InfoItem('Teléfono', state.clinic.phone),
              InfoItem('WhatsApp', state.clinic.whatsapp),
              InfoItem('Correo', state.clinic.email),
            ]),
          ),
          AppButton('Llamar', icon: Icons.phone_outlined, onPressed: () {
            toast(ctx, 'Llamando a la clínica: ${state.clinic.phone}');
            Navigator.pop(ctx);
          }),
          AppButton('WhatsApp', icon: Icons.send, kind: BtnKind.accent, onPressed: () {
            toast(ctx, 'Abriendo WhatsApp: ${state.clinic.whatsapp}');
            Navigator.pop(ctx);
          }),
          AppButton('Enviar correo', kind: BtnKind.ghost, onPressed: () {
            toast(ctx, 'Escribiendo a ${state.clinic.email}');
            Navigator.pop(ctx);
          }),
          AppButton('Cerrar', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx)),
        ],
      );
    }),
  );
}

/// Hoja para contactar al dueño de una mascota (recepción y chofer).
void showOwnerContactSheet(BuildContext context, {required String petName, required String phone, String? extra}) {
  showAppSheet<void>(
    context,
    Builder(builder: (BuildContext ctx) {
      return SheetBody(
        title: 'Contactar cliente',
        subtitle: 'Dueño de $petName · $phone${extra == null ? '' : '\n$extra'}.',
        children: [
          AppButton('Llamar', icon: Icons.phone_outlined, onPressed: () {
            toast(ctx, 'Llamando al cliente…');
            Navigator.pop(ctx);
          }),
          AppButton('WhatsApp', icon: Icons.send, kind: BtnKind.accent, onPressed: () {
            toast(ctx, 'Mensaje enviado por WhatsApp');
            Navigator.pop(ctx);
          }),
          AppButton('Cerrar', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx)),
        ],
      );
    }),
  );
}
