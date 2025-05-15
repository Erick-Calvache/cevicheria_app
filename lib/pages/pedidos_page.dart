import 'package:cevicheria_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final _player = AudioPlayer();
  final _notifications = FlutterLocalNotificationsPlugin();
  final formatFecha = DateFormat('dd/MM/yyyy HH:mm');
  final Map<String, bool> _expandido = {
    'pendiente': true,
    'listo': true,
    'entregado': false,
    'anulado': false,
  };

  final Set<String> _vistoPedidosIds = {};
  String _currentDeviceId = '';

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadDeviceId();
  }

  void _initNotifications() {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    _notifications.initialize(initSettings);
  }

  void _showNotification() {
    const androidDetails = AndroidNotificationDetails(
      'canal_pedidos',
      'Pedidos Nuevos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
    );
    const notifDetails = NotificationDetails(android: androidDetails);
    _notifications.show(
      0,
      'Nuevo Pedido',
      'Se agregó un nuevo pedido',
      notifDetails,
    );
  }

  void _reproducirSonido() async {
    await _player.setAsset('assets/sonidos/nuevo_pedido.mp3');
    _player.play();
  }

  void _loadDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _currentDeviceId = androidInfo.id;
    });
  }

  void _manejarNuevosPedidos(List<QueryDocumentSnapshot> docs) {
    for (var doc in docs) {
      final pedidoId = doc.id;
      final data = doc.data() as Map<String, dynamic>;
      final creadorId = data['deviceId'] ?? '';

      // Solo mostrar notificación y reproducir sonido si es un nuevo pedido no visto
      if (!_vistoPedidosIds.contains(pedidoId)) {
        _vistoPedidosIds.add(pedidoId);
        if (creadorId != _currentDeviceId) {
          _reproducirSonido(); // Solo suena si no es un pedido ya visto
          _showNotification();
        }
      }
    }
  }

  IconData getEstadoIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.access_time;
      case 'listo':
        return Icons.check_circle_outline;
      case 'entregado':
        return Icons.delivery_dining;
      case 'anulado':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color getEstadoColor(String estado) {
    switch (estado) {
      case 'listo':
        return Colors.green.withOpacity(0.08);
      case 'entregado':
        return Colors.blue.withOpacity(0.08);
      case 'anulado':
        return Colors.red.withOpacity(0.08);
      case 'pendiente':
      default:
        return Colors.white.withOpacity(0.05);
    }
  }

  String getEstadoTitulo(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendientes';
      case 'listo':
        return 'Listos';
      case 'entregado':
        return 'Entregados';
      case 'anulado':
        return 'Anulados';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos en Vivo'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('pedidos')
                .orderBy('fecha', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay pedidos aún.'));
          }

          final docs = snapshot.data!.docs;
          _manejarNuevosPedidos(docs);

          final pedidosPorEstado = <String, List<DocumentSnapshot>>{
            'pendiente': [],
            'listo': [],
            'entregado': [],
            'anulado': [],
          };

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final estado = (data['estado'] ?? 'pendiente') as String;
            pedidosPorEstado[estado]?.add(doc);
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children:
                pedidosPorEstado.entries.expand((entry) {
                  final estado = entry.key;
                  final estadoDocs = entry.value;

                  return [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandido[estado] = !_expandido[estado]!;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              getEstadoIcon(estado),
                              color: const Color.fromARGB(255, 0, 81, 255),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                getEstadoTitulo(estado),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Icon(
                              _expandido[estado]!
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_expandido[estado]! && estadoDocs.isNotEmpty)
                      ...estadoDocs.map((doc) {
                        final pedido = doc.data() as Map<String, dynamic>;
                        final items =
                            (pedido['items'] ?? []) as List<dynamic>? ?? [];
                        final fecha = (pedido['fecha'] as Timestamp?)?.toDate();
                        final estadoActual =
                            (pedido['estado'] ?? 'pendiente') as String;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: GlassContainer(
                            blur: 10,
                            opacity: 0.2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                            color: getEstadoColor(estadoActual),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pedido',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Fecha: ${fecha != null ? formatFecha.format(fecha) : 'Sin fecha'}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  ...items.map((item) {
                                    if (item is Map<String, dynamic>) {
                                      return Text(
                                        '${item['nombre'] ?? 'Item'}: ${item['cantidad'] ?? '?'}',
                                      );
                                    }
                                    return const Text('Item inválido');
                                  }),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Estado:'),
                                      DropdownButton<String>(
                                        value: estadoActual,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'pendiente',
                                            child: Text('Pendiente'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'listo',
                                            child: Text('Listo'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'entregado',
                                            child: Text('Entregado'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'anulado',
                                            child: Text('Anulado'),
                                          ),
                                        ],
                                        onChanged: (nuevoEstado) {
                                          if (nuevoEstado != null) {
                                            doc.reference.update({
                                              'estado': nuevoEstado,
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  if (estadoActual != 'anulado')
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Anular',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () {
                                          doc.reference.update({
                                            'estado': 'anulado',
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ];
                }).toList(),
          );
        },
      ),
    );
  }
}
