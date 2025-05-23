import 'package:cevicheria_app/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final DateTime ahora = DateTime.now();
  late final String mesActual;
  late final String diaActual;

  @override
  void initState() {
    super.initState();
    mesActual = DateFormat('MMMM yyyy').format(ahora);
    diaActual = ahora.day.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.backgroundColor,
        elevation: 0,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('historial')
                .doc(mesActual)
                .collection('dias')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshotDias) {
          if (snapshotDias.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (!snapshotDias.hasData || snapshotDias.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No hay historial disponible.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final diasDocs = snapshotDias.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: diasDocs.length,
            itemBuilder: (context, index) {
              final diaDoc = diasDocs[index];
              final dia = diaDoc.id;

              return Card(
                color: theme.colorScheme.surface,
                elevation: 6,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Theme(
                  data: theme.copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    childrenPadding: const EdgeInsets.only(bottom: 16),
                    title: Text(
                      'Pedidos del Día $dia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    iconColor: theme.colorScheme.primary,
                    collapsedIconColor: theme.colorScheme.primary,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('historial')
                                .doc(mesActual)
                                .collection('dias')
                                .doc(dia)
                                .collection('pedidos')
                                .orderBy('fecha', descending: true)
                                .snapshots(),
                        builder: (context, snapshotPedidos) {
                          if (snapshotPedidos.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            );
                          }

                          if (!snapshotPedidos.hasData ||
                              snapshotPedidos.data!.docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No hay pedidos en este día.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          final pedidos = snapshotPedidos.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pedidos.length,
                            itemBuilder: (context, index) {
                              final data =
                                  pedidos[index].data() as Map<String, dynamic>;
                              final fecha =
                                  (data['fecha'] as Timestamp?)?.toDate();
                              final total = (data['total'] ?? 0).toDouble();
                              final estado = data['estado'] ?? 'sin estado';
                              final items =
                                  (data['items'] ?? []) as List<dynamic>;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha: ${fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : 'Sin fecha'}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.7),
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Estado: $estado',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...items.map((item) {
                                      if (item is Map<String, dynamic>) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Text(
                                            '${item['nombre']}: ${item['cantidad']}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        );
                                      }
                                      return const Text('Item inválido');
                                    }).toList(),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Total: \$${total.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
