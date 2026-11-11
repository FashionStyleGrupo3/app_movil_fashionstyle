// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Modal de Promociones
class ModalPromocionesSheet extends StatefulWidget {
  final List<Product> productos;

  const ModalPromocionesSheet({super.key, required this.productos});

  @override
  State<ModalPromocionesSheet> createState() => _ModalPromocionesSheetState();
}

class _ModalPromocionesSheetState extends State<ModalPromocionesSheet> {
  bool _cargando = true;
  List<Promotion> _promociones = [];

  @override
  void initState() {
    super.initState();
    _cargarPromos();
  }

  Future<void> _cargarPromos() async {
    setState(() => _cargando = true);
    try {
      final promos = await PromotionService.instance.obtenerPromocionesVigentes();
      if (mounted) setState(() => _promociones = promos);
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  void _crearPromoModal() {
    final nombreCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    String tipo = 'porcentaje';
    int? productoId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Nueva Promoción'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'porcentaje', child: Text('Porcentaje (%)')),
                    DropdownMenuItem(value: 'monto', child: Text('Monto fijo (COP)')),
                  ],
                  onChanged: (v) => setDState(() => tipo = v ?? 'porcentaje'),
                ),
                const SizedBox(height: 8),
                TextField(controller: valorCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor del descuento *')),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  initialValue: productoId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Aplicar a producto (opcional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toda la tienda')),
                    ...widget.productos.map((p) => DropdownMenuItem(value: p.idProducto, child: Text(p.nombre, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setDState(() => productoId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante),
              onPressed: () async {
                final nom = nombreCtrl.text.trim();
                final val = double.tryParse(valorCtrl.text) ?? 0;
                if (nom.isEmpty || val <= 0) return;
                if (tipo == 'porcentaje' && val > 90) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El descuento máximo permitido es 90%.'), backgroundColor: FashionColors.peligro),
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  await ApiClient.instance.dio.post('/promociones', data: {
                    'nombre': nom,
                    'tipo': tipo,
                    'valor': val,
                    'producto_id': productoId,
                    'estado': true,
                  });
                  _cargarPromos();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible crear la promoción.')),
                        backgroundColor: FashionColors.peligro,
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: FashionColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Campañas y Promociones',
                style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionColors.brandAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _crearPromoModal,
                icon: const Icon(Icons.add, size: 16),
                label: Text('Nueva Promo', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _promociones.isEmpty
                    ? const Center(child: Text('No hay promociones activas registradas'))
                    : ListView.builder(
                        itemCount: _promociones.length,
                        itemBuilder: (context, index) {
                          final pr = _promociones[index];
                          return Card(
                            elevation: 0.5,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.local_offer, color: FashionColors.rosaCorporativo),
                              title: Text(pr.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${pr.tipo == "porcentaje" ? "${pr.valor}%" : CurrencyFormatter.formatearCOP(pr.valor)} · ${pr.nombreProducto ?? "Toda la tienda"}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: FashionColors.peligro),
                                onPressed: () async {
                                  try {
                                    await ApiClient.instance.dio.delete('/promociones/${pr.id}');
                                    _cargarPromos();
                                  } catch (_) {}
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
