// esta linea importa librerías principales de Flutter y Firebase
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'intro_page.dart';
import 'theme.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'home_page.dart';

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
        '/main': (context) => const HomePage(),
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
  // esta lista contiene los platos disponibles y sus cantidades
  final List<Map<String, dynamic>> _menu = [
    {'nombre': 'Ceviche de camarón', 'cantidad': 0},
    {'nombre': 'Ceviche mixto', 'cantidad': 0},
    {'nombre': 'Ceviche con arroz', 'cantidad': 0},
    {'nombre': 'Ceviche con chifle', 'cantidad': 0},
    {'nombre': 'Ceviche de pulpo', 'cantidad': 0},
    {'nombre': 'Ceviche extra grande', 'cantidad': 0},
    {'nombre': 'Arroz con camarones', 'cantidad': 0},
    {'nombre': 'consome', 'cantidad': 0},
    {'nombre': 'sancocho de pescado', 'cantidad': 0},
  ];

  // suma la cantidad de un plato
  void _sumar(int index) {
    setState(() {
      _menu[index]['cantidad']++;
    });
  }

  // resta la cantidad de un plato
  void _restar(int index) {
    setState(() {
      if (_menu[index]['cantidad'] > 0) {
        _menu[index]['cantidad']--;
      }
    });
  }

  // muestra diálogo de error si hay algún problema
  Future<void> _mostrarDialogoError(String mensaje) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => Center(
            child: GlassContainer(
              blur: 20,
              shadowStrength: 8,
              borderRadius: BorderRadius.circular(25),
              opacity: 0.12,
              border: Border.all(color: const Color(0xFF7D91FF), width: 1),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFF7D91FF),
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Atención',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      mensaje,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7D91FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // muestra mensaje de confirmación si el pedido fue exitoso
  Future<void> _mostrarConfirmacion() async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => Center(
            child: GlassContainer(
              blur: 20,
              opacity: 0.12,
              borderRadius: BorderRadius.circular(25),
              shadowStrength: 8,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      '¡Pedido guardado!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // guarda el pedido en Firestore si hay stock suficiente
  Future<bool> _guardarPedido() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final pedidos = firestore.collection('pedidos');
      final productos = firestore.collection('productos');
      final platosSeleccionados =
          _menu.where((p) => p['cantidad'] > 0).toList();

      if (platosSeleccionados.isEmpty) {
        await _mostrarDialogoError('No has seleccionado ningún plato.');
        return false;
      }

      final bodegaSnapshot = await productos.doc('bodega').get();
      final productosData = bodegaSnapshot.data();

      if (productosData == null) {
        await _mostrarDialogoError(
          'El inventario de la bodega no está disponible.',
        );
        return false;
      }

      final cevicheCamaronCantidad = _menu[0]['cantidad'];
      final stockCamaron = (productosData['camarones'] as int?) ?? 0;

      if (cevicheCamaronCantidad > 0 &&
          stockCamaron < cevicheCamaronCantidad * 8) {
        await _mostrarDialogoError('No hay suficientes camarones en bodega.');
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
      await _mostrarDialogoError('Error al guardar el pedido.');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Menú de la Cevichería',
          style: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        // Esta línea elimina cualquier sombra que aparezca al hacer scroll.
        scrolledUnderElevation: 0,
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
              // esta linea crea cada tarjeta de plato
              child: ListTile(
                title: Text(
                  plato['nombre'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                    decoration: TextDecoration.none,
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
    );
  }
}
