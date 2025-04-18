// (Cambios están marcados con comentarios // 👈 CAMBIO)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:intl/intl.dart';

class PedidosPage extends StatelessWidget {
  const PedidosPage({super.key});

  static Color getEstadoColor(String estado) {
    switch (estado) {
      case 'listo':
        return Colors.green.withOpacity(0.1);
      case 'entregado':
        return Colors.blue.withOpacity(0.1);
      case 'anulado':
        return Colors.red.withOpacity(0.1);
      default:
        return Colors.white.withOpacity(0.05);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos en Vivo'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 4,
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

          try {
            final pedidosOriginal = snapshot.data!.docs;

            final pedidos = [...pedidosOriginal];

            // Ordenar por estado
            pedidos.sort((a, b) {
              final estadoA =
                  (a.data() as Map<String, dynamic>)['estado'] ?? 'pendiente';
              final estadoB =
                  (b.data() as Map<String, dynamic>)['estado'] ?? 'pendiente';
              final orden = ['pendiente', 'listo', 'entregado', 'anulado'];
              return orden.indexOf(estadoA).compareTo(orden.indexOf(estadoB));
            });
            return ListView.builder(
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                try {
                  final doc = pedidos[index];
                  final pedido = doc.data() as Map<String, dynamic>;

                  // 👈 CAMBIO: Establecer estado a 'pendiente' si no existe
                  if (!pedido.containsKey('estado')) {
                    doc.reference.update({'estado': 'pendiente'});
                  }

                  final items = (pedido['items'] ?? []) as List<dynamic>;
                  final fecha = (pedido['fecha'] as Timestamp?)?.toDate();
                  final estado = (pedido['estado'] ?? 'pendiente') as String;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    child: GlassContainer(
                      blur: 8,
                      opacity: 0.15,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      color: getEstadoColor(estado),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Fecha: ${fecha != null ? formatFecha.format(fecha) : 'No disponible'}',
                            ),
                            const SizedBox(height: 8),
                            ...items.map((item) {
                              if (item is Map<String, dynamic>) {
                                final nombre = item['nombre'] ?? 'Sin nombre';
                                final cantidad =
                                    item['cantidad'] ?? 'Sin cantidad';
                                return Text('$nombre: $cantidad');
                              } else {
                                return const Text('Item inválido');
                              }
                            }).toList(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Estado:'),
                                DropdownButton<String>(
                                  value: estado,
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
                                  onChanged: (nuevoEstado) async {
                                    if (nuevoEstado != null) {
                                      try {
                                        await doc.reference.update({
                                          'estado': nuevoEstado,
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Estado actualizado a "$nuevoEstado"',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error al actualizar estado: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (estado != 'anulado')
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
                                  onPressed: () async {
                                    try {
                                      await doc.reference.update({
                                        'estado': 'anulado',
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Pedido anulado'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al anular: $e'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  return const SizedBox.shrink();
                }
              },
            );
          } catch (e) {
            return Center(child: Text('Error al mostrar pedidos: $e'));
          }
        },
      ),
    );
  }
}
