import 'package:flutter/material.dart';
import 'main.dart';
import 'pedidos_page.dart';
import 'productos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MenuPage(),
    PedidosPage(),
    ProductosPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipPath(
        clipper: InvertedTopCornersClipper(),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: const Color.fromARGB(
            255,
            125,
            145,
            255,
          ).withOpacity(0.8),
          unselectedItemColor: const Color.fromARGB(100, 255, 255, 255),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Menú',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: 'Productos',
            ),
          ],
        ),
      ),
    );
  }
}

// Esta clase debe estar fuera de _HomePageState
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
