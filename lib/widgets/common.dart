import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../utils/formatters.dart';

// ======================= HELPERS =======================

/// Intercala un espacio vertical entre los widgets.
List<Widget> spaced(List<Widget> children, double gap) {
  final List<Widget> out = <Widget>[];
  for (int i = 0; i < children.length; i++) {
    if (i > 0) out.add(SizedBox(height: gap));
    out.add(children[i]);
  }
  return out;
}

void toast(BuildContext context, String msg) {
  final ScaffoldMessengerState m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 2600)));
}

Future<T?> showAppSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (BuildContext ctx) => Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 18 + MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(child: child),
    ),
  );
}

PillKind apptPillKind(ApptStatus s) {
  if (s == ApptStatus.confirmada) return PillKind.good;
  if (s == ApptStatus.pendiente) return PillKind.warn;
  if (s == ApptStatus.concluida) return PillKind.info;
  return PillKind.bad;
}

// ======================= BLOQUES BÁSICOS =======================

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: r,
        border: Border.all(color: borderColor ?? C.line),
        boxShadow: const [BoxShadow(color: Color(0x1215213E), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: C.muted),
    );
  }
}

enum PillKind { good, warn, bad, info, neutral }

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.kind = PillKind.neutral});
  final String text;
  final PillKind kind;

  @override
  Widget build(BuildContext context) {
    Color bg = C.surface2;
    Color fg = C.inkSoft;
    if (kind == PillKind.good) {
      bg = C.goodSoft;
      fg = C.good;
    } else if (kind == PillKind.warn) {
      bg = C.warnSoft;
      fg = C.warn;
    } else if (kind == PillKind.bad) {
      bg = C.badSoft;
      fg = C.bad;
    } else if (kind == PillKind.info) {
      bg = C.primarySoft;
      fg = C.primaryDark;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

enum BtnKind { primary, accent, ghost, danger, success }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.kind = BtnKind.primary,
    this.small = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BtnKind kind;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    Color bg = C.primary;
    Color fg = Colors.white;
    BorderSide side = BorderSide.none;
    if (kind == BtnKind.accent) {
      bg = C.accent;
    } else if (kind == BtnKind.ghost) {
      bg = C.surface2;
      fg = C.ink;
      side = const BorderSide(color: C.line);
    } else if (kind == BtnKind.danger) {
      bg = C.badSoft;
      fg = C.bad;
    } else if (kind == BtnKind.success) {
      bg = C.goodSoft;
      fg = C.good;
    }
    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: kind == BtnKind.primary ? C.line : bg.withAlpha(140),
      disabledForegroundColor: kind == BtnKind.primary ? C.muted : fg.withAlpha(140),
      elevation: 0,
      shadowColor: Colors.transparent,
      side: side,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: small ? 10 : 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(small ? 11 : 14)),
      textStyle: TextStyle(fontSize: small ? 13 : 14.5, fontWeight: FontWeight.w700),
    );
    final Widget button = icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(label, textAlign: TextAlign.center))
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: small ? 16 : 18),
            label: Text(label, textAlign: TextAlign.center),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class IconBtn extends StatelessWidget {
  const IconBtn({super.key, required this.icon, required this.onTap, this.color, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget w = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.line),
          ),
          child: Icon(icon, size: 18, color: color ?? C.ink),
        ),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

class AppBanner extends StatelessWidget {
  const AppBanner({super.key, required this.text, this.bold, this.warn = false, this.icon = Icons.shield_outlined});
  final String text;
  final String? bold;
  final bool warn;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn ? C.badSoft : C.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: warn ? C.bad : C.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (bold != null)
                    TextSpan(text: '$bold ', style: const TextStyle(fontWeight: FontWeight.w700, color: C.ink)),
                  TextSpan(text: text),
                ],
              ),
              style: const TextStyle(fontSize: 12.5, height: 1.45, color: C.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= FORMULARIOS =======================

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.onChanged,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: C.line),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.inkSoft)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: C.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: C.muted, fontSize: 14),
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18, color: C.muted),
            filled: true,
            fillColor: C.surface2,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: C.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.inkSoft)),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: C.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(fontSize: 14, color: C.ink),
              items: items
                  .map((T e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(labelOf(e), overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class AppSegmented extends StatelessWidget {
  const AppSegmented({super.key, required this.options, required this.index, required this.onChanged});
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? C.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      options[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == index ? Colors.white : C.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opción seleccionable (mascota, servicio, médico, horario).
class ChipSelect extends StatelessWidget {
  const ChipSelect({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.sub,
    this.subColor,
    this.selected = false,
    this.conflict = false,
    this.disabled = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final String? sub;
  final Color? subColor;
  final bool selected;
  final bool conflict;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color border = C.line;
    Color bg = Colors.white;
    Color fg = C.inkSoft;
    if (selected) {
      border = C.primary;
      bg = C.primarySoft;
      fg = C.primaryDark;
    } else if (conflict) {
      border = C.bad;
      bg = C.badSoft;
      fg = C.bad;
    }
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: disabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) leading!,
                if (leading == null && icon != null) Icon(icon, size: 20, color: selected ? C.primaryDark : C.primary),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: subColor ?? C.muted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================= ESTRUCTURA DE PANTALLAS =======================

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.tag, this.size = 19});
  final String? tag;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Vet', style: TextStyle(color: C.primary, fontSize: size, fontWeight: FontWeight.w800)),
            TextSpan(text: 'Care', style: TextStyle(color: C.brand1, fontSize: size, fontWeight: FontWeight.w800)),
          ]),
        ),
        if (tag != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: C.primarySoft, borderRadius: BorderRadius.circular(999)),
            child: Text(
              tag!.toUpperCase(),
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: C.primaryDark, letterSpacing: 0.4),
            ),
          ),
        ],
      ],
    );
  }
}

