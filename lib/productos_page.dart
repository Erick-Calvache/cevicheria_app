// lib/productos_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosPage extends StatelessWidget {
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bodega de Productos')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('productos')
                .doc('bodega')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No hay productos en la bodega.'));
          }

          var productos = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            children: [
              ListTile(
                title: const Text('Camarones'),
                subtitle: Text('Cantidad: ${productos['camarones']}'),
              ),
              ListTile(
                title: const Text('Pescado'),
                subtitle: Text('Cantidad: ${productos['pescado']}'),
              ),
              ListTile(
                title: const Text('Tomates'),
                subtitle: Text('Cantidad: ${productos['tomates']}'),
              ),
            ],
          );
        },
      ),
    );
  }
}
