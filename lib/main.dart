// Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'intro_page.dart';
import 'theme.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
    macOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
    {'nombre': 'Ceviche de calamar', 'cantidad': 0},
    {'nombre': 'Ceviche de pescado', 'cantidad': 0},
    {'nombre': 'Ceviche de concha', 'cantidad': 0},
    {'nombre': 'Ceviche de pulpa de cangrejo', 'cantidad': 0},
    {'nombre': 'Ceviche mixto', 'cantidad': 0},
    {'nombre': 'Ceviche trimixto', 'cantidad': 0},
    {'nombre': 'Ceviche rompecolchón', 'cantidad': 0},
    {'nombre': 'Ceviche rompeombligo', 'cantidad': 0},
    {'nombre': 'Viche de cangrejo', 'cantidad': 0},
    {'nombre': 'Viche de camarón', 'cantidad': 0},
    {'nombre': 'Viche de pescado', 'cantidad': 0},
    {'nombre': 'Tres al hilo', 'cantidad': 0},
    {'nombre': 'Encebollado normal', 'cantidad': 0},
    {'nombre': '1/2 encebollado normal', 'cantidad': 0},
    {'nombre': 'Encebollado mixto', 'cantidad': 0},
    {'nombre': 'Encebollado trimixto', 'cantidad': 0},
    {'nombre': 'Encebollado maritimo', 'cantidad': 0},
    {'nombre': 'Arroz con camarón', 'cantidad': 0},
    {'nombre': '1/2 arroz con camarón', 'cantidad': 0},
    {'nombre': 'Arroz con concha', 'cantidad': 0},
    {'nombre': '1/2 arroz con concha', 'cantidad': 0},
    {'nombre': 'Arroz mixto', 'cantidad': 0},
    {'nombre': 'Arroz trimixto', 'cantidad': 0},
    {'nombre': 'Arroz rompe', 'cantidad': 0},
    {'nombre': 'Combo económico', 'cantidad': 0},
    {'nombre': 'Combo pata gorda', 'cantidad': 0},
    {'nombre': 'Sopa especial de pulpa de cangrejo', 'cantidad': 0},
    {'nombre': 'Tenazas de cangrejo', 'cantidad': 0},
    {'nombre': 'Combo friends (3 personas)', 'cantidad': 0},
    {'nombre': 'Combo súper (3 personas)', 'cantidad': 0},
    {'nombre': 'Combo familiar (4 personas)', 'cantidad': 0},
    {'nombre': 'Combo Jumbo familiar (5 personas)', 'cantidad': 0},
    {'nombre': 'Cangreviche', 'cantidad': 0},
    {'nombre': 'La gamba', 'cantidad': 0},
    {'nombre': 'Chicharrón de pescado', 'cantidad': 0},
    {'nombre': 'Corvina encocado', 'cantidad': 0},
    {'nombre': 'Camarón encocado', 'cantidad': 0},
    {'nombre': 'Picaditas de mariscos', 'cantidad': 0},
    {'nombre': 'Volcán de camarón', 'cantidad': 0},
    {'nombre': 'Filete de corvina', 'cantidad': 0},
    {'nombre': 'Camarones apanados', 'cantidad': 0},
    {'nombre': 'Conchas asadas', 'cantidad': 0},
    {'nombre': 'Entre panas', 'cantidad': 0},
    {'nombre': 'Mix de mariscos', 'cantidad': 0},
    {'nombre': '', 'cantidad': 0},
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

  void escucharPedidosNuevos() {
    FirebaseFirestore.instance
        .collection('pedidos')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((event) {
          for (var doc in event.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              mostrarNotificacion(doc.doc.data()?['nombre'] ?? 'Nuevo pedido');
            }
          }
        });
  }

  void mostrarNotificacion(String titulo) async {
    const notificationDetails = NotificationDetails();

    await flutterLocalNotificationsPlugin.show(
      0,
      '📦 Nuevo Pedido',
      titulo,
      notificationDetails,
    );

    final player = AudioPlayer();
    await player.play(
      AssetSource('notificacion.mp3'),
    ); // Coloca este archivo en assets/
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