/// Encabezado de las pestañas principales.
class RootBar extends StatelessWidget {
  const RootBar({super.key, this.title, this.tag, this.trailing});
  final String? title;
  final String? tag;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Expanded(
            child: title != null
                ? Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.brand1))
                : Align(alignment: Alignment.centerLeft, child: Wordmark(tag: tag)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Pestaña principal: encabezado fijo + contenido con scroll.
class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.header, required this.children});
  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          header,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              children: spaced(children, 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pantalla de detalle con barra superior, contenido y botón inferior opcional.
class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.bottom,
    this.showBack = true,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? bottom;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 58,
        leading: showBack
            ? Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: IconBtn(
                  icon: Icons.arrow_back_ios_new,
                  onTap: onBack ?? () => Navigator.of(context).pop(),
                ),
              )
            : null,
        titleSpacing: showBack ? 4 : 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.ink)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: C.muted)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: spaced(children, 14),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: C.line)),
                ),
                child: bottom,
              ),
            ),
    );
  }
}

/// Contenido estándar de una hoja inferior: título, texto y acciones.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.title, this.subtitle, required this.children});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.ink)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 13, height: 1.45, color: C.inkSoft)),
        ],
        const SizedBox(height: 14),
        ...spaced(children, 10),
      ],
    );
  }
}

// ======================= TARJETAS DE DATOS =======================

class InfoItem {
  const InfoItem(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
}

class InfoList extends StatelessWidget {
  const InfoList(this.items, {super.key});
  final List<InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) rows.add(const Divider(height: 20, thickness: 1, color: C.line));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(items[i].label, style: const TextStyle(fontSize: 13, color: C.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              items[i].value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: items[i].valueColor ?? C.ink),
            ),
          ),
        ],
      ));
    }
    return Column(children: rows);
  }
}

/// Tarjeta azul marino destacada (próxima cita).
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: C.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x8C0A1240), blurRadius: 24, offset: Offset(0, 12), spreadRadius: -12)],
      ),
      child: child,
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials, {super.key, this.size = 42});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: C.primarySoft, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(fontSize: size * 0.33, fontWeight: FontWeight.w800, color: C.primaryDark),
      ),
    );
  }
}

// ======================= CALENDARIO MENSUAL =======================

/// Calendario mensual real: domingos cerrados (regla de negocio) y días pasados bloqueados.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({super.key, required this.selected, required this.onPick});
  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final DateTime base = widget.selected ?? DateTime.now();
    _year = base.year;
    _month = base.month;
  }

  @override
  void didUpdateWidget(covariant MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final DateTime? s = widget.selected;
    if (s != null && (oldWidget.selected == null || !sameDay(s, oldWidget.selected!))) {
      _year = s.year;
      _month = s.month;
    }
  }

  void _shift(int delta) {
    setState(() {
      _month += delta;
      if (_month < 1) {
        _month = 12;
        _year--;
      } else if (_month > 12) {
        _month = 1;
        _year++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = dateOnly(DateTime.now());
    final bool isCurrent = _year == today.year && _month == today.month;
    final int firstDow = (DateTime(_year, _month, 1).weekday + 6) % 7; // 0 = lunes
    final int daysInMonth = DateTime(_year, _month + 1, 0).day;

    final List<Widget> cells = <Widget>[];
    for (int i = 0; i < firstDow; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final DateTime day = DateTime(_year, _month, d);
      final bool disabled = day.isBefore(today) || isClinicClosed(day);
      final bool isToday = sameDay(day, today);
      final bool isSel = widget.selected != null && sameDay(day, widget.selected!);
      cells.add(GestureDetector(
        onTap: disabled ? null : () => widget.onPick(day),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? C.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: (isToday && !isSel) ? C.primary : Colors.transparent, width: 1.5),
          ),
          child: Text(
            '$d',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSel ? Colors.white : (disabled ? C.line : (isToday ? C.primaryDark : C.ink)),
            ),
          ),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavBtn(icon: Icons.chevron_left, enabled: !isCurrent, onTap: () => _shift(-1)),
              Text(
                capitalize('${kMonthNames[_month - 1]} $_year'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.ink),
              ),
              _NavBtn(icon: Icons.chevron_right, enabled: true, onTap: () => _shift(1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final String w in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                Expanded(
                  child: Center(
                    child: Text(w, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: C.muted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.circle, size: 7, color: C.primary),
              SizedBox(width: 6),
              Text('Hoy y días disponibles · domingos cerrado', style: TextStyle(fontSize: 11, color: C.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.line)),
        child: Icon(icon, size: 18, color: enabled ? C.inkSoft : C.line),
      ),
    );
  }
}
