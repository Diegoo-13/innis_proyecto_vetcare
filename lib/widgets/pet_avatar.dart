import 'package:flutter/material.dart';

import '../theme.dart';

/// Avatar de mascota dibujado con código (cara de perro, gato o huella genérica
/// para el resto de especies). Sustituye a las fotos mientras no haya almacenamiento de imágenes.
class PetAvatar extends StatelessWidget {
  const PetAvatar({super.key, required this.species, this.size = 42, this.square = false});

  final String species;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final bool dog = species.startsWith('Perro');
    final bool cat = species.startsWith('Gat');
    final int kind = dog ? 0 : (cat ? 1 : 2);
    final double ring = size * 1.22;
    final Color bg = dog ? C.cat1Soft : (cat ? C.cat2Soft : C.cat3Soft);
    final double radius = square ? ring * 0.28 : ring / 2;
    final double inner = square ? size * 0.28 : size / 2;
    return Container(
      width: ring,
      height: ring,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(inner),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _FacePainter(kind)),
          ),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.kind);

  final int kind; // 0 perro, 1 gato, 2 otra especie

  Paint _fill(int argb) => Paint()..color = Color(argb);

  Paint _stroke(int argb, double w) => Paint()
    ..color = Color(argb)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    if (kind == 1) {
      canvas.drawCircle(const Offset(32, 32), 32, _fill(0xFFF2E4CD));
      canvas.drawPath(Path()
        ..moveTo(15, 20)
        ..lineTo(8, 8)
        ..lineTo(22, 17)
        ..close(), _fill(0xFFEAD5B4));
      canvas.drawPath(Path()
        ..moveTo(49, 20)
        ..lineTo(56, 8)
        ..lineTo(42, 17)
        ..close(), _fill(0xFFEAD5B4));
      canvas.drawCircle(const Offset(32, 35), 20, _fill(0xFFF8ECD8));
      canvas.drawCircle(const Offset(25, 33), 2.6, _fill(0xFF3A2A20));
      canvas.drawCircle(const Offset(39, 33), 2.6, _fill(0xFF3A2A20));
      canvas.drawPath(Path()
        ..moveTo(29, 41)
        ..quadraticBezierTo(32, 44, 35, 41), _stroke(0xFF3A2A20, 1.8));
      final Paint whisk = _stroke(0xFFCBB48D, 1.4);
      canvas.drawLine(const Offset(17, 38), const Offset(6, 36), whisk);
      canvas.drawLine(const Offset(17, 41), const Offset(6, 43), whisk);
      canvas.drawLine(const Offset(47, 38), const Offset(58, 36), whisk);
      canvas.drawLine(const Offset(47, 41), const Offset(58, 43), whisk);
    } else if (kind == 0) {
      canvas.drawCircle(const Offset(32, 32), 32, _fill(0xFFF4C989));
      canvas.drawPath(Path()
        ..moveTo(12, 18)
        ..quadraticBezierTo(4, 30, 16, 40)
        ..quadraticBezierTo(12, 24, 24, 18)
        ..close(), _fill(0xFFE0A75E));
      canvas.drawPath(Path()
        ..moveTo(52, 18)
        ..quadraticBezierTo(60, 30, 48, 40)
        ..quadraticBezierTo(52, 24, 40, 18)
        ..close(), _fill(0xFFE0A75E));
      canvas.drawCircle(const Offset(32, 34), 19, _fill(0xFFFBDDA9));
      canvas.drawOval(Rect.fromCenter(center: const Offset(32, 43), width: 18, height: 14), _fill(0xFFFFF6E7));
      canvas.drawCircle(const Offset(32, 41), 2.6, _fill(0xFF2A1B10));
      canvas.drawCircle(const Offset(23, 30), 2.8, _fill(0xFF2A1B10));
      canvas.drawCircle(const Offset(41, 30), 2.8, _fill(0xFF2A1B10));
      canvas.drawPath(Path()
        ..moveTo(32, 45)
        ..quadraticBezierTo(32, 51, 39, 52), _stroke(0xFFC0392B, 3.4));
    } else {
      canvas.drawCircle(const Offset(32, 32), 32, _fill(0xFFE4E9FE));
      final Paint p = _fill(0xFF5B7CFA);
      canvas.drawOval(Rect.fromCenter(center: const Offset(32, 40), width: 22, height: 18), p);
      canvas.drawOval(Rect.fromCenter(center: const Offset(19, 29), width: 9.2, height: 12), p);
      canvas.drawOval(Rect.fromCenter(center: const Offset(45, 29), width: 9.2, height: 12), p);
      canvas.drawOval(Rect.fromCenter(center: const Offset(26, 18), width: 8.8, height: 11.6), p);
      canvas.drawOval(Rect.fromCenter(center: const Offset(38, 18), width: 8.8, height: 11.6), p);
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) => oldDelegate.kind != kind;
}
