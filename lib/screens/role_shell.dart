import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import 'admin/admin_tab.dart';
import 'chofer/routes_tab.dart';
import 'cliente/appts_tab.dart';
import 'cliente/home_tab.dart';
import 'cliente/pets_tab.dart';
import 'profile_tab.dart';
import 'recepcion/agenda_tab.dart';
import 'recepcion/domicilio_tab.dart';
import 'recepcion/reminders_tab.dart';

class _TabDef {
  const _TabDef(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Contenedor con barra de pestañas inferior; cambia según el rol que inició sesión.
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.role});
  final Role role;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;

  List<_TabDef> get _defs {
    switch (widget.role) {
      case Role.cliente:
        return const [
          _TabDef('Inicio', Icons.home_outlined),
          _TabDef('Citas', Icons.calendar_month_outlined),
          _TabDef('Mascotas', Icons.pets),
          _TabDef('Perfil', Icons.person_outline),
        ];
      case Role.recepcion:
        return const [
          _TabDef('Agenda', Icons.calendar_month_outlined),
          _TabDef('Avisos', Icons.notifications_none),
          _TabDef('Domicilio', Icons.local_shipping_outlined),
          _TabDef('Perfil', Icons.person_outline),
        ];
      case Role.chofer:
        return const [
          _TabDef('Rutas', Icons.local_shipping_outlined),
          _TabDef('Perfil', Icons.person_outline),
        ];
      case Role.admin:
        return const [
          _TabDef('Panel', Icons.settings_outlined),
          _TabDef('Perfil', Icons.person_outline),
        ];
    }
  }

  List<Widget> _pages() {
    switch (widget.role) {
      case Role.cliente:
        return [
          ClienteHomeTab(onGoTab: (int i) => setState(() => _index = i)),
          const ClienteApptsTab(),
          const ClientePetsTab(),
          const ProfileTab(),
        ];
      case Role.recepcion:
        return const [
          RecepAgendaTab(),
          RecepRemindersTab(),
          RecepDomicilioTab(),
          ProfileTab(),
        ];
      case Role.chofer:
        return const [
          ChoferRoutesTab(),
          ProfileTab(),
        ];
      case Role.admin:
        return const [
          AdminTab(),
          ProfileTab(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final defs = _defs;
    final pages = _pages();
    final int safeIndex = _index >= pages.length ? 0 : _index;
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: safeIndex,
          selectedItemColor: C.primary,
          unselectedItemColor: C.muted,
          selectedFontSize: 10.5,
          unselectedFontSize: 10.5,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          onTap: (int i) => setState(() => _index = i),
          items: [
            for (final _TabDef d in defs) BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
          ],
        ),
      ),
    );
  }
}
