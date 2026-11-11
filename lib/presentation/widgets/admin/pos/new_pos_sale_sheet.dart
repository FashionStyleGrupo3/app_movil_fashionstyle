// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/constants/payment_constants.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/services/invoice_pdf_service.dart';
import 'package:fashion_style_mobile/data/services/pos_sale_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Modal de Registro de Venta Mostrador (POS)
class ModalNuevaVentaPos extends StatefulWidget {
  final VoidCallback onCobrada;

  const ModalNuevaVentaPos({super.key, required this.onCobrada});

  @override
  State<ModalNuevaVentaPos> createState() => _ModalNuevaVentaPosState();
}

class _ModalNuevaVentaPosState extends State<ModalNuevaVentaPos> {
  List<Product> _productos = [];
  bool _cargandoProds = true;
  String _busqueda = '';

  final List<Map<String, dynamic>> _bolsa = [];
  String _medioPago = 'efectivo';
  final TextEditingController _nombreCtrl = TextEditingController(text: 'Consumidor Final');
  final TextEditingController _docCtrl = TextEditingController(text: '222222222222');
  final TextEditingController _telCtrl = TextEditingController();
  bool _procesandoCobro = false;

  @override
  void initState() {
    super.initState();
    _cargarPrendas();
  }

  Future<void> _cargarPrendas() async {
    try {
      final p = await ProductService.instance.obtenerProductos();
      if (mounted) setState(() => _productos = p);
    } catch (_) {}
    if (mounted) setState(() => _cargandoProds = false);
  }

  double get _totalBolsa {
    return _bolsa.fold(0.0, (sum, it) => sum + (it['precio'] * it['cantidad']));
  }

  void _agregarPrenda(Product p, ProductVariant v) {
    if (v.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta talla no tiene stock disponible')));
      return;
    }

    setState(() {
      final idx = _bolsa.indexWhere((it) => it['variante_id'] == v.idVariante);
      if (idx != -1) {
        if (_bolsa[idx]['cantidad'] < v.stock) {
          _bolsa[idx]['cantidad'] += 1;
        }
      } else {
        _bolsa.add({
          'variante_id': v.idVariante,
          'nombre': p.nombre,
          'talla': v.talla,
          'sku': v.sku,
          'precio': v.precioVenta > 0 ? v.precioVenta : p.precioMinimo,
          'cantidad': 1,
          'max_stock': v.stock,
        });
      }
    });
  }

  Future<void> _cobrarVenta() async {
    if (_bolsa.isEmpty) return;

    setState(() => _procesandoCobro = true);
    try {
      final payload = {
        'medio_pago': _medioPago,
        'cliente_nombre': _nombreCtrl.text.trim(),
        'cliente_documento': _docCtrl.text.trim(),
        'cliente_telefono': _telCtrl.text.trim(),
        'items': _bolsa.map((it) => {
          'variante_id': it['variante_id'],
          'cantidad': it['cantidad'],
          'precio_unitario': it['precio'],
        }).toList(),
      };

      final venta = await PosSaleService.instance.registrarVenta(
        items: (payload['items'] as List).cast<Map<String, dynamic>>(),
        medioPago: _medioPago,
        clienteNombre: _nombreCtrl.text.trim(),
        clienteDocumento: _docCtrl.text.trim(),
      );
      widget.onCobrada();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venta POS registrada: ${venta.codigo}')),
        );
        InvoicePdfGenerator.generarYCompartirReciboPos(venta);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo procesar la venta en el punto de venta.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesandoCobro = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
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
                'Caja Mostrador (POS)',
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),

          // Buscador de prendas
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar prendas para agregar a la venta...',
              prefixIcon: Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => setState(() => _busqueda = val),
          ),
          const SizedBox(height: 8),

          // Catálogo rápido de selección
          SizedBox(
            height: 120,
            child: _cargandoProds
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final p = _productos[index];
                      if (_busqueda.isNotEmpty && !p.nombre.toLowerCase().contains(_busqueda.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(border: Border.all(color: FashionColors.grisBorde), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            Text(CurrencyFormatter.formatearCOP(p.precioMinimo), style: const TextStyle(fontSize: 10, color: FashionColors.rosaCorporativo, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Wrap(
                              spacing: 2,
                              children: p.variantes.map((v) => InkWell(
                                onTap: () => _agregarPrenda(p, v),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: v.stock > 0 ? FashionColors.negroElegante : FashionColors.fondoClaro,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    v.talla,
                                    style: TextStyle(fontSize: 9, color: v.stock > 0 ? Colors.white : FashionColors.textoMuted, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 10),
          const Divider(),

          // Bolsa de mostrador
          Expanded(
            child: _bolsa.isEmpty
                ? const Center(child: Text('Toca una talla arriba para agregar a la venta de mostrador'))
                : ListView.builder(
                    itemCount: _bolsa.length,
                    itemBuilder: (context, index) {
                      final it = _bolsa[index];
                      return ListTile(
                        dense: true,
                        title: Text('${it['nombre']} (${it['talla']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text('${CurrencyFormatter.formatearCOP(it['precio'])} x${it['cantidad']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                setState(() {
                                  if (it['cantidad'] > 1) {
                                    it['cantidad'] -= 1;
                                  } else {
                                    _bolsa.removeAt(index);
                                  }
                                });
                              },
                            ),
                            Text('${it['cantidad']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                if (it['cantidad'] < it['max_stock']) {
                                  setState(() => it['cantidad'] += 1);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Medio de pago y total
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _medioPago,
                  decoration: const InputDecoration(labelText: 'Medio de pago', border: OutlineInputBorder()),
                  items: mediosPagoPos.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _medioPago = v ?? 'efectivo'),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total:', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.inkSecondary)),
                  Text(
                    CurrencyFormatter.formatearCOP(_totalBolsa),
                    style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.brandAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _procesandoCobro || _bolsa.isEmpty ? null : _cobrarVenta,
              icon: _procesandoCobro ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
              label: Text(
                _procesandoCobro ? 'Procesando...' : 'Cobrar e Imprimir Comprobante',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
