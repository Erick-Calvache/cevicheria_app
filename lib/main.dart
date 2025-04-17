import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'pedidos_page.dart';
import 'productos_page.dart';

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
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: const MenuPage(),
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

  Future<bool> _guardarPedido() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference pedidos = firestore.collection('pedidos');
      CollectionReference productos = firestore.collection('productos');

      final platosSeleccionados =
          _menu.where((plato) => plato['cantidad'] > 0).toList();

      if (platosSeleccionados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No has seleccionado ningún plato para guardar.'),
          ),
        );
        return false;
      }

      var bodega = await productos.doc('bodega').get();
      var productosData = bodega.data() as Map<String, dynamic>;

      final cevicheCamaronCantidad = _menu[0]['cantidad'];
      final stockCamaron =
          int.tryParse(productosData['camarones'].toString()) ?? 0;

      if (cevicheCamaronCantidad > 0 &&
          stockCamaron < cevicheCamaronCantidad * 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay suficientes camarones en bodega.'),
          ),
        );
        return false;
      }

      await pedidos.add({
        'items':
            platosSeleccionados
                .map(
                  (plato) => {
                    'nombre': plato['nombre'],
                    'cantidad': plato['cantidad'],
                  },
                )
                .toList(),
        'fecha': FieldValue.serverTimestamp(),
      });

      if (cevicheCamaronCantidad > 0) {
        await productos.doc('bodega').update({
          'camarones': FieldValue.increment(-(cevicheCamaronCantidad * 8)),
        });
      }

      // Reiniciar cantidades
      setState(() {
        for (var plato in _menu) {
          plato['cantidad'] = 0;
        }
      });

      // Mostrar el diálogo inmediatamente después de guardar el pedido
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  '¡Pedido guardado!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text('Tu pedido fue registrado exitosamente.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PedidosPage(),
                        ),
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
      });

      return true;
    } catch (e) {
      print('Error al guardar el pedido: $e');
      return false;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú de la Cevichería'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductosPage()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _menu.length,
        itemBuilder: (context, index) {
          final plato = _menu[index];
          return ListTile(
            title: Text(plato['nombre']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _restar(index),
                  icon: const Icon(Icons.remove),
                ),
                Text('${plato['cantidad']}'),
                IconButton(
                  onPressed: () => _sumar(index),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final guardadoConExito = await _guardarPedido();

          if (guardadoConExito) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PedidosPage()),
            );

            return;
          }

          await _guardarPedido();

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PedidosPage()),
          );
        },
        label: const Text('Ver Pedidos'),
        icon: const Icon(Icons.list),
      ),
    );
  }
}
