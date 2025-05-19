import 'package:cevicheria_app/pages/menu_page.dart';
import 'package:cevicheria_app/theme.dart';
import 'package:flutter/material.dart';
import 'pedidos_page.dart';
import 'productos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  final List<Widget> _pages = const [
    MenuPage(),
    PedidosPage(),
    ProductosPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<double>(
      begin: -20, // Comienza desde arriba
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Suaviza la animación
      ),
    );

    // Iniciar con animación por defecto
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _controller.forward(from: 0); // reinicia animación al seleccionar nuevo
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipPath(
        clipper: InvertedTopCornersClipper(),
        child: BottomAppBar(
          color: AppTheme.backgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) {
              IconData iconData;
              String label;

              switch (index) {
                case 0:
                  iconData = Icons.restaurant_menu;
                  label = 'Menú';
                  break;
                case 1:
                  iconData = Icons.receipt_long;
                  label = 'Pedidos';
                  break;
                case 2:
                default:
                  iconData = Icons.inventory_2;
                  label = 'Productos';
                  break;
              }

              final isSelected = _selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onItemTapped(index),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final offsetY = isSelected ? _offsetAnimation.value : 0.0;

                      return Transform.translate(
                        offset: Offset(0, offsetY),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData,
                              color:
                                  isSelected
                                      ? const Color.fromARGB(255, 125, 145, 255)
                                      : const Color.fromARGB(
                                        100,
                                        255,
                                        255,
                                        255,
                                      ),
                            ),
                            Text(
                              label,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? const Color.fromARGB(
                                          255,
                                          125,
                                          145,
                                          255,
                                        )
                                        : const Color.fromARGB(
                                          100,
                                          255,
                                          255,
                                          255,
                                        ),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class InvertedTopCornersClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 30.0;
    final path = Path();

    path.moveTo(radius, 0);
    path.quadraticBezierTo(0, 0, 0, radius);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, radius);
    path.quadraticBezierTo(size.width, 0, size.width - radius, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
