import 'dart:math';

import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

/// Consultorios de la clínica (ahora son 4).
const List<String> kRooms = [
  'Consultorio 1', 'Consultorio 2', 'Consultorio 3', 'Consultorio 4',
];

class SlotSuggestion {
  SlotSuggestion(this.doctor, this.date, this.minutes);
  final Doctor doctor;
  final DateTime date;
  final int minutes;
}

class ManualApptResult {
  ManualApptResult({this.error, this.conflict = false, this.newPatient = false, this.pet});
  final String? error;
  final bool conflict;
  final bool newPatient;
  final Pet? pet;
}

/// Capa de lógica de negocio (hace de "fachada" para la presentación).
/// Todas las pantallas leen y modifican datos solo a través de esta clase.
class AppState extends ChangeNotifier {
  AppState({Repository? repository})
      : repo = repository ?? Repository.seed(DateTime.now()) {
    currentClientId = repo.clients.first.id;
    currentDriverId = repo.drivers.first.id;
  }

  final Repository repo;
  final Random _rng = Random();

  Role? role;
  late String currentClientId;
  late String currentDriverId;
  String? currentHomeReqId; // solicitud a domicilio que el cliente está siguiendo
  bool clientNotifUnread = true;

  DateTime get today => dateOnly(DateTime.now());
  DateTime get firstOpenDate => nextOpenDay(today);
  DateTime get reminderDay => nextOpenDay(addDays(today, 1));

  // ======================= AUTENTICACIÓN =======================

  /// Devuelve un mensaje de error o null si el acceso fue correcto.
  String? login(Role r, String email, String pass) {
    if (email.trim().isEmpty || pass.trim().isEmpty) {
      return 'Completa tu correo y contraseña';
    }
    if (r == Role.cliente) {
      final String e = email.trim().toLowerCase();
      final matches = repo.clients.where((c) => c.email.toLowerCase() == e).toList();
      currentClientId = matches.isNotEmpty ? matches.first.id : repo.clients.first.id;
    }
    role = r;
    currentHomeReqId = null;
    clientNotifUnread = true;
    notifyListeners();
    return null;
  }

