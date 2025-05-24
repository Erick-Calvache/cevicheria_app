import 'package:cangreviche_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgregarPlatosPage extends StatefulWidget {
  const AgregarPlatosPage({Key? key}) : super(key: key);

  @override
  State<AgregarPlatosPage> createState() => _AgregarPlatosPageState();
}

class _AgregarPlatosPageState extends State<AgregarPlatosPage> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  List<Map<String, dynamic>> ingredientes = [];

  void _agregarIngrediente() {
    setState(() {
      ingredientes.add({'nombre': '', 'cantidad': 1});
    });
  }

  void _guardarPlato() async {
    final nombrePlato = _nombreController.text.trim();
    final precio = num.tryParse(_precioController.text.trim());

    if (nombrePlato.isEmpty || precio == null || ingredientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final Map<String, dynamic> data = {'nombre': nombrePlato, 'precio': precio};

    for (var ing in ingredientes) {
      if (ing['nombre'].isNotEmpty) {
        data[ing['nombre']] = ing['cantidad'];
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('platos')
          .doc(nombrePlato)
          .set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plato guardado exitosamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar el plato: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el plato')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar nuevo plato'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del plato',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del plato',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _precioController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Precio',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Ingredientes',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...ingredientes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final ingrediente = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 3,
                                    child: TextField(
                                      onChanged:
                                          (val) =>
                                              ingrediente['nombre'] =
                                                  val.trim(),
                                      decoration: const InputDecoration(
                                        hintText: 'Nombre del ingrediente',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    flex: 1,
                                    child: TextField(
                                      onChanged:
                                          (val) =>
                                              ingrediente['cantidad'] =
                                                  int.tryParse(val) ?? 1,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Cantidad',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 10),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _agregarIngrediente,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar ingrediente'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.primary,
                                side: BorderSide(color: colors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarPlato,
                icon: const Icon(Icons.save_alt),
                label: const Text('Guardar plato'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
