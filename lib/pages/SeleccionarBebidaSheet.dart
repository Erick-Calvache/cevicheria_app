import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeleccionarBebidaSheet extends StatefulWidget {
  final bool desdeProductosPage;

  SeleccionarBebidaSheet({
    this.desdeProductosPage = false,
  }); // Para saber si viene desde productos_page

  @override
  State<SeleccionarBebidaSheet> createState() => _SeleccionarBebidaSheetState();
}

class _SeleccionarBebidaSheetState extends State<SeleccionarBebidaSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> bebidas = [];
  Map<String, int> cantidades = {};
  bool deseaBebidas = false;
  bool _preguntaMostrada = false;

  @override
  void initState() {
    super.initState();
    _cargarBebidas();
  }

  Future<void> _cargarBebidas() async {
    final snapshot = await _firestore.collection('bebidas').get();
    if (!mounted) return;

    setState(() {
      bebidas =
          snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'nombre': doc['nombre'],
              'precio': (doc['precio'] as num).toDouble(),
              'stock': doc['stock'] ?? 0,
            };
          }).toList();
    });

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Seleccionar Bebidas"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Solo mostrar el título si no viene desde productos_page
                if (!widget.desdeProductosPage) ...[
                  const Text(
                    '¿Qué bebidas deseas?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                ],

                ElevatedButton.icon(
                  onPressed: ,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar nueva bebida'),
                ),

                const SizedBox(height: 10),

                // Mostrar lista de bebidas solo si deseaBebidas es true
                if (deseaBebidas)
                  ...bebidas.map((bebida) {
                    final nombre = bebida['nombre'];
                    final precio = bebida['precio'];
                    final cantidad = cantidades[nombre] ?? 0;

                    return Card(
                      child: ListTile(
                        title: Text(
                          '$nombre - \$${precio.toStringAsFixed(2)} (Stock: ${bebida['stock']})',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  if (cantidad > 0)
                                    cantidades[nombre] = cantidad - 1;
                                });
                              },
                            ),
                            Text('$cantidad'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  if (cantidad < bebida['stock']) {
                                    cantidades[nombre] = cantidad + 1;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                const SizedBox(height: 10),

                // Mostrar total y botón finalizar solo si NO viene desde productos_page
                if (deseaBebidas && !widget.desdeProductosPage) ...[
                  Text('Total bebidas: \$${total.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final seleccionadas =
                          bebidas
                              .where(
                                (bebida) =>
                                    (cantidades[bebida['nombre']] ?? 0) > 0,
                              )
                              .map(
                                (bebida) => {
                                  'id': bebida['id'],
                                  'nombre': bebida['nombre'],
                                  'precio': bebida['precio'],
                                  'cantidad': cantidades[bebida['nombre']]!,
                                },
                              )
                              .toList();

                      for (var bebida in seleccionadas) {
                        final docRef = _firestore
                            .collection('bebidas')
                            .doc(bebida['id']);
                        await docRef.update({
                          'stock': FieldValue.increment(-bebida['cantidad']),
                        });
                      }

                      Navigator.pop(context, seleccionadas);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Finalizar pedido'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }
}
