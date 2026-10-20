// Utilidades de fechas y horas (sin dependencias externas).

const List<String> kMonthNames = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const List<String> kWeekdayShort = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
const List<String> kDayNames = [
  'domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado',
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// 0 = domingo ... 6 = sábado.
int dow0(DateTime d) => d.weekday % 7;

/// Regla de negocio: la clínica cierra los domingos.
bool isClinicClosed(DateTime d) => d.weekday == DateTime.sunday;

DateTime nextOpenDay(DateTime from) {
  DateTime d = dateOnly(from);
  while (isClinicClosed(d)) {
    d = addDays(d, 1);
  }
  return d;
}

String pad2(int n) => n.toString().padLeft(2, '0');

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// 570 -> "9:30 am"
String minutesLabel(int m) {
  final int h = m ~/ 60;
  final int mm = m % 60;
  final int h12 = (h % 12 == 0) ? 12 : h % 12;
  return '$h12:${pad2(mm)} ${h >= 12 ? 'pm' : 'am'}';
}

/// 9 -> "9:00 am"
String hourLabel(int h) => minutesLabel(h * 60);

int minutesOfDay(DateTime d) => d.hour * 60 + d.minute;

DateTime atMinutes(DateTime day, int minutes) =>
    DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

String timeLabel(DateTime d) => minutesLabel(minutesOfDay(d));

/// "Mié 17 sep"
String formatDateShort(DateTime d) =>
    '${kWeekdayShort[dow0(d)]} ${d.day} ${kMonthNames[d.month - 1].substring(0, 3)}';

/// "Miércoles 17 de septiembre"
String formatDateLong(DateTime d) =>
    '${capitalize(kDayNames[dow0(d)])} ${d.day} de ${kMonthNames[d.month - 1]}';

String money(int n) => '\$$n';

bool overlaps(DateTime a1, DateTime a2, DateTime b1, DateTime b2) =>
    a1.isBefore(b2) && b1.isBefore(a2);

/// Horarios de 30 min en los que la clínica agenda (8:00 am - 5:30 pm).
List<int> clinicSlotMinutes() {
  final List<int> out = <int>[];
  for (int m = 8 * 60; m < 18 * 60; m += 30) {
    out.add(m);
  }
  return out;
}

/// Horarios disponibles para solicitar un servicio a domicilio.
const List<int> kHomeServiceTimes = [
  540, 570, 600, 630, 660, 690, 720, 750, 780, 810, 840, 900, 930, 960, 990, 1020,
];
