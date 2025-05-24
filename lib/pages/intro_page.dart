import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late AnimationController _bubbleController;

  final Color _bgColor = const Color(0xFF121212);
  final Color _bubbleColor = const Color(0xFF7D91FF).withOpacity(0.3);
  final Color _textColor = Colors.white;

  final int bubbleCount = 100; // de 40 a 100
  final List<Bubble> bubbles = [];

  Offset? touchPosition;

  @override
  void initState() {
    super.initState();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Inicializa burbujas con semilla fija para estabilidad visual
    final random = Random(42);
    for (int i = 0; i < bubbleCount; i++) {
      bubbles.add(
        Bubble(
          radius:
              random.nextDouble() * 5 +
              10, // 10-15 px (antes 7-12), +3 px promedio
          x: random.nextDouble(),
          y: random.nextDouble(),
          speed: random.nextDouble() * 0.3 + 0.1, // velocidad individual
        ),
      );
    }
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bgColor,
      body: GestureDetector(
        onPanDown: (details) {
          setState(() {
            touchPosition = details.localPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            touchPosition = details.localPosition;
          });
        },
        onPanEnd: (_) {
          setState(() {
            touchPosition = null;
          });
        },
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: BubblePainter(
                    bubbles: bubbles,
                    animationValue: _bubbleController.value,
                    screenSize: size,
                    bubbleColor: _bubbleColor,
                    touchPosition: touchPosition,
                  ),
                );
              },
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CANGREVICHE',
                        style: GoogleFonts.lora(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: _textColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'La mejor cevichería',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: _textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 60),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/main');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: const Color(0xFF7D91FF),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Entrar',
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7D91FF),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Bubble {
  double radius;
  double x; // porcentaje horizontal [0,1]
  double y; // porcentaje vertical [0,1]
  double speed;

  Bubble({
    required this.radius,
    required this.x,
    required this.y,
    required this.speed,
  });
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;
  final Size screenSize;
  final Color bubbleColor;
  final Offset? touchPosition;

  BubblePainter({
    required this.bubbles,
    required this.animationValue,
    required this.screenSize,
    required this.bubbleColor,
    this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = bubbleColor;
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.08);

    for (var bubble in bubbles) {
      // Movimiento vertical: sube despacio, usa velocidad individual
      bubble.y -= bubble.speed * 0.005;
      if (bubble.y < 0) bubble.y += 1;

      double dx = bubble.x * size.width;
      double dy = bubble.y * size.height;

      // Si hay toque, burbujas cercanas se desvían suavemente hacia/desde el toque
      if (touchPosition != null) {
        final touchDx = touchPosition!.dx;
        final touchDy = touchPosition!.dy;

        final dist = sqrt(pow(dx - touchDx, 2) + pow(dy - touchDy, 2));
        if (dist < 150) {
          final angle = atan2(dy - touchDy, dx - touchDx);
          final force = (150 - dist) / 150;
          dx += cos(angle) * force * 20;
          dy += sin(angle) * force * 20;
        }
      }

      final offset = Offset(dx, dy);

      // burbuja base
      canvas.drawCircle(offset, bubble.radius, paint);

      // brillo sutil en esquina superior izquierda
      final highlightOffset = Offset(
        dx - bubble.radius / 3,
        dy - bubble.radius / 3,
      );
      canvas.drawCircle(highlightOffset, bubble.radius / 4, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) => true;
}
