import 'dart:math' as math;
import 'package:flutter/material.dart';

class SosAutoLogo extends StatelessWidget {
  final double size;
  final bool showTextInside;

  const SosAutoLogo({
    super.key,
    this.size = 56,
    this.showTextInside = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SosAutoLogoPainter(showTextInside: showTextInside),
      ),
    );
  }
}

class _SosAutoLogoPainter extends CustomPainter {
  final bool showTextInside;

  _SosAutoLogoPainter({required this.showTextInside});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Fondo redondeado azul marino oscuro (#0B1E38)
    final RRect bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.22),
    );
    final Paint bgPaint = Paint()..color = const Color(0xFF0B1E38);
    canvas.drawRRect(bgRect, bgPaint);

    final double cx = w * 0.5;
    final double domeBottom = h * (showTextInside ? 0.56 : 0.68);
    final double domeTop = h * (showTextInside ? 0.25 : 0.28);
    final double domeHalfW = w * 0.185;

    // 2. Destellos radiales (7 rayos: 3 rojos izquierda, 1 rojo centro, 3 azules derecha)
    final List<double> angles = [
      -math.pi, // izquierda horizontal
      -math.pi * 0.80,
      -math.pi * 0.63,
      -math.pi * 0.50, // arriba centro
      -math.pi * 0.37,
      -math.pi * 0.20,
      0.0, // derecha horizontal
    ];

    final double rayInnerR = domeHalfW * 1.48;
    final double rayOuterR = domeHalfW * 2.15;
    final Offset rayOrigin = Offset(cx, (domeTop + domeBottom) * 0.52);

    for (int i = 0; i < angles.length; i++) {
      final double a = angles[i];
      final bool isRed = i <= 3;
      final Paint rayPaint = Paint()
        ..color = isRed ? const Color(0xFFE53935) : const Color(0xFF1E88E5)
        ..strokeWidth = w * 0.032
        ..strokeCap = StrokeCap.round;

      final Offset p1 = Offset(
        rayOrigin.dx + math.cos(a) * rayInnerR,
        rayOrigin.dy + math.sin(a) * rayInnerR,
      );
      final Offset p2 = Offset(
        rayOrigin.dx + math.cos(a) * rayOuterR,
        rayOrigin.dy + math.sin(a) * rayOuterR,
      );
      canvas.drawLine(p1, p2, rayPaint);
    }

    // 3. Cúpula de la sirena (mitad izquierda roja, mitad derecha azul)
    final Path domePath = Path()
      ..moveTo(cx - domeHalfW, domeBottom)
      ..lineTo(cx - domeHalfW * 0.85, domeTop + (domeBottom - domeTop) * 0.35)
      ..quadraticBezierTo(
        cx - domeHalfW * 0.85,
        domeTop,
        cx,
        domeTop,
      )
      ..quadraticBezierTo(
        cx + domeHalfW * 0.85,
        domeTop,
        cx + domeHalfW * 0.85,
        domeTop + (domeBottom - domeTop) * 0.35,
      )
      ..lineTo(cx + domeHalfW, domeBottom)
      ..close();

    // Mitad izquierda (Roja)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, cx, h));
    final Paint redDomePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(cx - domeHalfW, domeTop, domeHalfW, domeBottom - domeTop));
    canvas.drawPath(domePath, redDomePaint);
    canvas.restore();

    // Mitad derecha (Azul)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx, 0, w - cx, h));
    final Paint blueDomePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF40C4FF), Color(0xFF0D47A1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(cx, domeTop, domeHalfW, domeBottom - domeTop));
    canvas.drawPath(domePath, blueDomePaint);
    canvas.restore();

    // Brillo blanco curvo en el lado izquierdo de la sirena
    final Path shinePath = Path()
      ..moveTo(cx - domeHalfW * 0.62, domeBottom - (domeBottom - domeTop) * 0.14)
      ..lineTo(cx - domeHalfW * 0.54, domeTop + (domeBottom - domeTop) * 0.36)
      ..quadraticBezierTo(
        cx - domeHalfW * 0.52,
        domeTop + (domeBottom - domeTop) * 0.14,
        cx - domeHalfW * 0.18,
        domeTop + (domeBottom - domeTop) * 0.12,
      );
    final Paint shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(shinePath, shinePaint);

    // 4. Base metálica gris de la sirena
    final double baseTop = domeBottom + h * 0.012;
    final double baseH = h * 0.068;
    final double baseHalfW = domeHalfW * 1.24;
    final RRect baseRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - baseHalfW, baseTop, baseHalfW * 2, baseH),
      topLeft: Radius.circular(baseH * 0.55),
      topRight: Radius.circular(baseH * 0.55),
      bottomLeft: Radius.circular(baseH * 0.15),
      bottomRight: Radius.circular(baseH * 0.15),
    );
    canvas.drawRRect(baseRRect, Paint()..color = const Color(0xFF78909C));

    // Sombra derecha en la base
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx, baseTop, w - cx, baseH));
    canvas.drawRRect(baseRRect, Paint()..color = const Color(0xFF455A64));
    canvas.restore();

    // 5. Estela amarilla y silueta de automóvil dorado
    final double roadY = baseTop + baseH + h * 0.088;
    final double carStartX = w * 0.59;
    final double carEndX = w * 0.90;
    final double carW = carEndX - carStartX;

    // Estela cónica hacia la izquierda
    final Path trailPath = Path()
      ..moveTo(w * 0.11, roadY - h * 0.004)
      ..lineTo(carStartX - w * 0.018, roadY - h * 0.026)
      ..lineTo(carStartX - w * 0.018, roadY)
      ..close();
    canvas.drawPath(trailPath, Paint()..color = const Color(0xFFFBC02D));

    // Silueta del automóvil deportivo
    final Path carPath = Path()
      ..moveTo(carStartX, roadY)
      ..lineTo(carStartX + carW * 0.04, roadY - h * 0.032)
      ..quadraticBezierTo(
        carStartX + carW * 0.18,
        roadY - h * 0.044,
        carStartX + carW * 0.30,
        roadY - h * 0.068,
      )
      ..quadraticBezierTo(
        carStartX + carW * 0.48,
        roadY - h * 0.084,
        carStartX + carW * 0.68,
        roadY - h * 0.064,
      )
      ..lineTo(carStartX + carW * 0.80, roadY - h * 0.038)
      ..quadraticBezierTo(
        carStartX + carW * 0.98,
        roadY - h * 0.032,
        carEndX,
        roadY,
      )
      ..close();
    canvas.drawPath(carPath, Paint()..color = const Color(0xFFFBC02D));

    // Ventanas oscuras del auto
    final Path windowPath = Path()
      ..moveTo(carStartX + carW * 0.30, roadY - h * 0.038)
      ..lineTo(carStartX + carW * 0.38, roadY - h * 0.062)
      ..lineTo(carStartX + carW * 0.62, roadY - h * 0.060)
      ..lineTo(carStartX + carW * 0.72, roadY - h * 0.038)
      ..close();
    canvas.drawPath(windowPath, Paint()..color = const Color(0xFF0B1E38));

    // 6. Texto "S.O.S. AUTO" inferior (blanco + dorado)
    if (showTextInside) {
      final TextPainter tp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          style: TextStyle(
            fontSize: w * 0.128,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
          children: const [
            TextSpan(
              text: 'S.O.S. ',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'AUTO',
              style: TextStyle(color: Color(0xFFFBC02D)),
            ),
          ],
        ),
      )..layout(maxWidth: w * 0.92);

      tp.paint(
        canvas,
        Offset((w - tp.width) * 0.5, roadY + h * 0.032),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SosAutoLogoPainter oldDelegate) =>
      oldDelegate.showTextInside != showTextInside;
}
