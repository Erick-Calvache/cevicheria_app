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
      final firestore = FirebaseFirestore.instance;
      final pedidos = firestore.collection('pedidos');
      final productos = firestore.collection('productos');

      final platosSeleccionados =
          _menu.where((p) => p['cantidad'] > 0).toList();

      if (platosSeleccionados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No has seleccionado ningún plato.')),
        );
        return false;
      }

      final bodegaSnapshot = await productos.doc('bodega').get();

      if (!bodegaSnapshot.exists || bodegaSnapshot.data() == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El inventario de la bodega no está disponible.'),
          ),
        );
        return false;
      }

      final productosData = bodegaSnapshot.data() as Map<String, dynamic>;
      final cevicheCamaronCantidad = _menu[0]['cantidad'];

      if (!productosData.containsKey('camarones')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró el producto "camarones" en la bodega.',
            ),
          ),
        );
        return false;
      }

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

      await Future.delayed(Duration.zero);

      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
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

      return true;
    } catch (e) {
      print('Error al guardar el pedido: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar el pedido: $e')));
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
            tooltip: 'Ver productos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductosPage()),
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PedidosPage()),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('Ver Pedidos'),
            ),
            TextButton.icon(
              onPressed: _guardarPedido,
              icon: const Icon(Icons.check),
              label: const Text('Guardar Pedido'),
            ),
          ],
        ),
        frfrfrfrfrfrfr,
      ),
    );
  }
}
