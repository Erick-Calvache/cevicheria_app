import 'package:flutter/material.dart';

class BottomNavPainter extends CustomPainter {
  final double notchX;

  BottomNavPainter({required this.notchX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color.fromARGB(255, 32, 32, 32);

    final path =
        Path()
          ..moveTo(0, 0)
          //ajuste del corte notch
          ..lineTo(notchX - 40, 0)
          ..quadraticBezierTo(notchX - 30, 0, notchX - 30, 16)
          ..arcToPoint(
            Offset(notchX + 30, 16),
            radius: const Radius.circular(30),
            clockwise: false,
          )
          ..quadraticBezierTo(notchX + 30, 0, notchX + 40, 0)
          //fin de ajuste de corte notch
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BottomNavPainter oldDelegate) {
    return oldDelegate.notchX != notchX;
  }
}
