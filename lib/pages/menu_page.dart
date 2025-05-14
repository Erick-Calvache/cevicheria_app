import 'package:cevicheria_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
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

  List<Map<String, dynamic>> _menuItems = [
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
  ];

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

  void _loadMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = prefs.getStringList('menuItems') ?? [];
    final List<Map<String, dynamic>> loadedItems =
        jsonList
            .map((jsonStr) => Map<String, dynamic>.from(jsonDecode(jsonStr)))
            .toList();

    setState(() {
      if (loadedItems.isNotEmpty) {
        _menuItems = loadedItems;
      }
    });
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
          _menuItems.where((p) => p['cantidad'] > 0).toList();

      if (platosSeleccionados.isEmpty) {
        await _mostrarDialogoError('No se ha seleccionado ningún plato.');
        return;
      }

      final productosSnapshot =
          await _firestore.collection('productos').doc('bodega').get();
      final productosData = productosSnapshot.data();

      if (productosData == null) {
        await _mostrarDialogoError(
          'El inventario de la bodega no está disponible.',
        );
        return;
      }

      // Ejemplo de verificación de stock para "Ceviche de camarón"
      final cevicheCamaron = platosSeleccionados.firstWhereOrNull(
        (p) => p['nombre'] == 'Ceviche de camarón',
      );

      if (cevicheCamaron != null) {
        final stockCamaron = productosData['camarones'] ?? 0;
        final cantidad = cevicheCamaron['cantidad'];
        if (stockCamaron < cantidad * 8) {
          await _mostrarDialogoError('No hay suficientes camarones en bodega.');
          return;
        }

        // Descuento del stock
        await _firestore.collection('productos').doc('bodega').update({
          'camarones': FieldValue.increment(-(cantidad * 8)),
        });
      }

      await _firestore.collection('pedidos').add({
        'items': platosSeleccionados,
        'fecha': DateTime.now(),
        'estado': 'pendiente',
        'creador': _deviceId,
      });

      setState(() {
        for (var plato in _menuItems) {
          plato['cantidad'] = 0;
        }
      });

      _saveMenuItems();
      await _mostrarConfirmacion();
    } catch (e) {
      print('Error al guardar el pedido: $e');
      await _mostrarDialogoError('Hubo un error al guardar el pedido.');
    }
  }

  Future<void> _mostrarDialogoError(String mensaje) async {
    await showDialog(
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(mensaje, textAlign: TextAlign.center),
              ),
            ),
          ),
    );
  }

  Future<void> _mostrarConfirmacion() async {
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Pedido guardado'),
            content: const Text('Tu pedido se ha guardado correctamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
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
          return item['nombre'].toLowerCase().contains(_searchTerm);
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
                            icon: const Icon(Icons.remove),
                            onPressed: () => _restar(_menuItems.indexOf(item)),
                          ),
                          Text(
                            '${item['cantidad']}',
                            style: GoogleFonts.averiaSerifLibre(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
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
