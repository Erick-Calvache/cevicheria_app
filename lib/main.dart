import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'intro_page.dart';
import 'pedidos_page.dart';
import 'productos_page.dart';
import 'theme.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cevichería App',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const IntroPage(),
        '/main': (context) => const MenuPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final List<Map<String, dynamic>> _menu = [
    {'nombre': 'Ceviche de camarón', 'cantidad': 0},
    {'nombre': 'Ceviche mixto', 'cantidad': 0},
    {'nombre': 'Ceviche con arroz', 'cantidad': 0},
    {'nombre': 'Ceviche con chifle', 'cantidad': 0},
    {'nombre': 'Ceviche extra grande', 'cantidad': 0},
  ];

  void _sumar(int index) {
    setState(() {
      _menu[index]['cantidad']++;
    });
  }

  void _restar(int index) {
    setState(() {
      if (_menu[index]['cantidad'] > 0) {
        _menu[index]['cantidad']--;
      }
    });
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.black87),
    );
  }

  Future<bool> _guardarPedido() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final pedidos = firestore.collection('pedidos');
      final productos = firestore.collection('productos');
      final platosSeleccionados =
          _menu.where((p) => p['cantidad'] > 0).toList();

      if (platosSeleccionados.isEmpty) {
        _mostrarSnackBar('No has seleccionado ningún plato.');
        return false;
      }

      final bodegaSnapshot = await productos.doc('bodega').get();
      final productosData = bodegaSnapshot.data();

      if (productosData == null) {
        _mostrarSnackBar('El inventario de la bodega no está disponible.');
        return false;
      }

      final cevicheCamaronCantidad = _menu[0]['cantidad'];
      final stockCamaron = (productosData['camarones'] as int?) ?? 0;

      if (cevicheCamaronCantidad > 0 &&
          stockCamaron < cevicheCamaronCantidad * 8) {
        _mostrarSnackBar('No hay suficientes camarones en bodega.');
        return false;
      }

      await pedidos.add({
        'items':
            platosSeleccionados
                .map((p) => {'nombre': p['nombre'], 'cantidad': p['cantidad']})
                .toList(),
        'fecha': FieldValue.serverTimestamp(),
      });

      if (cevicheCamaronCantidad > 0) {
        await productos.doc('bodega').update({
          'camarones': FieldValue.increment(-(cevicheCamaronCantidad * 8)),
        });
      }

      setState(() {
        for (var plato in _menu) {
          plato['cantidad'] = 0;
        }
      });

      if (!mounted) return true;

      await _mostrarConfirmacion();

      return true;
    } catch (e) {
      print('Error al guardar el pedido: $e');
      _mostrarSnackBar('Error al guardar el pedido.');
      return false;
    }
  }

  Future<void> _mostrarConfirmacion() async {
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              '¡Pedido guardado!',
              style: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
            ),
            content: const Text('Tu pedido fue registrado exitosamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PedidosPage()),
                  );
                },
                child: const Text('Ver pedidos'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menú de la Cevichería',
          style: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: _menu.length,
        itemBuilder: (context, index) {
          final plato = _menu[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: GlassContainer(
              blur: 18,
              opacity: 0.15,
              borderRadius: BorderRadius.circular(20),
              shadowStrength: 8,
              child: ListTile(
                title: Text(
                  plato['nombre'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _restar(index),
                      icon: const Icon(Icons.remove, color: Colors.white70),
                    ),
                    Text(
                      '${plato['cantidad']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => _sumar(index),
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarPedido,
        backgroundColor: AppTheme.primaryColor,
        label: const Text('Confirmar Pedido'),
        icon: const Icon(Icons.send),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PedidosPage()),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Pedidos'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductosPage()),
                  );
                },
                icon: const Icon(Icons.inventory_2),
                label: const Text('Inventario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
