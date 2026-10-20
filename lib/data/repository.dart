import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/formatters.dart';

/// Capa de datos (patrón Repository). Hoy guarda todo en memoria con datos de ejemplo;
/// el día que exista una API / base de datos solo hay que cambiar esta clase.
class Repository {
  Repository.seed(DateTime now) {
    _seed(now);
  }

  final List<Client> clients = <Client>[];
  final List<Pet> pets = <Pet>[];
  final List<Doctor> doctors = <Doctor>[];
  final List<Service> services = <Service>[];
  final List<Driver> drivers = <Driver>[];
  final List<Appointment> appointments = <Appointment>[];
  final List<Surgery> surgeries = <Surgery>[];
  final List<HomeRequest> homeRequests = <HomeRequest>[];

  // Valores de ejemplo: reemplazar por los reales de la clínica.
  ClinicInfo clinic = ClinicInfo(
    phone: '477 000 0000',
    whatsapp: '477 000 0000',
    email: 'contacto@vetcare.example',
  );

  /// Consultorio de respaldo cuando el servicio no tiene uno fijo.
  final Map<String, String> defaultRooms = <String, String>{
    'ibarra': 'Consultorio 2',
    'soto': 'Consultorio 1',
    'cobos': 'Consultorio 3',
  };

  int _seq = 0;
  String newId(String prefix) {
    _seq++;
    return '$prefix${DateTime.now().millisecondsSinceEpoch % 100000}_$_seq';
  }

  String nextPetCode() {
    int n = 1003;
    while (pets.any((p) => p.code == 'VC-$n')) {
      n++;
    }
    return 'VC-$n';
  }

  Service serviceById(String id) => services.firstWhere((s) => s.id == id);

