import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cevicheria_app/pages/agregarplatos_page.dart';
import 'package:cevicheria_app/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import 'package:intl/intl.dart';

String? _deviceId;
DateTime? _appInitTime;
Set<String> _vistoPedidosIds = {};

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();

  String _searchTerm = '';
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {});
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
    FirebaseMessaging.instance.subscribeToTopic('nuevos_pedidos');

    _inicializar();
    _cargarPlatosDesdeFirestore();
    _verificarYArchivarPedidos();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    _appInitTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('deviceId');
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('deviceId', _deviceId!);
    }
    _loadVistosDesdeLocal();
    _loadMenuItems();
    _escucharPedidos();
  }

  void _verificarYArchivarPedidos() async {
    final ahora = DateTime.now();
    final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);

    final pedidosSnapshot =
        await FirebaseFirestore.instance
            .collection('pedidos')
            .where('fecha', isLessThan: Timestamp.fromDate(hoyInicio))
            .get();

    if (pedidosSnapshot.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in pedidosSnapshot.docs) {
        final data = doc.data();
        final fecha = (data['fecha'] as Timestamp).toDate();

        final mesDocId = DateFormat('MMMM yyyy').format(fecha);
        final diaDocId = fecha.day.toString().padLeft(2, '0');

        final historialRef = FirebaseFirestore.instance
            .collection('historial')
            .doc(mesDocId)
            .collection('dias')
            .doc(diaDocId)
            .collection('pedidos')
            .doc(doc.id);

        batch.set(historialRef, data);
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }

  Future<void> _mostrarDialogoError(String mensaje) async {
    await showDialog(
      context: context,
      builder:
          (_) =>
              AlertDialog(title: const Text('Alerta!'), content: Text(mensaje)),
    );
  }

  Future<void> _mostrarConfirmacion(double total) async {
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Valor total'),
            content: Text('Total a cobrar: \$${total.toStringAsFixed(2)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  Future<void> _cargarPlatosDesdeFirestore() async {
    final snapshot = await _firestore.collection('platos').get();
    final platos =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, 'nombre': data['nombre'], 'cantidad': 0};
        }).toList();
    setState(() {
      _menuItems = platos;
    });
  }

  void _loadVistosDesdeLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final vistos = prefs.getStringList('vistos') ?? [];
    setState(() {
      _vistoPedidosIds = vistos.toSet();
    });
  }

  void _escucharPedidos() {
    _firestore.collection('pedidos').snapshots().listen((snapshot) async {
      final prefs = await SharedPreferences.getInstance();
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final pedidoId = docChange.doc.id;
          if (_vistoPedidosIds.contains(pedidoId)) continue;
          final data = docChange.doc.data()!;
          final fecha = (data['fecha'] as Timestamp).toDate();
          final creador = data['creador'];
          if (fecha.isAfter(_appInitTime!) && creador != _deviceId) {
            try {
              await player.play(AssetSource('notificacion.mp3'));
              _vistoPedidosIds.add(pedidoId);
              await prefs.setStringList('vistos', _vistoPedidosIds.toList());
            } catch (e) {
              if (kDebugMode) print('Error al reproducir sonido: $e');
            }
          }
        }
      }
    });
  }

  void limpiarVistos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vistos');
    setState(() {
      _vistoPedidosIds.clear();
    });
  }

  Future<void> _loadMenuItems() async {
    final query = await _firestore.collection('platos').get();
    final items =
        query.docs.map((doc) {
          final nombre =
              doc.data().containsKey('nombre') ? doc['nombre'] : 'Sin nombre';
          return {'id': doc.id, 'nombre': nombre, 'cantidad': 0};
        }).toList();
    setState(() {
      _menuItems = items;
    });
    _saveMenuItems();
  }

  void _saveMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _menuItems.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('menuItems', jsonList);
  }

  void _sumar(int index) {
    setState(() {
      _menuItems[index]['cantidad']++;
    });
    _saveMenuItems();
  }

  void _restar(int index) {
    setState(() {
      if (_menuItems[index]['cantidad'] > 0) {
        _menuItems[index]['cantidad']--;
      }
    });
    _saveMenuItems();
  }

  Future<void> _guardarPedido() async {
    try {
      final platosSeleccionados =
          _menuItems.where((item) => item['cantidad'] > 0).toList();
      if (platosSeleccionados.isEmpty) {
        await _mostrarDialogoError('No se ha seleccionado ningún plato');
        return;
      }

      final snapshot =
          await _firestore.collection('productos').doc('bodega').get();
      final productosData = snapshot.data() ?? {};

      Map<String, num> requerimientosTotales = {};

      for (var plato in platosSeleccionados) {
        final cantidadPedida = int.tryParse(plato['cantidad'].toString()) ?? 0;
        final docPlato =
            await _firestore.collection('platos').doc(plato['id']).get();
        if (!docPlato.exists) {
          await _mostrarDialogoError(
            'El plato "${plato['nombre']}" no existe.',
          );
          return;
        }
        final dataPlato = docPlato.data() ?? {};
        for (var entry in dataPlato.entries) {
          final nombreIngrediente = entry.key;
          if (nombreIngrediente == 'nombre' || nombreIngrediente == 'precio')
            continue;
          final cantidadPorUnidad = num.tryParse(entry.value.toString()) ?? 0;
          requerimientosTotales[nombreIngrediente] =
              (requerimientosTotales[nombreIngrediente] ?? 0) +
              (cantidadPorUnidad * cantidadPedida);
        }
      }

      Map<String, dynamic> nuevosValoresStock = {};
      for (var entry in requerimientosTotales.entries) {
        final ingrediente = entry.key;
        final cantidad = entry.value;
        final stockActual = productosData[ingrediente] ?? 0;
        if (stockActual < cantidad) {
          await _mostrarDialogoError(
            'No hay suficiente stock de "$ingrediente".',
          );
          return;
        }
        nuevosValoresStock[ingrediente] = stockActual - cantidad;
      }

      // Calcular total
      double total = 0;
      for (var plato in platosSeleccionados) {
        final doc =
            await _firestore.collection('platos').doc(plato['id']).get();
        final precio =
            double.tryParse(doc.data()?['precio'].toString() ?? '0') ?? 0;
        total += precio * (plato['cantidad'] as int);
      }

      await _firestore
          .collection('productos')
          .doc('bodega')
          .update(nuevosValoresStock);
      await _firestore.collection('pedidos').add({
        'fecha': DateTime.now(),
        'platos': platosSeleccionados,
        'total': total,
        'creador': _deviceId,
      });

      _mostrarConfirmacion(total);

      setState(() {
        for (var item in _menuItems) {
          item['cantidad'] = 0;
        }
      });
      _saveMenuItems();
    } catch (e) {
      await _mostrarDialogoError('Error al guardar el pedido: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dentro de build:

    final platosFiltrados =
        _searchTerm.isEmpty
            ? _menuItems
            : _menuItems
                .where(
                  (item) => item['nombre'].toString().toLowerCase().contains(
                    _searchTerm.toLowerCase(),
                  ),
                )
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AgregarPlatosPage()),
                ),
            tooltip: 'Crear plato',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilledButton.icon(
              onPressed: _guardarPedido,
              icon: const Icon(
                Icons.send,
              ), // Puedes usar Icons.arrow_forward si prefieres
              label: const Text('Confirmar pedido'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    20,
                  ), // Esquinas redondeadas
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                backgroundColor:
                    AppTheme.primaryColor, // Cambia el color si quieres
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchTerm = value),
              decoration: const InputDecoration(
                hintText: 'Buscar platos',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: platosFiltrados.length,
        itemBuilder: (context, index) {
          final item = platosFiltrados[index];

          // Buscamos el índice real en _menuItems para que los botones modifiquen la lista original
          final realIndex = _menuItems.indexWhere(
            (element) => element['id'] == item['id'],
          );

          return ListTile(
            title: Text(item['nombre']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (realIndex != -1) {
                      _restar(realIndex);
                    }
                  },
                ),
                Text(item['cantidad'].toString()),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (realIndex != -1) {
                      _sumar(realIndex);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
      // Eliminamos el floatingActionButton porque ahora Confirmar está en el AppBar
    );
  }
}
