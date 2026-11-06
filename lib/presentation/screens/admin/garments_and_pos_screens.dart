// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/invoice_pdf_generator.dart';
import '../../../core/validators/garment_and_field_validators.dart';
import '../../../data/models/product_models.dart';
import '../../../data/services/pos_and_payment_service.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/promotion_service.dart';
import '../../layouts/admin_shell_layout.dart';

// ============================================================================
// 1. GESTIÓN DE PRENDAS (VistaGestionPrendas.vue + useGestionPrendas.js)
// ============================================================================

class AdminGarmentsScreen extends ConsumerStatefulWidget {
  const AdminGarmentsScreen({super.key});

  @override
  ConsumerState<AdminGarmentsScreen> createState() => _AdminGarmentsScreenState();
}

class _AdminGarmentsScreenState extends ConsumerState<AdminGarmentsScreen> {
  bool _cargando = true;
  String? _error;
  List<Product> _productos = [];
  List<Category> _categorias = [];
  List<Catalog> _catalogos = [];
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        ProductService.instance.obtenerProductos(const ProductFilters(esPersonal: true)),
        ProductService.instance.obtenerCategorias(),
        ProductService.instance.obtenerCatalogos(),
      ]);

      if (mounted) {
        setState(() {
          _productos = resultados[0] as List<Product>;
          _categorias = resultados[1] as List<Category>;
          _catalogos = resultados[2] as List<Catalog>;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar prendas: $e';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _togglePublicado(Product p) async {
    try {
      await ProductService.instance.togglePublicado(p.idProducto);
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!p.publicado ? 'Prenda "${p.nombre}" publicada en la tienda' : 'Prenda "${p.nombre}" ocultada de la tienda'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al alternar publicación: $e'), backgroundColor: FashionColors.peligro),
        );
      }
    }
  }

  Future<void> _toggleActivo(Product p, bool nuevoValor) async {
    try {
      await ApiClient.instance.dio.patch('/productos/${p.idProducto}/toggle-activo');
      _cargarDatos();
    } catch (_) {
      try {
        await ApiClient.instance.dio.put('/productos/${p.idProducto}', data: {'activo': nuevoValor});
        _cargarDatos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo cambiar el estado: $e'), backgroundColor: FashionColors.peligro),
          );
        }
      }
    }
  }

  Future<void> _eliminarPrenda(Product p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar prenda'),
        content: Text('¿Deseas eliminar definitivamente "${p.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.peligro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiClient.instance.dio.delete('/productos/${p.idProducto}');
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenda eliminada con éxito')),
        );
      }
    } catch (e) {
      String mensaje = 'No se pudo eliminar la prenda.';
      if (e is DioException && e.response?.statusCode == 409) {
        mensaje = 'No se puede eliminar esta prenda porque ya tiene ventas registradas. Puedes desactivarla para retirarla del catálogo.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: FashionColors.peligro, duration: const Duration(seconds: 4)),
        );
      }
    }
  }

  void _abrirModalPromociones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ModalPromocionesSheet(productos: _productos),
    );
  }

  void _abrirFormularioPrenda([Product? prendaEditar]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ModalFormularioPrenda(
        prenda: prendaEditar,
        categorias: _categorias,
        catalogos: _catalogos,
        onGuardado: _cargarDatos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Product> filtrados = List.from(_productos);
    if (_busqueda.trim().isNotEmpty) {
      final q = _busqueda.trim().toLowerCase();
      filtrados = filtrados.where((p) => p.nombre.toLowerCase().contains(q) || p.descripcion.toLowerCase().contains(q)).toList();
    }

    return AdminShellLayout(
      currentPath: '/admin/prendas',
      child: Column(
        children: [
          // BARRA SUPERIOR CON BOTONES DE ACCIÓN
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar prendas por nombre...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setState(() => _busqueda = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FashionColors.rosaCorporativo,
                        side: const BorderSide(color: FashionColors.rosaCorporativo),
                      ),
                      onPressed: _abrirModalPromociones,
                      icon: const Icon(Icons.local_offer_outlined, size: 16),
                      label: const Text('Promociones', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.negroElegante,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _abrirFormularioPrenda(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nueva', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LISTA DE PRENDAS
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
                : _error != null
                    ? Center(child: Text(_error!))
                    : filtrados.isEmpty
                        ? const Center(child: Text('No hay prendas registradas con ese criterio'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final p = filtrados[index];
                              return Card(
                                elevation: 0.5,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: FashionColors.grisBorde),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 60,
                                          height: 72,
                                          child: p.primeraImagenUrl.isNotEmpty
                                              ? CachedNetworkImage(imageUrl: p.primeraImagenUrl, fit: BoxFit.cover)
                                              : Container(color: FashionColors.fondoClaro, child: const Icon(Icons.checkroom)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${p.categoria?.nombre ?? "Sin categoría"} · ${p.catalogo?.nombre ?? "Sin colección"}',
                                              style: const TextStyle(fontSize: 11, color: FashionColors.textoMuted),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: p.publicado ? const Color(0xFFDEF7EC) : const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: p.publicado ? const Color(0xFF31C48D) : const Color(0xFFD1D5DB),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    p.publicado ? 'Publicado' : 'Oculto',
                                                    style: TextStyle(
                                                      color: p.publicado ? const Color(0xFF03543F) : const Color(0xFF6B7280),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () => _togglePublicado(p),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        p.publicado ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                                        size: 14,
                                                        color: p.publicado ? FashionColors.verdeExito : FashionColors.textoMuted,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        p.publicado ? 'Ocultar' : 'Publicar',
                                                        style: const TextStyle(fontSize: 10, decoration: TextDecoration.underline),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  CurrencyFormatter.formatearCOP(p.precioMinimo),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FashionColors.textoOscuro),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Stock: ${p.stockTotal} uds',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: p.stockTotal <= 0 ? FashionColors.peligro : FashionColors.verdeExito,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Switch(
                                            value: p.activo,
                                            activeColor: FashionColors.rosaCorporativo,
                                            onChanged: (val) => _toggleActivo(p, val),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18),
                                                onPressed: () => _abrirFormularioPrenda(p),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: FashionColors.peligro),
                                                onPressed: () => _eliminarPrenda(p),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
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

// Modal de Promociones
class _ModalPromocionesSheet extends StatefulWidget {
  final List<Product> productos;

  const _ModalPromocionesSheet({required this.productos});

  @override
  State<_ModalPromocionesSheet> createState() => _ModalPromocionesSheetState();
}

class _ModalPromocionesSheetState extends State<_ModalPromocionesSheet> {
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
                  value: tipo,
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
                  value: productoId,
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
                      SnackBar(content: Text('Error al crear promoción: $e'), backgroundColor: FashionColors.peligro),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Campañas y Promociones',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                onPressed: _crearPromoModal,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva Promo'),
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

// Modal de Creación / Edición de Prenda
class _ModalFormularioPrenda extends StatefulWidget {
  final Product? prenda;
  final List<Category> categorias;
  final List<Catalog> catalogos;
  final VoidCallback onGuardado;

  const _ModalFormularioPrenda({
    this.prenda,
    required this.categorias,
    required this.catalogos,
    required this.onGuardado,
  });

  @override
  State<_ModalFormularioPrenda> createState() => _ModalFormularioPrendaState();
}

class _ModalFormularioPrendaState extends State<_ModalFormularioPrenda> {
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
              value: _categoriaId,
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                ...widget.categorias.map((c) => DropdownMenuItem(value: c.idCategoria, child: Text(c.nombre))),
              ],
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int?>(
              value: _catalogoId,
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

class AdminPosSalesScreen extends ConsumerStatefulWidget {
  const AdminPosSalesScreen({super.key});

  @override
  ConsumerState<AdminPosSalesScreen> createState() => _AdminPosSalesScreenState();
}

class _AdminPosSalesScreenState extends ConsumerState<AdminPosSalesScreen> {
  bool _cargando = true;
  String? _error;
  List<PosSaleModel> _ventas = [];
  Map<String, dynamic> _resumen = {};
  String _filtroMedioPago = '';
  int _pagina = 1;
  int _totalPaginas = 1;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        PosSaleService.instance.obtenerResumenVentas(),
        PosSaleService.instance.listarVentas(pagina: _pagina, medioPago: _filtroMedioPago),
      ]);

      if (mounted) {
        final pag = resultados[1] as PaginatedResponse<PosSaleModel>;
        setState(() {
          _resumen = resultados[0] as Map<String, dynamic>;
          _ventas = pag.lista;
          _totalPaginas = pag.totalPaginas;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar ventas POS: $e';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cancelarVenta(PosSaleModel v) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular venta POS'),
        content: Text('¿Deseas cancelar la venta "${v.codigo}"? Las unidades volverán al inventario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.peligro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anular Venta', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await PosSaleService.instance.cancelarVenta(v.id);
      _cargarVentas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta anulada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al anular: $e'), backgroundColor: FashionColors.peligro),
        );
      }
    }
  }

  void _abrirModalNuevaVenta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ModalNuevaVentaPos(onCobrada: _cargarVentas),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/ventas',
      child: Column(
        children: [
          // RESUMEN FINANCIERO SUPERIOR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _cardResumen('Ventas Hoy', '${_resumen['ventasHoy'] ?? 0}', FashionColors.rosaCorporativo),
                    const SizedBox(width: 8),
                    _cardResumen('Ingreso Hoy', CurrencyFormatter.formatearCOP(JsonParser.toDouble(_resumen['montoHoy'])), FashionColors.verdeExito),
                    const SizedBox(width: 8),
                    _cardResumen('Caja Activa', CurrencyFormatter.formatearCOP(JsonParser.toDouble(_resumen['montoActivas'])), const Color(0xFF2563EB)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chipMedio('', 'Todos'),
                            ...mediosPagoPos.entries.map((e) => _chipMedio(e.key, e.value)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                      onPressed: _abrirModalNuevaVenta,
                      icon: const Icon(Icons.point_of_sale, size: 16),
                      label: const Text('Nueva Venta'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LISTA DE VENTAS REGISTRADAS
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
                : _error != null
                    ? Center(child: Text(_error!))
                    : _ventas.isEmpty
                        ? const Center(child: Text('No hay ventas registradas'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _ventas.length,
                            itemBuilder: (context, index) {
                              final v = _ventas[index];
                              final esActiva = v.estado == 'completada' || v.estado == 'activa';

                              return Card(
                                elevation: 0.5,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: FashionColors.grisBorde),
                                ),
                                child: ExpansionTile(
                                  title: Row(
                                    children: [
                                      Text(v.codigo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: esActiva ? FashionColors.verdeExito.withOpacity(0.12) : FashionColors.peligro.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          v.medioPago.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: esActiva ? FashionColors.verdeExito : FashionColors.peligro,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        CurrencyFormatter.formatearCOP(v.total),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${v.fecha ?? ''} · Cliente: ${v.clienteNombre.isNotEmpty ? v.clienteNombre : "Consumidor"}',
                                    style: const TextStyle(fontSize: 11, color: FashionColors.textoMuted),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  children: [
                                    const Divider(),
                                    ...v.detalles.map((d) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${d.nombre} (${d.talla}) x${d.cantidad}', style: const TextStyle(fontSize: 12)),
                                          Text(CurrencyFormatter.formatearCOP(d.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: FashionColors.fondoClaro, foregroundColor: FashionColors.textoOscuro),
                                          onPressed: () => InvoicePdfGenerator.generarYCompartirReciboPos(v),
                                          icon: const Icon(Icons.print, size: 16),
                                          label: const Text('Imprimir Recibo', style: TextStyle(fontSize: 12)),
                                        ),
                                        const Spacer(),
                                        if (esActiva)
                                          TextButton(
                                            style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
                                            onPressed: () => _cancelarVenta(v),
                                            child: const Text('Anular Venta', style: TextStyle(fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _cardResumen(String label, String valor, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: col.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valor, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: FashionColors.textoMuted)),
          ],
        ),
      ),
    );
  }

  Widget _chipMedio(String val, String label) {
    final sel = _filtroMedioPago == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 10, color: sel ? Colors.white : FashionColors.textoOscuro)),
        selected: sel,
        selectedColor: FashionColors.negroElegante,
        onSelected: (_) {
          setState(() => _filtroMedioPago = val);
          _cargarVentas();
        },
      ),
    );
  }
}

// Modal de Registro de Venta Mostrador (POS)
class _ModalNuevaVentaPos extends StatefulWidget {
  final VoidCallback onCobrada;

  const _ModalNuevaVentaPos({required this.onCobrada});

  @override
  State<_ModalNuevaVentaPos> createState() => _ModalNuevaVentaPosState();
}

class _ModalNuevaVentaPosState extends State<_ModalNuevaVentaPos> {
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
          SnackBar(content: Text('Error al cobrar venta: $e'), backgroundColor: FashionColors.peligro),
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Caja Mostrador (POS)',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
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
                  value: _medioPago,
                  decoration: const InputDecoration(labelText: 'Medio de pago', border: OutlineInputBorder()),
                  items: mediosPagoPos.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _medioPago = v ?? 'efectivo'),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 11, color: FashionColors.textoMuted)),
                  Text(
                    CurrencyFormatter.formatearCOP(_totalBolsa),
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.textoOscuro),
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
                backgroundColor: FashionColors.negroElegante,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _procesandoCobro || _bolsa.isEmpty ? null : _cobrarVenta,
              icon: _procesandoCobro ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
              label: Text(
                _procesandoCobro ? 'Procesando...' : 'Cobrar e Imprimir Comprobante',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
