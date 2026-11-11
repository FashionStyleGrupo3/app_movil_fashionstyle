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
import 'package:fashion_style_mobile/presentation/screens/admin/admin_pos_sales_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/garment_form_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/promotions_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/pos/new_pos_sale_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

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
      builder: (ctx) => ModalPromocionesSheet(productos: _productos),
    );
  }

  void _abrirFormularioPrenda([Product? prendaEditar]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ModalFormularioPrenda(
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
                                            activeThumbColor: FashionColors.rosaCorporativo,
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
