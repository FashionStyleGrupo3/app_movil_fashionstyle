// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_filters.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/garment_form_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/promotions_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
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
  String _filtroEstado = 'todas';

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
          _error = ApiClient.obtenerMensajeError(e, 'No se pudieron cargar las prendas del catálogo.');
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
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible cambiar la visibilidad de la prenda.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    }
  }

  Future<void> _toggleActivo(Product p, bool nuevoValor) async {
    try {
      await ProductService.instance.toggleActivo(p.idProducto);
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nuevoValor ? 'Prenda "${p.nombre}" activada' : 'Prenda "${p.nombre}" desactivada'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible cambiar el estado de la prenda.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
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
      String mensaje = ApiClient.obtenerMensajeError(e, 'No se pudo eliminar la prenda.');
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

  Future<void> _duplicarPrenda(Product p) async {
    try {
      await ApiClient.instance.dio.post('/productos/${p.idProducto}/duplicar');
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prenda "${p.nombre}" duplicada como borrador')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible duplicar la prenda.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    }
  }

  void _abrirModalPromociones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalPromocionesSheet(productos: _productos),
    );
  }

  Future<void> _abrirFormularioPrenda([Product? prendaEditar]) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalFormularioPrenda(
        prenda: prendaEditar,
        categorias: _categorias,
        catalogos: _catalogos,
        onGuardado: _cargarDatos,
      ),
    );

    if (guardado == true && mounted) {
      _cargarDatos();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FashionColors.statusSuccess.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: FashionColors.statusSuccess, size: 24),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  prendaEditar != null ? '¡Prenda actualizada!' : '¡Prenda creada con éxito!',
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            prendaEditar != null
                ? 'Los cambios en la prenda y sus variantes han sido guardados correctamente.'
                : 'La prenda y sus variantes han sido creadas exitosamente en el catálogo.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkSecondary),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.inkPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  Widget _chipFiltro(String valor, String etiqueta) {
    final seleccionado = _filtroEstado == valor;
    return ChoiceChip(
      label: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 11,
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          color: seleccionado ? Colors.white : FashionColors.textoOscuro,
        ),
      ),
      selected: seleccionado,
      selectedColor: FashionColors.negroElegante,
      backgroundColor: FashionColors.fondoClaro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) => setState(() => _filtroEstado = valor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalActivas = _productos.where((p) => p.activo).length;
    final totalInactivas = _productos.where((p) => !p.activo).length;
    final totalOcultas = _productos.where((p) => !p.publicado).length;

    List<Product> filtrados = List.from(_productos);
    if (_filtroEstado == 'activas') {
      filtrados = filtrados.where((p) => p.activo).toList();
    } else if (_filtroEstado == 'inactivas') {
      filtrados = filtrados.where((p) => !p.activo).toList();
    } else if (_filtroEstado == 'ocultas') {
      filtrados = filtrados.where((p) => !p.publicado).toList();
    }

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
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar prendas por nombre...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _busqueda = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FashionColors.inkPrimary,
                          side: const BorderSide(color: FashionColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        onPressed: _abrirModalPromociones,
                        icon: const Icon(Icons.local_offer_outlined, size: 16),
                        label: Text('Promociones', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FashionColors.brandAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        onPressed: () => _abrirFormularioPrenda(),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('Nueva Prenda', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chipFiltro('todas', 'Todas (${_productos.length})'),
                      const SizedBox(width: 6),
                      _chipFiltro('activas', 'Activas ($totalActivas)'),
                      const SizedBox(width: 6),
                      _chipFiltro('inactivas', 'Inactivas ($totalInactivas)'),
                      const SizedBox(width: 6),
                      _chipFiltro('ocultas', 'Ocultas ($totalOcultas)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LISTA DE PRENDAS
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.brandAccent))
                : _error != null
                    ? Center(child: Text(_error!))
                    : filtrados.isEmpty
                        ? const Center(
                            child: AtelierEmptyStateIllustration(
                              type: AtelierEmptyStateType.emptySearch,
                              title: 'Sin prendas coincidentes',
                              subtitle: 'No hay prendas registradas con ese criterio.',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final p = filtrados[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: FashionColors.borderSubtle),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 54,
                                          height: 72,
                                          child: p.primeraImagenUrl.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: p.primeraImagenUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => Container(color: FashionColors.surfaceMuted, child: const Icon(Icons.checkroom, color: FashionColors.inkPrimary)),
                                                )
                                              : Container(color: FashionColors.surfaceMuted, child: const Icon(Icons.checkroom, color: FashionColors.inkPrimary)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.nombre, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: FashionColors.inkPrimary)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${p.categoria?.nombre ?? "Sin categoría"} · ${p.catalogo?.nombre ?? "Sin colección"}',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                // Estado Activa / Inactiva
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: p.activo ? FashionColors.statusSuccess.withValues(alpha: 0.12) : FashionColors.statusDanger.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: p.activo ? FashionColors.statusSuccess.withValues(alpha: 0.3) : FashionColors.statusDanger.withValues(alpha: 0.3),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    p.activo ? 'Activa' : 'Inactiva',
                                                    style: TextStyle(
                                                      color: p.activo ? FashionColors.statusSuccess : FashionColors.statusDanger,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                // Estado En tienda / Oculto
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: p.publicado ? FashionColors.statusSuccess.withValues(alpha: 0.12) : FashionColors.surfaceMuted,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: p.publicado ? FashionColors.statusSuccess.withValues(alpha: 0.3) : FashionColors.borderSubtle,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    p.publicado ? 'En tienda' : 'Oculto tienda',
                                                    style: TextStyle(
                                                      color: p.publicado ? FashionColors.statusSuccess : FashionColors.inkSecondary,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => _togglePublicado(p),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        p.publicado ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                                        size: 14,
                                                        color: p.publicado ? FashionColors.statusSuccess : FashionColors.inkSecondary,
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
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  CurrencyFormatter.formatearCOP(p.precioMinimo),
                                                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 13, color: FashionColors.inkPrimary),
                                                ),
                                                Text(
                                                  'Stock: ${p.stockTotal} uds',
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: p.stockTotal <= 0 ? FashionColors.statusDanger : FashionColors.statusSuccess,
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
                                            activeThumbColor: FashionColors.verdeExito,
                                            activeTrackColor: FashionColors.verdeExito.withValues(alpha: 0.3),
                                            inactiveThumbColor: FashionColors.textoMuted,
                                            onChanged: (val) => _toggleActivo(p, val),
                                          ),
                                          Text(
                                            p.activo ? 'Activa' : 'Inactiva',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: p.activo ? FashionColors.verdeExito : FashionColors.textoMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.copy_outlined, size: 17),
                                                tooltip: 'Duplicar prenda',
                                                onPressed: () => _duplicarPrenda(p),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18),
                                                tooltip: 'Editar prenda',
                                                onPressed: () => _abrirFormularioPrenda(p),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: FashionColors.peligro),
                                                tooltip: 'Eliminar prenda',
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
