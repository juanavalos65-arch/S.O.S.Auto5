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
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'lib/widget/IMG-20261118-WA5334.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
