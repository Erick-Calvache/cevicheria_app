import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final DocumentReference bodegaRef = FirebaseFirestore.instance
      .collection('productos')
      .doc('bodega');

  String _busqueda = '';

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
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AlertDialog(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (nombreInicial == null)
                        TextField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre del ingrediente',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cantidadController,
                        decoration: InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
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
                        backgroundColor: const Color.fromARGB(
                          255,
                          203,
                          237,
                          244,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
      titulo: 'Agregar ingrediente',
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ingrediente "$nombre" agregado.')),
          );
        } catch (e) {
          print('Error: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        }
      },
    );
  }

  void _editarIngrediente(String nombre, int cantidad) {
    _mostrarDialogoIngrediente(
      titulo: 'Editar ingrediente',
      nombreInicial: nombre,
      cantidadInicial: cantidad,
      onGuardar: (nombre, nuevaCantidad) async {
        try {
          await bodegaRef.update({nombre: nuevaCantidad});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ingrediente "$nombre" actualizado.')),
          );
        } catch (e) {
          print('Error: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
        }
      },
    );
  }

  void _eliminarIngrediente(String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AlertDialog(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text('Eliminar ingrediente'),
                  content: Text('¿Deseas eliminar "$nombre"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    if (confirmar == true) {
      try {
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        title: const Text('Bodega de Ingredientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar ingrediente',
            onPressed: () {
              showSearch(
                context: context,
                delegate: _IngredienteSearchDelegate(
                  bodegaRef: bodegaRef,
                  onEditar: _editarIngrediente,
                  onEliminar: _eliminarIngrediente,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: bodegaRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los datos'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('La bodega está vacía'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final ingredientes =
              data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 90),
            itemCount: ingredientes.length,
            itemBuilder: (context, index) {
              final nombre = ingredientes[index].key;
              final cantidad = ingredientes[index].value;

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Card(
                    color: Colors.white.withOpacity(0.85),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Cantidad: $cantidad'),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _editarIngrediente(nombre, cantidad),
                      onLongPress: () => _eliminarIngrediente(nombre),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarIngrediente,
        tooltip: 'Agregar ingrediente',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _IngredienteSearchDelegate extends SearchDelegate {
  final DocumentReference bodegaRef;
  final void Function(String, int) onEditar;
  final void Function(String) onEliminar;

  _IngredienteSearchDelegate({
    required this.bodegaRef,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => BackButton();

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    return FutureBuilder<DocumentSnapshot>(
      future: bodegaRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No hay datos'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final resultados =
            data.entries
                .where((e) => e.key.contains(query.toLowerCase()))
                .toList();

        if (resultados.isEmpty) {
          return const Center(child: Text('No se encontraron ingredientes'));
        }

        return ListView(
          children:
              resultados.map((e) {
                final nombre = e.key;
                final cantidad = e.value;

                return ListTile(
                  title: Text(nombre),
                  subtitle: Text('Cantidad: $cantidad'),
                  onTap: () {
                    close(context, null);
                    onEditar(nombre, cantidad);
                  },
                  onLongPress: () {
                    close(context, null);
                    onEliminar(nombre);
                  },
                );
              }).toList(),
        );
      },
    );
  }
}
