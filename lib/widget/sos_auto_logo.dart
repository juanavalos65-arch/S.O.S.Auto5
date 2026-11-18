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

    // 1. Fondo redondeado azul marino oscuro (#0A192F)
    final RRect bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.22),
    );
    final Paint bgPaint = Paint()..color = const Color(0xFF0A192F);
    canvas.drawRRect(bgRect, bgPaint);

    final double cx = w * 0.5;
    final double domeBottom = h * (showTextInside ? 0.57 : 0.68);
    final double domeTop = h * (showTextInside ? 0.24 : 0.27);
    final double domeHalfW = w * 0.185;

    // 2. Destellos radiales (7 rayos con halo luminoso: 4 rojos izq/centro, 3 azules der)
    final List<double> angles = [
      -math.pi, // izquierda horizontal
      -math.pi * 0.80,
      -math.pi * 0.63,
      -math.pi * 0.50, // arriba centro
      -math.pi * 0.37,
      -math.pi * 0.20,
      0.0, // derecha horizontal
    ];

    final double rayInnerR = domeHalfW * 1.46;
    final double rayOuterR = domeHalfW * 2.18;
    final Offset rayOrigin = Offset(cx, (domeTop + domeBottom) * 0.52);

    for (int i = 0; i < angles.length; i++) {
      final double a = angles[i];
      final bool isRed = i <= 3;

      final Offset p1 = Offset(
        rayOrigin.dx + math.cos(a) * rayInnerR,
        rayOrigin.dy + math.sin(a) * rayInnerR,
      );
      final Offset p2 = Offset(
        rayOrigin.dx + math.cos(a) * rayOuterR,
        rayOrigin.dy + math.sin(a) * rayOuterR,
      );

      // Halo suave
      final Paint glowPaint = Paint()
        ..color = (isRed ? const Color(0xFFFF1744) : const Color(0xFF00B0FF))
            .withOpacity(0.35)
        ..strokeWidth = w * 0.056
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, glowPaint);

      // Núcleo del rayo
      final Paint rayPaint = Paint()
        ..color = isRed ? const Color(0xFFE53935) : const Color(0xFF1E88E5)
        ..strokeWidth = w * 0.032
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, rayPaint);
    }

    // 3. Cúpula de la sirena (mitad izquierda roja, mitad derecha azul)
    final Path domePath = Path()
      ..moveTo(cx - domeHalfW, domeBottom)
      ..lineTo(cx - domeHalfW * 0.86, domeTop + (domeBottom - domeTop) * 0.34)
      ..quadraticBezierTo(
        cx - domeHalfW * 0.86,
        domeTop,
        cx,
        domeTop,
      )
      ..quadraticBezierTo(
        cx + domeHalfW * 0.86,
        domeTop,
        cx + domeHalfW * 0.86,
        domeTop + (domeBottom - domeTop) * 0.34,
      )
      ..lineTo(cx + domeHalfW, domeBottom)
      ..close();

    // Mitad izquierda (Roja)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, cx, h));
    final Paint redDomePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD50000), Color(0xFFFF5252), Color(0xFF9B0000)],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(
          Rect.fromLTWH(cx - domeHalfW, domeTop, domeHalfW, domeBottom - domeTop));
    canvas.drawPath(domePath, redDomePaint);
    canvas.restore();

    // Mitad derecha (Azul)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx, 0, w - cx, h));
    final Paint blueDomePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF00B0FF), Color(0xFF1565C0)],
        stops: [0.0, 0.45, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(
          Rect.fromLTWH(cx, domeTop, domeHalfW, domeBottom - domeTop));
    canvas.drawPath(domePath, blueDomePaint);
    canvas.restore();

    // Brillo blanco curvo en el lado izquierdo de la sirena
    final Path shinePath = Path()
      ..moveTo(cx - domeHalfW * 0.62, domeBottom - (domeBottom - domeTop) * 0.14)
      ..lineTo(cx - domeHalfW * 0.54, domeTop + (domeBottom - domeTop) * 0.35)
      ..quadraticBezierTo(
        cx - domeHalfW * 0.52,
        domeTop + (domeBottom - domeTop) * 0.14,
        cx - domeHalfW * 0.18,
        domeTop + (domeBottom - domeTop) * 0.12,
      );
    final Paint shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(shinePath, shinePaint);

    // 4. Base metálica gris de la sirena con luz superior y sombra derecha
    final double baseTop = domeBottom + h * 0.010;
    final double baseH = h * 0.068;
    final double baseHalfW = domeHalfW * 1.24;
    final RRect baseRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - baseHalfW, baseTop, baseHalfW * 2, baseH),
      topLeft: Radius.circular(baseH * 0.55),
      topRight: Radius.circular(baseH * 0.55),
      bottomLeft: Radius.circular(baseH * 0.18),
      bottomRight: Radius.circular(baseH * 0.18),
    );
    canvas.drawRRect(baseRRect, Paint()..color = const Color(0xFF78909C));

    // Mitad derecha más oscura de la base
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx, baseTop, w - cx, baseH));
    canvas.drawRRect(baseRRect, Paint()..color = const Color(0xFF455A64));
    canvas.restore();

    // Reborde claro superior de la base
    final Paint baseHighlight = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.008;
    canvas.drawRRect(baseRRect, baseHighlight);

    // 5. Estela amarilla y silueta de automóvil dorado con pasos de rueda
    final double roadY = baseTop + baseH + h * 0.088;
    final double carStartX = w * 0.59;
    final double carEndX = w * 0.90;
    final double carW = carEndX - carStartX;
    final double wheelR = carW * 0.105;

    // Estela cónica hacia la izquierda
    final Path trailPath = Path()
      ..moveTo(w * 0.11, roadY - h * 0.004)
      ..lineTo(carStartX - w * 0.018, roadY - h * 0.025)
      ..lineTo(carStartX - w * 0.018, roadY)
      ..close();
    canvas.drawPath(trailPath, Paint()..color = const Color(0xFFFBC02D));

    // Silueta del automóvil con arcos de rueda
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
      // Paso de rueda delantera
      ..lineTo(carStartX + carW * 0.83, roadY)
      ..arcToPoint(
        Offset(carStartX + carW * 0.67, roadY),
        radius: Radius.circular(wheelR),
        clockwise: false,
      )
      // Paso de rueda trasera
      ..lineTo(carStartX + carW * 0.31, roadY)
      ..arcToPoint(
        Offset(carStartX + carW * 0.15, roadY),
        radius: Radius.circular(wheelR),
        clockwise: false,
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
    canvas.drawPath(windowPath, Paint()..color = const Color(0xFF0A192F));

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
