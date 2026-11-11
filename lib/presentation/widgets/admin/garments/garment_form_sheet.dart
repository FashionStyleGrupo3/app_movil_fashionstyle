// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:google_fonts/google_fonts.dart';

// Modal de Creación / Edición de Prenda
class ModalFormularioPrenda extends StatefulWidget {
  final Product? prenda;
  final List<Category> categorias;
  final List<Catalog> catalogos;
  final VoidCallback onGuardado;

  const ModalFormularioPrenda({super.key, 
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
  late List<Category> _categoriasLocales;
  late List<Catalog> _catalogosLocales;

  @override
  void initState() {
    super.initState();
    _categoriasLocales = List.from(widget.categorias);
    _catalogosLocales = List.from(widget.catalogos);
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

  Future<void> _crearCategoriaModal() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de categoría', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.brandAccent),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Crear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      try {
        final resp = await ApiClient.instance.dio.post('/categorias', data: {'nombre': res});
        final data = ApiResponseParser.extractData(resp);
        final nueva = Category.fromJson(data is Map<String, dynamic> ? data : {'id': DateTime.now().millisecondsSinceEpoch, 'nombre': res, 'activo': true});
        setState(() {
          _categoriasLocales.add(nueva);
          _categoriaId = nueva.idCategoria;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Categoría "$res" creada con éxito')));
      } catch (_) {
        final nueva = Category(idCategoria: DateTime.now().millisecondsSinceEpoch, nombre: res, descripcion: '', activo: true);
        setState(() {
          _categoriasLocales.add(nueva);
          _categoriaId = nueva.idCategoria;
        });
      }
    }
  }

  Future<void> _crearColeccionModal() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Colección'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de colección', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.brandAccent),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Crear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      try {
        final resp = await ApiClient.instance.dio.post('/catalogos', data: {'nombre': res});
        final data = ApiResponseParser.extractData(resp);
        final nuevo = Catalog.fromJson(data is Map<String, dynamic> ? data : {'id': DateTime.now().millisecondsSinceEpoch, 'nombre': res, 'activo': true});
        setState(() {
          _catalogosLocales.add(nuevo);
          _catalogoId = nuevo.idCatalogo;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Colección "$res" creada con éxito')));
      } catch (_) {
        final nuevo = Catalog(idCatalogo: DateTime.now().millisecondsSinceEpoch, nombre: res, descripcion: '', activo: true);
        setState(() {
          _catalogosLocales.add(nuevo);
          _catalogoId = nuevo.idCatalogo;
        });
      }
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
        'activo': widget.prenda?.activo ?? true,
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
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible guardar la prenda. Verifica los datos ingresados.')),
            backgroundColor: FashionColors.peligro,
          ),
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
      decoration: const BoxDecoration(
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
            Text(
              widget.prenda != null ? 'Editar Prenda' : 'Nueva Prenda de Catálogo',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
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

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: _categoriaId,
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                      ..._categoriasLocales.map((c) => DropdownMenuItem(value: c.idCategoria, child: Text(c.nombre, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _categoriaId = v),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '+ Categoría',
                  icon: const Icon(Icons.add_circle_outline, color: FashionColors.brandAccent, size: 26),
                  onPressed: _crearCategoriaModal,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: _catalogoId,
                    decoration: const InputDecoration(labelText: 'Colección / Catálogo', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin colección')),
                      ..._catalogosLocales.map((c) => DropdownMenuItem(value: c.idCatalogo, child: Text(c.nombre, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _catalogoId = v),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '+ Colección',
                  icon: const Icon(Icons.add_circle_outline, color: FashionColors.brandAccent, size: 26),
                  onPressed: _crearColeccionModal,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TALLAS Y VARIANTES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Tallas y Precios',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(color: FashionColors.fondoClaro, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: TextFormField(
                        initialValue: item['talla']?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Talla',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => item['talla'] = val,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextFormField(
                        initialValue: item['precio']?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => item['precio'] = double.tryParse(val) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 52,
                      child: TextFormField(
                        initialValue: item['stock']?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => item['stock'] = int.tryParse(val) ?? 0,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
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
                backgroundColor: FashionColors.brandAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _guardando ? null : _guardarPrenda,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.prenda != null ? 'Actualizar Prenda' : 'Crear Prenda', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
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
