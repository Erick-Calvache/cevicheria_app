import 'package:cevicheria_app/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:cevicheria_app/pages/agregarplatos_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart'; // si la instancia `flutterLocalNotificationsPlugin` está en main.dart

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
  bool _isSearching = false;

  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    FirebaseMessaging.instance.requestPermission(); // Pide permisos

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _mostrarNotificacion(
        message.notification?.title ?? '',
        message.notification?.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Maneja cuando abren la app desde la notificación
    });

    super.initState();
    _inicializar();
    _cargarPlatosDesdeFirestore();
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
    final snapshot =
        await FirebaseFirestore.instance.collection('platos').get();

    final platos =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'nombre': data['nombre'],
            'cantidad': 0, // Por defecto 0 al mostrar en el menú
          };
        }).toList();

    setState(() {
      _menuItems = platos;
    });
  }

  void _escucharPedidos() {
    _firestore.collection('pedidos').snapshots().listen((snapshot) {
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final data = docChange.doc.data()!;
          final fecha = (data['fecha'] as Timestamp).toDate();
          final creador = data['creador'];
          if (fecha.isAfter(_appInitTime!) && creador != _deviceId) {
            player.play(AssetSource('notificacion.mp3'));
          }
        }
      }
    });
  }

  void _mostrarNotificacion(String titulo, String cuerpo) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'canal_notificaciones',
          'Canal de notificaciones',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      titulo,
      cuerpo,
      platformChannelSpecifics,
    );
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

    _saveMenuItems(); // Opcional: actualiza localmente
  }

  void _saveMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList =
        _menuItems.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('menuItems', jsonList);
  }

  void _loadVistosDesdeLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final vistos = prefs.getStringList('vistos') ?? [];
    setState(() {
      _vistoPedidosIds = vistos.toSet();
    });
  }

  void _guardarPedidoVisto(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _vistoPedidosIds.add(id);
    await prefs.setStringList('vistos', _vistoPedidosIds.toList());
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

      // Obtener stock actual
      final snapshot =
          await _firestore.collection('productos').doc('bodega').get();
      final productosData = snapshot.data() ?? {};

      // Mapa para acumular requerimientos totales de ingredientes
      // Mapa para acumular requerimientos totales de ingredientes
      Map<String, num> requerimientosTotales = {};

      // 1. Calcular los ingredientes necesarios en total
      for (var plato in platosSeleccionados) {
        final cantidadPedida = int.tryParse(plato['cantidad'].toString()) ?? 0;

        final docPlato =
            await _firestore.collection('platos').doc(plato['id']).get();
        if (!docPlato.exists) {
          if (kDebugMode) {
            debugPrint('ID no encontrado: ${plato['id']}');
          }
          await _mostrarDialogoError(
            'El plato "${plato['nombre']}" no existe en la base de datos (ID: ${plato['id']}).',
          );
          return;
        }

        final dataPlato = docPlato.data() ?? {};

        print('Plato: ${plato['nombre']} - Cantidad pedida: $cantidadPedida');
        print('Ingredientes del plato: $dataPlato');

        for (var entry in dataPlato.entries) {
          final nombreIngrediente = entry.key;
          final valor = entry.value;

          // Filtrar campos no numéricos o que no sean ingredientes
          if (nombreIngrediente == 'nombre' || nombreIngrediente == 'precio') {
            continue; // Ignorar estos campos
          }

          final cantidadPorUnidad = num.tryParse(valor.toString()) ?? 0;

          requerimientosTotales[nombreIngrediente] =
              (requerimientosTotales[nombreIngrediente] ?? 0) +
              (cantidadPorUnidad * cantidadPedida);
        }
      }
      // 2. Preparar los nuevos valores para actualizar el stock en Firestore
      Map<String, dynamic> nuevosValoresStock = {};

      requerimientosTotales.forEach((ingrediente, cantidad) {
        final stockActual = productosData[ingrediente] ?? 0;
        nuevosValoresStock[ingrediente] = stockActual - cantidad;
      });

      // 3. Actualizar la colección productos -> documento bodega
      await _firestore
          .collection('productos')
          .doc('bodega')
          .update(nuevosValoresStock);

      // 1. Calcular los ingredientes necesarios en total
      for (var plato in platosSeleccionados) {
        final cantidadPedida = int.tryParse(plato['cantidad'].toString()) ?? 0;
        final docPlato =
            await _firestore.collection('platos').doc(plato['id']).get();
        if (!docPlato.exists) {
          if (kDebugMode) {
            debugPrint('ID no encontrado: ${plato['id']}');
          }
          await _mostrarDialogoError(
            'El plato "${plato['nombre']}" no existe en la base de datos (ID: ${plato['id']}).',
          );
          return;
        }

        final dataPlato = docPlato.data() ?? {};

        for (var entry in dataPlato.entries) {
          final nombreIngrediente = entry.key;
          final cantidadPorUnidad = num.tryParse(entry.value.toString()) ?? 0;

          // Ignorar campos que no son ingredientes
          if (nombreIngrediente == 'nombre' || nombreIngrediente == 'precio')
            continue;

          final cantidadTotal = cantidadPedida * (cantidadPorUnidad as num);
          requerimientosTotales[nombreIngrediente] =
              (requerimientosTotales[nombreIngrediente] ?? 0) + cantidadTotal;
        }
      }

      // 2. Verificar que hay suficiente stock
      bool hayStockSuficiente = true;
      List<String> errores = [];

      requerimientosTotales.forEach((ingrediente, cantidadNecesaria) {
        if (!productosData.containsKey(ingrediente)) {
          hayStockSuficiente = false;
          errores.add('El ingrediente "$ingrediente" no existe en bodega.');
        } else {
          final stockDisponible = productosData[ingrediente] ?? 0;
          if (stockDisponible < cantidadNecesaria) {
            hayStockSuficiente = false;
            errores.add(
              'No hay suficiente "$ingrediente" (necesitas $cantidadNecesaria, hay $stockDisponible).',
            );
          }
        }
      });

      if (!hayStockSuficiente) {
        await _mostrarDialogoError(errores.join('\n'));
        return;
      }
      List<Map<String, dynamic>> items =
          _menuItems
              .where((plato) => plato['cantidad'] > 0)
              .map<Map<String, dynamic>>(
                (plato) => {
                  'nombre': plato['nombre'],
                  'cantidad': plato['cantidad'],
                },
              )
              .toList();

      // 4. Calcular total
      double total = 0.0;
      for (var plato in platosSeleccionados) {
        final doc =
            await _firestore.collection('platos').doc(plato['id']).get();
        final precio = (doc['precio'] as num).toDouble();
        total += precio * (plato['cantidad'] as int);
      }

      // 5. Guardar el pedido
      await _firestore.collection('pedidos').add({
        'items': items,
        'fecha': DateTime.now(),
        'estado': 'pendiente',
        'creador': _deviceId,
        'total': total,
      });

      // 6. Limpiar cantidades seleccionadas
      setState(() {
        for (var plato in _menuItems) {
          plato['cantidad'] = 0;
        }
      });

      _saveMenuItems();
      await _mostrarConfirmacion(total);
    } catch (e, stacktrace) {
      if (kDebugMode) {
        debugPrint('Error al guardar el pedido: $e\n$stacktrace');
      }
      await _mostrarDialogoError('Hubo un error al guardar el pedido.');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems =
        _menuItems.where((item) {
          final nombre = item['nombre'];
          if (nombre == null) return false;
          return nombre.toLowerCase().contains(_searchTerm);
        }).toList();
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Stack(
          alignment: Alignment.center,
          children: [
            // Cuadro de búsqueda o botón de lupa alineado a la izquierda
            Align(
              alignment: Alignment.centerLeft,
              child:
                  _isSearching
                      ? SizedBox(
                        width: 580,
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {
                              _searchTerm = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar plato...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchTerm = '';
                                  _searchController.clear();
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(70, 0, 0, 0),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      )
                      : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
            ),

            // Título centrado, que no se mueve
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            label: Text(
              'Confirmar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.send),
            onPressed: _guardarPedido,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgregarPlatosPage()),
          );
          _cargarPlatosDesdeFirestore(); // Recarga el menú al volver
        },
        child: Icon(Icons.add),
      ),

      body:
          filteredItems.isEmpty
              ? Center(
                child: Text(
                  'No se encontraron platos',
                  style: GoogleFonts.averiaSerifLibre(fontSize: 18),
                ),
              )
              : ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        item['nombre'],
                        style: GoogleFonts.averiaSerifLibre(),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Symbols.chevron_left, weight: 800),
                            onPressed: () => _restar(_menuItems.indexOf(item)),
                          ),
                          Text(
                            '${item['cantidad']} ',
                            style: GoogleFonts.anton(),
                          ),
                          IconButton(
                            icon: Icon(Symbols.chevron_right, weight: 800),
                            onPressed: () => _sumar(_menuItems.indexOf(item)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
