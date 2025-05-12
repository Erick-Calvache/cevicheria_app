import 'dart:ui';
import '../theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final DocumentReference bodegaRef = FirebaseFirestore.instance
      .collection('productos')
      .doc('bodega');

  void _mostrarDialogoIngrediente({
    required String titulo,
    String? nombreInicial,
    int? cantidadInicial,
    required Function(String, int) onGuardar,
  }) {
    final _nombreController = TextEditingController(text: nombreInicial ?? '');
    final _cantidadController = TextEditingController(
      text: cantidadInicial?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: const Color.fromARGB(15, 0, 0, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AlertDialog(
                  backgroundColor: const Color.fromARGB(
                    255,
                    88,
                    88,
                    88,
                  ).withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    titulo,
                    style: GoogleFonts.merriweather(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (nombreInicial == null)
                        TextField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            labelStyle: TextStyle(color: Colors.white70),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _cantidadController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          labelStyle: TextStyle(color: Colors.white70),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final nombre =
                            _nombreController.text.trim().toLowerCase();
                        final cantidad = int.tryParse(
                          _cantidadController.text.trim(),
                        );

                        if ((nombre.isEmpty && nombreInicial == null) ||
                            cantidad == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Datos inválidos')),
                          );
                          return;
                        }

                        onGuardar(nombreInicial ?? nombre, cantidad);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _agregarIngrediente() {
    _mostrarDialogoIngrediente(
      titulo: 'Agregar Ingrediente',
      onGuardar: (nombre, cantidad) async {
        try {
          final bodegaSnapshot = await bodegaRef.get();
          final bodegaData =
              bodegaSnapshot.data() as Map<String, dynamic>? ?? {};

          if (bodegaData.containsKey(nombre)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ya existe "$nombre" en la bodega.')),
            );
            return;
          }

          await bodegaRef.set({nombre: cantidad}, SetOptions(merge: true));
          setState(() {});
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
    );
  }

  void _editarIngrediente(String nombre, int cantidad) {
    _mostrarDialogoIngrediente(
      titulo: 'Editar Ingrediente',
      nombreInicial: nombre,
      cantidadInicial: cantidad,
      onGuardar: (nombre, nuevaCantidad) async {
        try {
          await bodegaRef.update({nombre: nuevaCantidad});
          setState(() {});
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al editar: $e')));
        }
      },
    );
  }

  void _eliminarIngrediente(String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar Ingrediente'),
            content: Text('¿Deseas eliminar "$nombre"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await bodegaRef.update({nombre: FieldValue.delete()});
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bodega de Ingredientes'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        // Esta línea elimina cualquier sombra que aparezca al hacer scroll.
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarIngrediente,
        backgroundColor: Color(0xFF7D91FF),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: bodegaRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No hay ingredientes'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final ingredientes =
              data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

          return ListView.builder(
            padding: const EdgeInsets.only(top: 100, bottom: 80),
            itemCount: ingredientes.length,
            itemBuilder: (context, index) {
              final nombre = ingredientes[index].key;
              final cantidad = ingredientes[index].value;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GlassContainer(
                  blur: 10,
                  opacity: 0.12,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  color: Colors.white.withOpacity(0.1),
                  child: ListTile(
                    title: Text(
                      nombre,
                      style: GoogleFonts.merriweather(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Cantidad: $cantidad',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.white),
                    onTap: () => _editarIngrediente(nombre, cantidad),
                    onLongPress: () => _eliminarIngrediente(nombre),
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
