import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  // Referencia al documento 'bodega' dentro de la colección 'productos'
  final DocumentReference bodegaRef = FirebaseFirestore.instance
      .collection('productos')
      .doc('bodega');

  // Función para agregar un ingrediente a la bodega
  void _agregarIngrediente() {
    final _nombreController = TextEditingController();
    final _cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Agregar ingrediente'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del ingrediente',
                  ),
                ),
                TextField(
                  controller: _cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final nombre = _nombreController.text.trim().toLowerCase();
                  final cantidad = int.tryParse(
                    _cantidadController.text.trim(),
                  );

                  if (nombre.isEmpty || cantidad == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Datos inválidos')),
                    );
                    return;
                  }

                  try {
                    // Verificar si el ingrediente ya existe
                    final bodegaSnapshot = await bodegaRef.get();
                    final bodegaData =
                        bodegaSnapshot.data() as Map<String, dynamic>;

                    if (bodegaData.containsKey(nombre)) {
                      // Si el producto ya existe, mostrar mensaje y no agregar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Producto "$nombre" ya existe en la bodega.',
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                      return;
                    }

                    // Agregar el ingrediente a la bodega
                    await bodegaRef.set({
                      nombre: cantidad,
                    }, SetOptions(merge: true));

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ingrediente "$nombre" agregado.'),
                      ),
                    );
                  } catch (e) {
                    print('Error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  // Función para editar un ingrediente
  void _editarIngrediente(String nombre, int cantidad) {
    final _cantidadController = TextEditingController(
      text: cantidad.toString(),
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar ingrediente'),
            content: TextField(
              controller: _cantidadController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final nuevaCantidad = int.tryParse(
                    _cantidadController.text.trim(),
                  );

                  if (nuevaCantidad == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cantidad inválida')),
                    );
                    return;
                  }

                  try {
                    // Actualizar el ingrediente en 'bodega'
                    await bodegaRef.update({nombre: nuevaCantidad});

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ingrediente "$nombre" actualizado.'),
                      ),
                    );
                  } catch (e) {
                    print('Error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar: $e')),
                    );
                  }
                },
                child: const Text('Actualizar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  // Función para eliminar un ingrediente
  void _eliminarIngrediente(String nombre) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar ingrediente'),
            content: Text('¿Estás seguro de que deseas eliminar "$nombre"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmDelete == true) {
      try {
        // Eliminar el ingrediente de 'bodega'
        await bodegaRef.update({nombre: FieldValue.delete()});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingrediente "$nombre" eliminado.')),
        );
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bodega de Ingredientes')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: bodegaRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar los ingredientes'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('La bodega está vacía.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            children:
                data.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    trailing: Text(entry.value.toString()),
                    onTap: () => _editarIngrediente(entry.key, entry.value),
                    onLongPress: () => _eliminarIngrediente(entry.key),
                  );
                }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarIngrediente,
        child: const Icon(Icons.add),
        tooltip: 'Agregar ingrediente',
      ),
    );
  }
}
