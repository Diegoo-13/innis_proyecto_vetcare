import 'package:flutter/material.dart';

import '../utils/formatters.dart';

// ======================= ENUMS =======================

enum Role { cliente, recepcion, chofer, admin }

extension RoleLabel on Role {
  String get label {
    if (this == Role.cliente) return 'Cliente';
    if (this == Role.recepcion) return 'Recepción';
    if (this == Role.chofer) return 'Chofer';
    return 'Administrador';
  }
}

enum PetCategory { pequenas, exoticos, grandes }

extension PetCategoryLabel on PetCategory {
  String get label {
    if (this == PetCategory.pequenas) return 'Especies pequeñas';
    if (this == PetCategory.exoticos) return 'Exóticos';
    return 'Grandes especies';
  }
}

const List<String> kSpecies = [
  'Perro', 'Gato', 'Conejo', 'Ave', 'Reptil', 'Vaca', 'Burro', 'Cerdo', 'Caballo', 'Otro',
];

/// La categoría se autocompleta según la especie (apuntes del cliente).
PetCategory categoryForSpecies(String species) {
  switch (species) {
    case 'Perro':
    case 'Gato':
    case 'Gata':
    case 'Conejo':
      return PetCategory.pequenas;
    case 'Vaca':
    case 'Burro':
    case 'Cerdo':
    case 'Caballo':
      return PetCategory.grandes;
    default:
      return PetCategory.exoticos;
  }
}

enum ApptStatus { pendiente, confirmada, concluida, cancelada }

extension ApptStatusLabel on ApptStatus {
  String get label {
    if (this == ApptStatus.pendiente) return 'Pendiente';
    if (this == ApptStatus.confirmada) return 'Confirmada';
    if (this == ApptStatus.concluida) return 'Concluida';
    return 'Cancelada';
  }
}

enum HomeStatus { porAsignar, asignado, enCamino, enServicio, concluido }

extension HomeStatusLabel on HomeStatus {
  String get label {
    if (this == HomeStatus.porAsignar) return 'Por asignar';
    if (this == HomeStatus.asignado) return 'Asignado';
    if (this == HomeStatus.enCamino) return 'En camino';
    if (this == HomeStatus.enServicio) return 'En servicio';
    return 'Concluido';
  }

  /// Avance (1..4) del seguimiento que ve el cliente.
  int get progress {
    if (this == HomeStatus.porAsignar) return 1;
    if (this == HomeStatus.asignado) return 2;
    if (this == HomeStatus.enCamino || this == HomeStatus.enServicio) return 3;
    return 4;
  }
}

/// Resultado de consultar si un horario se puede ocupar.
enum SlotState { ok, rest, outOfHours, busy, surgery, past }

// ======================= ENTIDADES =======================

class Client {
  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.remindDayBefore = true,
    this.remindMorning = true,
  });

  final String id;
  String name;
  String email;
  String phone;
  bool remindDayBefore;
  bool remindMorning;

  String get firstName => name.trim().split(' ').first;
  String get initials {
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class Pet {
  Pet({
    required this.id,
    required this.code,
    required this.name,
    required this.species,
    required this.category,
    required this.breed,
    required this.color,
    required this.age,
    required this.ownerId,
    required this.ownerName,
    required this.phone,
  });

  final String id;
  final String code; // VC-xxxx
  String name;
  String species;
  PetCategory category;
  String breed;
  String color;
  String age;
  String ownerId;
  String ownerName;
  String phone;
}

class Doctor {
  Doctor({
    required this.id,
    required this.name,
    required this.especialidad,
    required this.cedula,
    required this.startH,
    required this.endH,
    this.rest,
    this.guardia = false,
  });

  final String id;
  String name;
  String especialidad;
  String cedula;
  int startH;
  int endH;
  int? rest; // 0 = domingo ... 6 = sábado, null = sin descanso fijo
  bool guardia;

  String get hours => '${hourLabel(startH)} – ${hourLabel(endH)}';
}

class Service {
  Service({
    required this.id,
    required this.label,
    required this.icon,
    required this.minutes,
    required this.price,
    this.room,
  });

  final String id;
  String label;
  IconData icon;
  int minutes; // 0 = duración variable
  int price;
  String? room; // consultorio fijo, o null = según disponibilidad

  int get effectiveMinutes => minutes > 0 ? minutes : 30;
}

class Driver {
  Driver({required this.id, required this.name, required this.vehicle});

  final String id;
  String name;
  String vehicle;
}

class ClinicInfo {
  ClinicInfo({required this.phone, required this.whatsapp, required this.email});

  String phone;
  String whatsapp;
  String email;
}

class Appointment {
  Appointment({
    required this.id,
    required this.petId,
    required this.serviceId,
    required this.doctorId,
    required this.room,
    required this.start,
    required this.durationMin,
    this.status = ApptStatus.confirmada,
    this.checkedIn = false,
    this.isNewPatient = false,
    this.reminderOn = true,
    this.reminderSent = false,
  });

  final String id;
  String petId;
  String serviceId;
  String doctorId;
  String room;
  DateTime start;
  int durationMin;
  ApptStatus status;
  bool checkedIn;
  bool isNewPatient;
  bool reminderOn;
  bool reminderSent;

  DateTime get end => start.add(Duration(minutes: durationMin));

  /// Una cita activa ocupa horario, médico y consultorio.
  bool get isActive =>
      status == ApptStatus.pendiente || status == ApptStatus.confirmada;

  /// Concluida y cancelada son estados finales.
  bool get isFinal =>
      status == ApptStatus.concluida || status == ApptStatus.cancelada;
}

class Surgery {
  Surgery({
    required this.id,
    required this.doctorId,
    required this.start,
    required this.durationMin,
  });

  final String id;
  final String doctorId;
  final DateTime start;
  final int durationMin;

  DateTime get end => start.add(Duration(minutes: durationMin));
}

class Trip {
  const Trip({required this.distanceKm, required this.minutes});

  final double distanceKm;
  final int minutes;

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
  String get durationLabel => '$minutes min';
}

class HomeRequest {
  HomeRequest({
    required this.id,
    required this.clientId,
    required this.petId,
    required this.addr,
    required this.date,
    required this.timeMinutes,
    required this.notes,
    required this.reason,
    required this.qty,
    required this.returnHome,
    required this.companion,
    required this.trip,
    this.status = HomeStatus.porAsignar,
    this.driverId,
  });

  final String id;
  final String clientId;
  final String petId;
  String addr;
  DateTime date;
  int timeMinutes;
  String notes;
  String reason;
  int qty;
  bool returnHome;
  bool companion;
  final Trip trip; // estimación calculada una sola vez por solicitud
  HomeStatus status;
  String? driverId;

  static const String serviceType = 'Recolección a domicilio';
}
