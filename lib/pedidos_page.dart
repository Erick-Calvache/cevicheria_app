// lib/pedidos_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PedidosPage extends StatelessWidget {
  const PedidosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos en Vivo')),
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

          final pedidos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index].data() as Map<String, dynamic>;
              final items = pedido['items'] as List<dynamic>;
              final fecha = pedido['fecha']?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                child: ListTile(
                  title: Text('Pedido ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha: ${fecha != null ? fecha.toString() : 'No disponible'}',
                      ),
                      ...items.map((item) {
                        return Text('${item['nombre']}: ${item['cantidad']}');
                      }).toList(),
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
