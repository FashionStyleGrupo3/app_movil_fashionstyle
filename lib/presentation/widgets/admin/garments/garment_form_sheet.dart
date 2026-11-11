// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/constants/payment_constants.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/payment/bank_account_config.dart';
import 'package:fashion_style_mobile/data/models/payment/parallel_payment_control.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_detail.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_model.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sales_summary.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/price_info.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_filters.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/invoice_pdf_service.dart';
import 'package:fashion_style_mobile/data/services/payment_config_service.dart';
import 'package:fashion_style_mobile/data/services/pos_sale_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_garments_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_pos_sales_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/promotions_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/pos/new_pos_sale_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

// Modal de Creación / Edición de Prenda
class ModalFormularioPrenda extends StatefulWidget {
  final Product? prenda;
  final List<Category> categorias;
  final List<Catalog> catalogos;
  final VoidCallback onGuardado;

  const ModalFormularioPrenda({
    this.prenda,
    required this.categorias,
    required this.catalogos,
    required this.onGuardado,
  });

  @override
  State<ModalFormularioPrenda> createState() => _ModalFormularioPrendaState();
}

class _ModalFormularioPrendaState extends State<ModalFormularioPrenda> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _colorCtrl = TextEditingController();

  int? _categoriaId;
  int? _catalogoId;
  bool _guardando = false;
  List<Map<String, dynamic>> _variantes = [];

  @override
  void initState() {
    super.initState();
    if (widget.prenda != null) {
      final p = widget.prenda!;
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion;
      _colorCtrl.text = p.original['color']?.toString() ?? 'Estándar';
      _categoriaId = p.categoria?.idCategoria;
      _catalogoId = p.catalogo?.idCatalogo;
      _variantes = p.variantes.map((v) => {
        'id_variante': v.idVariante,
        'talla': v.talla,
        'sku': v.sku,
        'precio': v.precioVenta,
        'stock': v.stock,
      }).toList();
    } else {
      _variantes = [
        {'talla': 'S', 'sku': '', 'precio': 50000.0, 'stock': 5},
        {'talla': 'M', 'sku': '', 'precio': 50000.0, 'stock': 5},
      ];
    }
  }

  void _agregarVariante() {
    setState(() {
      _variantes.add({'talla': 'L', 'sku': '', 'precio': 50000.0, 'stock': 5});
    });
  }

  Future<void> _guardarPrenda() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre de la prenda es obligatorio')));
      return;
    }

    setState(() => _guardando = true);
    try {
      final payload = {
        'nombre': nombre,
        'descripcion': _descCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'publicado': widget.prenda?.publicado ?? false,
        'categoria_id': _categoriaId,
        'catalogo_id': _catalogoId,
        'variantes': _variantes,
      };

      if (widget.prenda != null) {
        await ApiClient.instance.dio.put('/productos/${widget.prenda!.idProducto}', data: payload);
      } else {
        await ApiClient.instance.dio.post('/productos', data: payload);
      }

      widget.onGuardado();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar prenda: $e'), backgroundColor: FashionColors.peligro),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.prenda != null ? 'Editar Prenda' : 'Nueva Prenda de Catálogo',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de la prenda *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción detallada', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _colorCtrl,
              decoration: const InputDecoration(labelText: 'Color / Gama de tono', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int?>(
              initialValue: _categoriaId,
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                ...widget.categorias.map((c) => DropdownMenuItem(value: c.idCategoria, child: Text(c.nombre))),
              ],
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int?>(
              initialValue: _catalogoId,
              decoration: const InputDecoration(labelText: 'Colección / Catálogo', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin colección')),
                ...widget.catalogos.map((c) => DropdownMenuItem(value: c.idCatalogo, child: Text(c.nombre))),
              ],
              onChanged: (v) => setState(() => _catalogoId = v),
            ),
            const SizedBox(height: 20),

            // TALLAS Y VARIANTES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tallas y Precios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton.icon(
                  onPressed: _agregarVariante,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar talla'),
                ),
              ],
            ),
            ..._variantes.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: FashionColors.fondoClaro, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: item['talla']?.toString(),
                        decoration: const InputDecoration(labelText: 'Talla', border: OutlineInputBorder()),
                        onChanged: (val) => item['talla'] = val,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: item['precio']?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio (COP)', border: OutlineInputBorder()),
                        onChanged: (val) => item['precio'] = double.tryParse(val) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        initialValue: item['stock']?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                        onChanged: (val) => item['stock'] = int.tryParse(val) ?? 0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: FashionColors.peligro),
                      onPressed: () => setState(() => _variantes.removeAt(idx)),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.negroElegante,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _guardando ? null : _guardarPrenda,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.prenda != null ? 'Actualizar Prenda' : 'Crear Prenda', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. VENTAS POS / MOSTRADOR (VistaVentasPOS.vue)
// ============================================================================