  String? register(String name, String email, String phone, String pass, String pass2) {
    if (name.trim().isEmpty || email.trim().isEmpty || phone.trim().isEmpty || pass.isEmpty || pass2.isEmpty) {
      return 'Completa todos los campos para crear tu cuenta';
    }
    if (!email.contains('@') || !email.contains('.')) return 'Escribe un correo válido';
    if (pass.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    if (pass != pass2) return 'Las contraseñas no coinciden';
    final String e = email.trim().toLowerCase();
    if (repo.clients.any((c) => c.email.toLowerCase() == e)) {
      return 'Ya existe una cuenta con ese correo';
    }
    final Client c = Client(id: repo.newId('cli'), name: name.trim(), email: email.trim(), phone: phone.trim());
    repo.clients.add(c);
    currentClientId = c.id;
    role = Role.cliente; // el registro solo aplica al rol Cliente
    currentHomeReqId = null;
    clientNotifUnread = false;
    notifyListeners();
    return null;
  }

  void logout() {
    role = null;
    currentHomeReqId = null;
    notifyListeners();
  }

  // ======================= BÚSQUEDAS =======================

  Client get currentClient => repo.clients.firstWhere((c) => c.id == currentClientId);
  Driver get currentDriver => repo.drivers.firstWhere((d) => d.id == currentDriverId);

  Pet? petById(String id) {
    for (final Pet p in repo.pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  Doctor? doctorById(String id) {
    for (final Doctor d in repo.doctors) {
      if (d.id == id) return d;
    }
    return null;
  }

  Service? serviceById(String id) {
    for (final Service s in repo.services) {
      if (s.id == id) return s;
    }
    return null;
  }

  Driver? driverById(String? id) {
    if (id == null) return null;
    for (final Driver d in repo.drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  Appointment? appointmentById(String id) {
    for (final Appointment a in repo.appointments) {
      if (a.id == id) return a;
    }
    return null;
  }

  HomeRequest? homeRequestById(String? id) {
    if (id == null) return null;
    for (final HomeRequest r in repo.homeRequests) {
      if (r.id == id) return r;
    }
    return null;
  }

  String petName(String id) => petById(id)?.name ?? 'Mascota';
  String doctorName(String id) => doctorById(id)?.name ?? 'Médico eliminado';
  String serviceLabel(String id) => serviceById(id)?.label ?? 'Servicio eliminado';
  String driverName(String? id) => driverById(id)?.name ?? 'Sin asignar';
  String vehicleOf(String? id) => driverById(id)?.vehicle ?? '—';

  List<Doctor> get doctors => repo.doctors;
  List<Service> get services => repo.services;
  List<Driver> get drivers => repo.drivers;
  ClinicInfo get clinic => repo.clinic;

  // ======================= CLIENTE: MASCOTAS =======================

  List<Pet> get clientPets => repo.pets.where((p) => p.ownerId == currentClientId).toList();

  /// Valida y registra una mascota; devuelve un error o null.
  String? addPet({
    required String name,
    required String species,
    required PetCategory category,
    required String breed,
    required String color,
    required String age,
    required String owner,
    required String phone,
  }) {
    if (name.trim().isEmpty) return 'Ponle un nombre a tu mascota';
    final String ageText = age.trim();
    final String ageLabel = ageText.isEmpty
        ? 'Edad no especificada'
        : (RegExp(r'^\d+$').hasMatch(ageText) ? (ageText == '1' ? '1 año' : '$ageText años') : ageText);
    repo.pets.add(Pet(
      id: repo.newId('pet'),
      code: repo.nextPetCode(),
      name: name.trim(),
      species: species,
      category: category,
      breed: breed.trim().isEmpty ? 'Raza no especificada' : breed.trim(),
      color: color.trim().isEmpty ? 'Color no especificado' : color.trim(),
      age: ageLabel,
      ownerId: currentClientId,
      ownerName: owner.trim().isEmpty ? currentClient.name : owner.trim(),
      phone: phone.trim().isEmpty ? currentClient.phone : phone.trim(),
    ));
    notifyListeners();
    return null;
  }

  List<Appointment> appointmentsOfPet(String petId) {
    final list = repo.appointments.where((a) => a.petId == petId).toList();
    list.sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  // ======================= DISPONIBILIDAD Y ANTI-EMPALMES =======================

  /// Consultorio de la cita: depende del servicio y, si no tiene uno fijo, del médico.
  String roomFor(Service service, Doctor doctor) {
    if (service.room != null) return service.room!;
    final String? fixed = repo.defaultRooms[doctor.id];
    if (fixed != null) return fixed;
    final int i = repo.doctors.indexOf(doctor);
    return kRooms[(i < 0 ? 0 : i) % kRooms.length];
  }

  /// Revisa solo la jornada del médico (descanso, horario por hora, cirugías).
  SlotState scheduleState(Doctor d, DateTime date, int minutes, int durationMin) {
    if (d.rest != null && dow0(date) == d.rest) return SlotState.rest;
    if (minutes < d.startH * 60 || minutes + durationMin > d.endH * 60) return SlotState.outOfHours;
    final DateTime start = atMinutes(date, minutes);
    final DateTime end = start.add(Duration(minutes: durationMin));
    for (final Surgery s in repo.surgeries) {
      if (s.doctorId == d.id && overlaps(start, end, s.start, s.end)) return SlotState.surgery;
    }
    return SlotState.ok;
  }

  /// Estado completo de un horario: jornada, cirugías, horas pasadas, y empalmes
  /// con otra cita del médico o del consultorio.
  SlotState slotState({
    required Doctor doctor,
    required DateTime date,
    required int minutes,
    required int durationMin,
    required String room,
    String? ignoreApptId,
  }) {
    final SlotState sched = scheduleState(doctor, date, minutes, durationMin);
    if (sched != SlotState.ok) return sched;
    final DateTime start = atMinutes(date, minutes);
    if (!start.isAfter(DateTime.now())) return SlotState.past;
    final DateTime end = start.add(Duration(minutes: durationMin));
    for (final Appointment a in repo.appointments) {
      if (a.id == ignoreApptId || !a.isActive) continue;
      if (!overlaps(start, end, a.start, a.end)) continue;
      if (a.doctorId == doctor.id || a.room == room) return SlotState.busy;
    }
    return SlotState.ok;
  }

  /// Busca el primer horario libre (el más temprano) entre todos los médicos.
  SlotSuggestion? autoAssign({required Service service, DateTime? from, String? ignoreApptId}) {
    DateTime day = dateOnly(from ?? firstOpenDate);
    for (int i = 0; i < 21; i++) {
      if (!isClinicClosed(day) && !day.isBefore(today)) {
        for (final int m in clinicSlotMinutes()) {
          for (final Doctor d in repo.doctors) {
            final SlotState st = slotState(
              doctor: d,
              date: day,
              minutes: m,
              durationMin: service.effectiveMinutes,
              room: roomFor(service, d),
              ignoreApptId: ignoreApptId,
            );
            if (st == SlotState.ok) return SlotSuggestion(d, day, m);
          }
        }
      }
      day = addDays(day, 1);
    }
    return null;
  }

  /// Dos citas activas chocan si se traslapan y comparten médico o consultorio.
  List<String> conflictReasons(Appointment a) {
    final List<String> out = <String>[];
    if (!a.isActive) return out;
    bool doctorClash = false;
    bool roomClash = false;
    for (final Appointment o in repo.appointments) {
      if (o.id == a.id || !o.isActive) continue;
      if (!overlaps(a.start, a.end, o.start, o.end)) continue;
      if (o.doctorId == a.doctorId) doctorClash = true;
      if (o.room == a.room) roomClash = true;
    }
    if (doctorClash) out.add('${doctorName(a.doctorId)} ya tiene otra cita en ese horario.');
    if (roomClash) out.add('${a.room} ya tiene otra cita en ese horario.');
    return out;
  }

  bool hasConflict(Appointment a) => conflictReasons(a).isNotEmpty;

  // ======================= CLIENTE: CITAS =======================

  List<Appointment> clientAppointments({required bool upcoming}) {
    final ids = clientPets.map((p) => p.id).toSet();
    final DateTime now = DateTime.now();
    final list = repo.appointments
        .where((a) => ids.contains(a.petId))
        .where((a) => upcoming == (a.isActive && a.end.isAfter(now)))
        .toList();
    list.sort((a, b) => upcoming ? a.start.compareTo(b.start) : b.start.compareTo(a.start));
    return list;
  }

  Appointment? get nextClientAppointment {
    final l = clientAppointments(upcoming: true);
    return l.isEmpty ? null : l.first;
  }

  /// Agenda una cita nueva, o reprograma una existente si se pasa [rescheduleId].
  String? bookAppointment({
    required String petId,
    required Service service,
    required Doctor doctor,
    required DateTime date,
    required int minutes,
    String? rescheduleId,
  }) {
    final String room = roomFor(service, doctor);
    final SlotState st = slotState(
      doctor: doctor,
      date: date,
      minutes: minutes,
      durationMin: service.effectiveMinutes,
      room: room,
      ignoreApptId: rescheduleId,
    );
    if (st != SlotState.ok) return 'Ese horario ya no está disponible. Elige otro.';
    final DateTime start = atMinutes(date, minutes);
    if (rescheduleId != null) {
      final Appointment? a = appointmentById(rescheduleId);
      if (a == null) return 'No se encontró la cita a reprogramar';
      a.doctorId = doctor.id;
      a.room = room;
      a.start = start;
      a.durationMin = service.effectiveMinutes;
      a.status = ApptStatus.confirmada;
      a.reminderSent = false;
    } else {
      repo.appointments.add(Appointment(
        id: repo.newId('a'),
        petId: petId,
        serviceId: service.id,
        doctorId: doctor.id,
        room: room,
        start: start,
        durationMin: service.effectiveMinutes,
      ));
    }
    notifyListeners();
    return null;
  }

  void cancelAppointment(String id) {
    final Appointment? a = appointmentById(id);
    if (a == null || a.isFinal) return;
    a.status = ApptStatus.cancelada;
    a.checkedIn = false;
    notifyListeners();
  }

  void setApptReminder(String id, bool on) {
    final Appointment? a = appointmentById(id);
    if (a == null) return;
    a.reminderOn = on;
    notifyListeners();
  }

  void setClientReminder({bool? dayBefore, bool? morning}) {
    if (dayBefore != null) currentClient.remindDayBefore = dayBefore;
    if (morning != null) currentClient.remindMorning = morning;
    notifyListeners();
  }

  /// Avisos que ve el cliente en la campana.
  List<String> clientNotifications() {
    final List<String> out = <String>[];
    final DateTime limit = DateTime.now().add(const Duration(hours: 48));
    for (final Appointment a in clientAppointments(upcoming: true)) {
      if (a.start.isBefore(limit)) {
        out.add('Cita ${sameDay(a.start, today) ? 'hoy' : 'próxima'} ${formatDateShort(a.start)} · ${timeLabel(a.start)}\n'
            '${serviceLabel(a.serviceId)} · ${petName(a.petId)} · ${doctorName(a.doctorId)}');
      }
    }
    for (final HomeRequest r in repo.homeRequests) {
      if (r.clientId == currentClientId && r.status != HomeStatus.concluido) {
        out.add('Servicio a domicilio: ${r.status.label}\n${petName(r.petId)} · ${formatDateShort(r.date)} · ${minutesLabel(r.timeMinutes)}');
      }
    }
    return out;
  }

  void markNotificationsRead() {
    if (!clientNotifUnread) return;
    clientNotifUnread = false;
    notifyListeners();
  }

  // ======================= RECEPCIÓN: AGENDA =======================

  List<Appointment> agendaFor(DateTime day, {String? room, String query = ''}) {
    final String q = query.trim().toLowerCase();
    final list = repo.appointments.where((a) {
      if (!sameDay(a.start, day)) return false;
      if (room != null && a.room != room) return false;
      if (q.isEmpty) return true;
      final Pet? p = petById(a.petId);
      final List<String> hay = <String>[
        p?.name ?? '', p?.code ?? '', p?.phone ?? '', p?.breed ?? '', p?.ownerName ?? '', doctorName(a.doctorId),
      ];
      return hay.any((v) => v.toLowerCase().contains(q));
    }).toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  int conflictCountOn(DateTime day) =>
      repo.appointments.where((a) => sameDay(a.start, day) && hasConflict(a)).length;

  /// Cambia el consultorio. Se bloquea si ya está ocupado a esa hora.
  String? reassignRoom(String apptId, String room) {
    final Appointment? a = appointmentById(apptId);
    if (a == null || a.isFinal) return 'Esta cita ya no se puede modificar';
    for (final Appointment o in repo.appointments) {
      if (o.id == a.id || !o.isActive) continue;
      if (o.room == room && overlaps(a.start, a.end, o.start, o.end)) {
        return '$room ya está ocupado a esa hora. Elige otro consultorio.';
      }
    }
    a.room = room;
    notifyListeners();
    return null;
  }

  /// Cambia el médico. Se bloquea si descansa, está fuera de horario, en cirugía u ocupado.
  String? reassignDoctor(String apptId, String doctorId) {
    final Appointment? a = appointmentById(apptId);
    final Doctor? d = doctorById(doctorId);
    if (a == null || d == null || a.isFinal) return 'Esta cita ya no se puede modificar';
    final SlotState st = scheduleState(d, dateOnly(a.start), minutesOfDay(a.start), a.durationMin);
    if (st == SlotState.rest) return '${d.name} descansa ese día.';
    if (st == SlotState.outOfHours) return '${d.name} atiende de ${d.hours}.';
    if (st == SlotState.surgery) return '${d.name} está en cirugía a esa hora.';
    for (final Appointment o in repo.appointments) {
      if (o.id == a.id || !o.isActive) continue;
      if (o.doctorId == d.id && overlaps(a.start, a.end, o.start, o.end)) {
        return '${d.name} ya tiene otra cita a esa hora.';
      }
    }
    a.doctorId = d.id;
    notifyListeners();
    return null;
  }

  void toggleCheckin(String apptId) {
    final Appointment? a = appointmentById(apptId);
    if (a == null || a.isFinal) return;
    a.checkedIn = !a.checkedIn;
    notifyListeners();
  }

  void concludeAppointment(String apptId) {
    final Appointment? a = appointmentById(apptId);
    if (a == null || a.isFinal) return;
    a.status = ApptStatus.concluida;
    notifyListeners();
  }

  /// Registra una cita tomada por teléfono o en mostrador. No bloquea por empalme:
  /// la deja marcada como "Conflicto" para que recepción la resuelva.
  ManualApptResult addManualAppointment({
    required DateTime day,
    required int minutes,
    required String serviceId,
    required String doctorId,
    required String room,
    String? existingPetId,
    String? newName,
    String? newSpecies,
    String? newBreed,
    String? newOwner,
    String? newPhone,
  }) {
    final Service? svc = serviceById(serviceId);
    final Doctor? doc = doctorById(doctorId);
    if (svc == null || doc == null) return ManualApptResult(error: 'Elige servicio y médico');

    Pet? pet;
    bool isNew = false;
    if (existingPetId == null) {
      if ((newName ?? '').trim().isEmpty || (newOwner ?? '').trim().isEmpty || (newPhone ?? '').trim().isEmpty) {
        return ManualApptResult(error: 'Completa mascota, dueño y teléfono del paciente nuevo');
      }
    } else {
      pet = petById(existingPetId);
      if (pet == null) return ManualApptResult(error: 'Elige un paciente');
    }

    final SlotState st = scheduleState(doc, day, minutes, svc.effectiveMinutes);
    if (st == SlotState.rest) return ManualApptResult(error: '${doc.name} descansa ese día');
    if (st == SlotState.outOfHours) return ManualApptResult(error: '${doc.name} atiende de ${doc.hours}: elige otra hora o médico');
    if (st == SlotState.surgery) return ManualApptResult(error: '${doc.name} está en cirugía a esa hora');

    if (existingPetId == null) {
      final String species = newSpecies ?? 'Perro';
      pet = Pet(
        id: repo.newId('pet'),
        code: repo.nextPetCode(),
        name: newName!.trim(),
        species: species,
        category: categoryForSpecies(species),
        breed: (newBreed ?? '').trim().isEmpty ? 'Sin raza registrada' : newBreed!.trim(),
        color: 'Sin registrar',
        age: 'Edad no especificada',
        ownerId: 'walkin-${repo.pets.length}',
        ownerName: newOwner!.trim(),
        phone: newPhone!.trim(),
      );
      repo.pets.add(pet);
      isNew = true;
    }

    final Appointment appt = Appointment(
      id: repo.newId('r'),
      petId: pet!.id,
      serviceId: svc.id,
      doctorId: doc.id,
      room: room,
      start: atMinutes(day, minutes),
      durationMin: svc.effectiveMinutes,
      isNewPatient: isNew,
    );
    repo.appointments.add(appt);
    final bool conflict = hasConflict(appt);
    notifyListeners();
    return ManualApptResult(conflict: conflict, newPatient: isNew, pet: pet);
  }

  // ======================= RECEPCIÓN: CIRUGÍAS =======================

  List<Surgery> surgeriesOn(DateTime day) =>
      repo.surgeries.where((s) => sameDay(s.start, day)).toList();

  List<Appointment> surgeryAffected(String doctorId, DateTime day, int startMin, int durationMin) {
    final DateTime a = atMinutes(day, startMin);
    final DateTime b = a.add(Duration(minutes: durationMin));
    return repo.appointments
        .where((x) => x.doctorId == doctorId && x.isActive && overlaps(a, b, x.start, x.end))
        .toList();
  }

  /// Bloquea al médico durante la cirugía y cancela las citas que se encimen.
  int registerSurgery(String doctorId, DateTime day, int startMin, int durationMin) {
    final List<Appointment> hit = surgeryAffected(doctorId, day, startMin, durationMin);
    for (final Appointment a in hit) {
      a.status = ApptStatus.cancelada;
      a.checkedIn = false;
    }
    repo.surgeries.add(Surgery(
      id: repo.newId('sg'),
      doctorId: doctorId,
      start: atMinutes(day, startMin),
      durationMin: durationMin,
    ));
    notifyListeners();
    return hit.length;
  }

  void removeSurgery(String id) {
    repo.surgeries.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ======================= RECEPCIÓN: RECORDATORIOS =======================

  List<Appointment> remindersFor(DateTime day) {
    final list = repo.appointments.where((a) => sameDay(a.start, day) && a.isActive && a.reminderOn).toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  /// Marca como enviados los recordatorios por WhatsApp. Devuelve cuántos se enviaron.
  int sendReminders(DateTime day) {
    int n = 0;
    for (final Appointment a in remindersFor(day)) {
      if (!a.reminderSent) {
        a.reminderSent = true;
        n++;
      }
    }
    notifyListeners();
    return n;
  }

  // ======================= SERVICIO A DOMICILIO =======================

  HomeRequest? get currentHomeRequest => homeRequestById(currentHomeReqId);

  /// La distancia y duración son una estimación simulada (no hay mapa real en el prototipo).
  Trip estimateTrip() {
    final double distance = 1.5 + _rng.nextDouble() * 7.5;
    final int duration = (6 + distance * 2.2).round();
    return Trip(distanceKm: double.parse(distance.toStringAsFixed(1)), minutes: duration);
  }

  String? requestHomeService({
    required String petId,
    required String addr,
    required DateTime? date,
    required int? timeMinutes,
    required String notes,
    required String reason,
    required int qty,
    required bool returnHome,
    required bool companion,
  }) {
    if (petById(petId) == null) return 'Elige una mascota';
    if (addr.trim().isEmpty) return 'Escribe una dirección para el servicio';
    if (date == null) return 'Elige una fecha para el servicio';
    if (timeMinutes == null) return 'Elige una hora para el servicio';
    if (!atMinutes(date, timeMinutes).isAfter(DateTime.now())) return 'Elige una fecha y hora que no hayan pasado';
    final HomeRequest r = HomeRequest(
      id: repo.newId('h'),
      clientId: currentClientId,
      petId: petId,
      addr: addr.trim(),
      date: dateOnly(date),
      timeMinutes: timeMinutes,
      notes: notes.trim(),
      reason: reason,
      qty: qty,
      returnHome: returnHome,
      companion: companion,
      trip: estimateTrip(),
    );
    repo.homeRequests.add(r);
    currentHomeReqId = r.id;
    notifyListeners();
    return null;
  }

  void finishHomeTracking() {
    currentHomeReqId = null;
    notifyListeners();
  }

  int driverActiveCount(String driverId) => repo.homeRequests
      .where((r) => r.driverId == driverId && r.status != HomeStatus.concluido)
      .length;

  String driverAvailability(String driverId) {
    final int n = driverActiveCount(driverId);
    if (n == 0) return 'disponible ahora';
    return '$n ${n == 1 ? 'ruta' : 'rutas'} en curso';
  }

  String? assignDriver(String reqId, String driverId) {
    final HomeRequest? r = homeRequestById(reqId);
    final Driver? d = driverById(driverId);
    if (r == null || d == null) return 'Elige un chofer';
    r.driverId = d.id;
    r.status = HomeStatus.asignado;
    notifyListeners();
    return null;
  }

  List<HomeRequest> get driverRoutes =>
      repo.homeRequests.where((r) => r.driverId == currentDriverId).toList();

  /// Texto del botón principal del chofer según el estado.
  String driverActionLabel(HomeStatus s) {
    if (s == HomeStatus.asignado) return 'Salir hacia el domicilio';
    if (s == HomeStatus.enCamino) return 'Llegué al domicilio';
    if (s == HomeStatus.enServicio) return 'Concluir y regresar a la clínica';
    return 'Servicio concluido';
  }

  /// Pendiente -> En camino -> En servicio -> Concluido. El mismo estado lo ven
  /// recepción y el cliente porque todos leen la misma solicitud.
  void advanceHomeStatus(String reqId) {
    final HomeRequest? r = homeRequestById(reqId);
    if (r == null) return;
    if (r.status == HomeStatus.asignado) {
      r.status = HomeStatus.enCamino;
    } else if (r.status == HomeStatus.enCamino) {
      r.status = HomeStatus.enServicio;
    } else if (r.status == HomeStatus.enServicio) {
      r.status = HomeStatus.concluido;
    } else {
      return;
    }
    notifyListeners();
  }

  // ======================= ADMINISTRADOR =======================

  String? saveDoctor({
    String? id,
    required String name,
    required String especialidad,
    required String cedula,
    required int startH,
    required int endH,
    required int? rest,
    required bool guardia,
  }) {
    if (name.trim().isEmpty || especialidad.trim().isEmpty || cedula.trim().isEmpty) {
      return 'Completa nombre, especialidad y cédula profesional';
    }
    if (endH <= startH) return 'La hora de salida debe ser posterior a la de entrada';
    if (id != null) {
      final Doctor? d = doctorById(id);
      if (d == null) return 'Médico no encontrado';
      d.name = name.trim();
      d.especialidad = especialidad.trim();
      d.cedula = cedula.trim();
      d.startH = startH;
      d.endH = endH;
      d.rest = rest;
      d.guardia = guardia;
    } else {
      repo.doctors.add(Doctor(
        id: repo.newId('doc'),
        name: name.trim(),
        especialidad: especialidad.trim(),
        cedula: cedula.trim(),
        startH: startH,
        endH: endH,
        rest: rest,
        guardia: guardia,
      ));
    }
    notifyListeners();
    return null;
  }

  String? deleteDoctor(String id) {
    if (repo.doctors.length <= 1) return 'Debe existir al menos un médico';
    if (repo.appointments.any((a) => a.doctorId == id && a.isActive && a.end.isAfter(DateTime.now()))) {
      return 'Tiene citas pendientes: reasígnalas desde Recepción antes de eliminarlo';
    }
    repo.doctors.removeWhere((d) => d.id == id);
    repo.surgeries.removeWhere((s) => s.doctorId == id);
    notifyListeners();
    return null;
  }

  String? saveDriver({String? id, required String name, required String vehicle}) {
    if (name.trim().isEmpty || vehicle.trim().isEmpty) return 'Completa nombre y vehículo del chofer';
    if (id != null) {
      final Driver? d = driverById(id);
      if (d == null) return 'Chofer no encontrado';
      d.name = name.trim();
      d.vehicle = vehicle.trim();
    } else {
      repo.drivers.add(Driver(id: repo.newId('drv'), name: name.trim(), vehicle: vehicle.trim()));
    }
    notifyListeners();
    return null;
  }

  String? deleteDriver(String id) {
    if (repo.drivers.length <= 1) return 'Debe existir al menos un chofer';
    if (driverActiveCount(id) > 0) return 'Tiene rutas en curso: concluye o reasigna sus servicios primero';
    repo.drivers.removeWhere((d) => d.id == id);
    if (currentDriverId == id) currentDriverId = repo.drivers.first.id;
    notifyListeners();
    return null;
  }

  String? saveService({String? id, required String label, required int minutes, required int price, String? room}) {
    if (label.trim().isEmpty) return 'Ponle un nombre al servicio';
    if (minutes < 0 || price < 0) return 'Duración y costo no pueden ser negativos';
    if (id != null) {
      final Service? s = serviceById(id);
      if (s == null) return 'Servicio no encontrado';
      s.label = label.trim();
      s.minutes = minutes;
      s.price = price;
      s.room = room;
    } else {
      repo.services.add(Service(
        id: repo.newId('svc'),
        label: label.trim(),
        icon: Icons.auto_awesome_outlined,
        minutes: minutes,
        price: price,
        room: room,
      ));
    }
    notifyListeners();
    return null;
  }

  String? deleteService(String id) {
    if (repo.services.length <= 1) return 'Debe existir al menos un servicio';
    if (repo.appointments.any((a) => a.serviceId == id && a.isActive)) {
      return 'Hay citas activas con este servicio';
    }
    repo.services.removeWhere((s) => s.id == id);
    notifyListeners();
    return null;
  }

  /// Aumento anual: un solo porcentaje aplicado a todos los servicios con costo fijo.
  String? applyPriceIncrease(double pct) {
    if (pct.isNaN || pct <= 0 || pct > 100) return 'Escribe un porcentaje entre 1 y 100';
    for (final Service s in repo.services) {
      if (s.price > 0) s.price = (s.price * (1 + pct / 100)).round();
    }
    notifyListeners();
    return null;
  }

  String? updateClinic({required String phone, required String whatsapp, required String email}) {
    if (phone.trim().isEmpty || whatsapp.trim().isEmpty || email.trim().isEmpty) {
      return 'Completa teléfono, WhatsApp y correo';
    }
    repo.clinic = ClinicInfo(phone: phone.trim(), whatsapp: whatsapp.trim(), email: email.trim());
    notifyListeners();
    return null;
  }
}
