import 'package:cevicheria_app/pages/menu_page.dart';
import 'package:cevicheria_app/pages/pedidos_page.dart';
import 'package:cevicheria_app/pages/productos_page.dart';
import 'package:cevicheria_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cevicheria_app/pages/circle_notch_painter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Widget> _pages = const [
    MenuPage(),
    PedidosPage(),
    ProductosPage(),
  ];

  // Coordenadas relativas para los íconos (x de 0 a 1, y también)
  List<Map<String, double>> iconPositions = [
    {'x': 0.167, 'y': 0.56}, // Menú
    {'x': 0.50, 'y': 0.56}, // Pedidos (centro)
    {'x': 0.834, 'y': 0.56}, // Productos
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _controller.forward(from: 0).then((_) => _controller.reverse());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Eliminamos backgroundColor aquí
      body: Stack(
        children: [
          // Fondo rojo
          Container(color: const Color.fromARGB(255, 172, 21, 21)),

          // Página activa
          Positioned.fill(child: _pages[_selectedIndex]),

          // Notch y navegación
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                child: SizedBox(
                  height: 75,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      final double itemWidth = width / 3;
                      final double circleLeft =
                          itemWidth * _selectedIndex + itemWidth / 2 - 21.5;
                      final double circleTop = 7;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Notch pintado
                          CustomPaint(
                            size: Size(width, 75),
                            painter: BottomNavPainter(
                              notchX: circleLeft + 21.5,
                            ),
                          ),

                          // Círculo animado
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: circleLeft,
                            top: circleTop,
                            child: Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 33, 33, 33),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),

                          // Íconos
                          ...List.generate(3, (index) {
                            IconData iconData;
                            String label;

                            switch (index) {
                              case 0:
                                iconData = Icons.restaurant_menu_rounded;
                                label = 'Menú';
                                break;
                              case 1:
                                iconData = Icons.receipt_long_rounded;
                                label = 'Pedidos';
                                break;
                              case 2:
                              default:
                                iconData = Icons.inventory_2_rounded;
                                label = 'Bodega';
                                break;
                            }

                            final isSelected = _selectedIndex == index;
                            final iconX = width * iconPositions[index]['x']!;
                            final iconY = 75 * iconPositions[index]['y']!;

                            return Positioned(
                              left: iconX - 25,
                              top: iconY - 24,
                              child: GestureDetector(
                                onTap: () => _onItemTapped(index),
                                child: AnimatedBuilder(
                                  animation: _animation,
                                  builder: (context, child) {
                                    double offsetY = 0;
                                    if (_selectedIndex == index) {
                                      offsetY = -8 * _animation.value;
                                    }
                                    return Transform.translate(
                                      offset: Offset(0, offsetY),
                                      child: child,
                                    );
                                  },
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _animation,
                                          builder: (context, childIcon) {
                                            double offsetY = 0;
                                            if (_selectedIndex == index) {
                                              offsetY = -8 * _animation.value;
                                            }
                                            return Transform.translate(
                                              offset: Offset(0, offsetY),
                                              child: childIcon,
                                            );
                                          },
                                          child: Icon(
                                            iconData,
                                            size: 24,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          child: Text(
                                            label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
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