  void _seed(DateTime now) {
    final DateTime today = dateOnly(now);
    final DateTime tomorrow = nextOpenDay(addDays(today, 1));

    clients.add(Client(
      id: 'cli1',
      name: 'Mariana López',
      email: 'mariana.lopez@correo.com',
      phone: '477 123 4567',
    ));

    pets.addAll(<Pet>[
      Pet(id: 'rocco', code: 'VC-1001', name: 'Rocco', species: 'Perro', category: PetCategory.pequenas, breed: 'Golden Retriever', color: 'Dorado', age: '3 años', ownerId: 'cli1', ownerName: 'Mariana López', phone: '477 123 4567'),
      Pet(id: 'mimi', code: 'VC-1002', name: 'Mimi', species: 'Gato', category: PetCategory.pequenas, breed: 'Siamés', color: 'Crema y café', age: '1 año', ownerId: 'cli1', ownerName: 'Mariana López', phone: '477 123 4567'),
      Pet(id: 'p1010', code: 'VC-1010', name: 'Manchas', species: 'Perro', category: PetCategory.pequenas, breed: 'Criollo', color: 'Blanco con negro', age: '4 años', ownerId: 'ext-laura', ownerName: 'Laura Díaz', phone: '477 100 2001'),
      Pet(id: 'p1011', code: 'VC-1011', name: 'Toby', species: 'Perro', category: PetCategory.pequenas, breed: 'Schnauzer', color: 'Gris', age: '5 años', ownerId: 'ext-jorge', ownerName: 'Jorge Ramos', phone: '477 100 2002'),
      Pet(id: 'p1012', code: 'VC-1012', name: 'Firulais', species: 'Perro', category: PetCategory.pequenas, breed: 'Mestizo', color: 'Café', age: '6 años', ownerId: 'ext-luis', ownerName: 'Luis Cano', phone: '477 100 2003'),
      Pet(id: 'p1013', code: 'VC-1013', name: 'Nube', species: 'Gato', category: PetCategory.pequenas, breed: 'Persa', color: 'Blanco', age: '2 años', ownerId: 'ext-ana', ownerName: 'Ana Torres', phone: '477 100 2004'),
      Pet(id: 'p1014', code: 'VC-1014', name: 'Canela', species: 'Perro', category: PetCategory.pequenas, breed: 'Labrador', color: 'Miel', age: '3 años', ownerId: 'ext-carlos', ownerName: 'Carlos Reyes', phone: '477 100 2005'),
      // Segundo "Rocco": recepción los distingue por ID, raza o teléfono.
      Pet(id: 'p1040', code: 'VC-1040', name: 'Rocco', species: 'Perro', category: PetCategory.pequenas, breed: 'Bóxer', color: 'Atigrado', age: '4 años', ownerId: 'ext-pedro', ownerName: 'Pedro Mena', phone: '477 555 0188'),
    ]);

    doctors.addAll(<Doctor>[
      Doctor(id: 'ibarra', name: 'Dra. Ibarra', especialidad: 'Medicina interna', cedula: '10234567', startH: 9, endH: 17, rest: 6),
      Doctor(id: 'soto', name: 'Dr. Soto', especialidad: 'Cirugía general', cedula: '09876543', startH: 8, endH: 15, rest: 3),
      Doctor(id: 'cobos', name: 'Dra. Cobos', especialidad: 'Medicina felina', cedula: '11223344', startH: 10, endH: 18, rest: 1, guardia: true),
    ]);

    // Precios de ejemplo (no son los reales de la clínica).
    services.addAll(<Service>[
      Service(id: 'consulta', label: 'Consulta general', icon: Icons.medical_services_outlined, minutes: 30, price: 350, room: 'Consultorio 4'),
      Service(id: 'visita', label: 'Visita', icon: Icons.person_outline, minutes: 20, price: 200, room: 'Consultorio 4'),
      Service(id: 'puntos', label: 'Retiro de puntos', icon: Icons.content_cut, minutes: 15, price: 150, room: 'Consultorio 4'),
      Service(id: 'vacuna', label: 'Vacunación', icon: Icons.medication_outlined, minutes: 20, price: 280),
      Service(id: 'despara', label: 'Desparasitación', icon: Icons.shield_outlined, minutes: 15, price: 180),
      Service(id: 'rayosx', label: 'Rayos X', icon: Icons.photo_camera_outlined, minutes: 20, price: 450),
      Service(id: 'cirugia', label: 'Cirugía', icon: Icons.healing, minutes: 90, price: 2500),
      Service(id: 'hosp', label: 'Hospitalización', icon: Icons.bed_outlined, minutes: 0, price: 600),
      Service(id: 'limpieza', label: 'Limpieza dental', icon: Icons.cleaning_services_outlined, minutes: 45, price: 900),
    ]);

    drivers.addAll(<Driver>[
      Driver(id: 'drv1', name: 'Ricardo Peña', vehicle: 'Tsuru blanco · ABC-123-A'),
      Driver(id: 'drv2', name: 'Lupita Sánchez', vehicle: 'Nissan NP300 gris · XYZ-456-B'),
    ]);

    Appointment appt(String id, String petId, String serviceId, String doctorId, String room, DateTime day, int h, int m,
        {ApptStatus status = ApptStatus.confirmada, bool checkedIn = false}) {
      return Appointment(
        id: id,
        petId: petId,
        serviceId: serviceId,
        doctorId: doctorId,
        room: room,
        start: DateTime(day.year, day.month, day.day, h, m),
        durationMin: serviceById(serviceId).effectiveMinutes,
        status: status,
        checkedIn: checkedIn,
      );
    }

    appointments.addAll(<Appointment>[
      // Agenda de hoy (r3 y r4 se empalman a propósito para demostrar la detección de conflictos).
      appt('r1', 'p1010', 'consulta', 'ibarra', 'Consultorio 4', today, 9, 0),
      appt('r2', 'p1011', 'despara', 'soto', 'Consultorio 2', today, 9, 30, checkedIn: true),
      appt('r3', 'rocco', 'vacuna', 'ibarra', 'Consultorio 2', today, 11, 0),
      appt('r4', 'p1012', 'cirugia', 'ibarra', 'Consultorio 2', today, 11, 0),
      appt('r5', 'mimi', 'limpieza', 'cobos', 'Consultorio 3', today, 12, 0, status: ApptStatus.pendiente),
      appt('r6', 'p1013', 'consulta', 'soto', 'Consultorio 4', today, 13, 0),
      appt('r7', 'p1040', 'consulta', 'soto', 'Consultorio 4', today, 14, 0),
      // Citas de mañana (alimentan los recordatorios de recepción).
      appt('a1', 'rocco', 'vacuna', 'ibarra', 'Consultorio 2', tomorrow, 10, 0),
      appt('t2', 'p1014', 'consulta', 'soto', 'Consultorio 4', tomorrow, 9, 30),
      appt('t3', 'p1013', 'consulta', 'soto', 'Consultorio 4', tomorrow, 13, 0),
      // Otras citas del cliente.
      appt('a2', 'mimi', 'consulta', 'soto', 'Consultorio 4', nextOpenDay(addDays(today, 5)), 9, 30, status: ApptStatus.pendiente),
      appt('a3', 'rocco', 'despara', 'cobos', 'Consultorio 3', addDays(today, -35), 12, 0, status: ApptStatus.concluida),
    ]);

    homeRequests.addAll(<HomeRequest>[
      HomeRequest(
        id: 'h1', clientId: 'cli1', petId: 'rocco', addr: 'Av. Hidalgo 214, Centro',
        date: tomorrow, timeMinutes: 750, notes: 'Rocco se pone nervioso con ruidos fuertes.',
        reason: 'Consulta general', qty: 1, returnHome: true, companion: false,
        trip: const Trip(distanceKm: 3.8, minutes: 14),
        status: HomeStatus.asignado, driverId: 'drv1',
      ),
      HomeRequest(
        id: 'h2', clientId: 'cli1', petId: 'mimi', addr: 'Calle Reforma 88',
        date: tomorrow, timeMinutes: 960, notes: 'Portón azul, tocar timbre.',
        reason: 'Vacunación', qty: 1, returnHome: false, companion: true,
        trip: const Trip(distanceKm: 5.2, minutes: 18),
      ),
    ]);
  }
}
