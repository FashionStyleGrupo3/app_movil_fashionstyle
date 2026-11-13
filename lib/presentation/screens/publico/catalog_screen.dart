// @source-mirror: src/views/publico/Vistacatalogo.vue, src/components/escaparate/CuadriculaProductos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/network/change_bus.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/filters_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/product_card.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  final int? categoriaId;
  final int? catalogoId;
  final String? searchQuery;
  final bool? soloFavoritos;

  const CatalogScreen({
    super.key,
    this.categoriaId,
    this.catalogoId,
    this.searchQuery,
    this.soloFavoritos,
  });

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _cargando = true;
  String? _error;

  List<Product> _productos = [];
  List<Category> _categorias = [];
  List<Catalog> _catalogos = [];
  List<Promotion> _promociones = [];

  bool _soloDisponibles = false;
  int _paginaActual = 1;
  final int _porPagina = 8;

  StreamSubscription<DataChangeEvent>? _busSub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.categoriaId != null) {
        ref.read(filtersProvider.notifier).establecerCategoria(widget.categoriaId);
      }
      if (widget.catalogoId != null) {
        ref.read(filtersProvider.notifier).establecerCatalogo(widget.catalogoId);
      }
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        ref.read(filtersProvider.notifier).establecerBusqueda(widget.searchQuery!);
        _searchController.text = widget.searchQuery!;
      }
      if (widget.soloFavoritos != null) {
        ref.read(favoritesProvider.notifier).setSoloFavoritos(widget.soloFavoritos!);
      }
    });

    _cargarCatalogData();
    _iniciarSuscripcionBus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _busSub?.cancel();
    super.dispose();
  }

  void _iniciarSuscripcionBus() {
    _busSub = ChangeBus.instance.stream.listen((evento) {
      const recursos = ['productos', 'categorias', 'catalogos', 'promociones', 'inventarios'];
      if (recursos.contains(evento.recurso)) {
        _recargarSilencioso();
      }
    });
  }

  Future<void> _cargarCatalogData() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        ProductService.instance.obtenerProductos(),
        ProductService.instance.obtenerCategorias(),
        ProductService.instance.obtenerCatalogos(),
        PromotionService.instance.obtenerPromocionesVigentes(),
      ]);

      if (mounted) {
        setState(() {
          _productos = resultados[0] as List<Product>;
          _categorias = {for (var c in resultados[1] as List<Category>) c.idCategoria: c}.values.toList();
          _catalogos = {for (var c in resultados[2] as List<Catalog>) c.idCatalogo: c}.values.toList();
          _promociones = resultados[3] as List<Promotion>;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los productos del catálogo.';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _recargarSilencioso() async {
    try {
      final resultados = await Future.wait([
        ProductService.instance.obtenerProductos(),
        ProductService.instance.obtenerCategorias(),
        ProductService.instance.obtenerCatalogos(),
        PromotionService.instance.obtenerPromocionesVigentes(),
      ]);

      if (mounted) {
        setState(() {
          _productos = resultados[0] as List<Product>;
          _categorias = {for (var c in resultados[1] as List<Category>) c.idCategoria: c}.values.toList();
          _catalogos = {for (var c in resultados[2] as List<Catalog>) c.idCatalogo: c}.values.toList();
          _promociones = resultados[3] as List<Promotion>;
        });
      }
    } catch (_) {}
  }

  void _limpiarTodosLosFiltros() {
    ref.read(filtersProvider.notifier).limpiarFiltros();
    ref.read(favoritesProvider.notifier).setSoloFavoritos(false);
    _searchController.clear();
    setState(() {
      _soloDisponibles = false;
      _paginaActual = 1;
    });
  }

  List<Product> _filtrarYOrdenar(FiltersState filtros, FavoritesState favs) {
    List<Product> filtrados = List.from(_productos);

    // Filtro por categoría
    if (filtros.categoriaId != null) {
      filtrados = filtrados.where((p) => p.categoria?.idCategoria == filtros.categoriaId).toList();
    }

    // Filtro por colección/catálogo
    if (filtros.catalogoId != null) {
      filtrados = filtrados.where((p) => p.catalogo?.idCatalogo == filtros.catalogoId).toList();
    }

    // Filtro por búsqueda textual
    if (filtros.busqueda.trim().isNotEmpty) {
      final q = filtros.busqueda.trim().toLowerCase();
      filtrados = filtrados.where((p) {
        final matchNombre = p.nombre.toLowerCase().contains(q);
        final matchDesc = p.descripcion.toLowerCase().contains(q);
        final matchCat = p.categoria?.nombre.toLowerCase().contains(q) ?? false;
        return matchNombre || matchDesc || matchCat;
      }).toList();
    }

    // Filtro por solo disponibles (con stock)
    if (_soloDisponibles) {
      filtrados = filtrados.where((p) => p.stockTotal > 0).toList();
    }

    // Filtro por favoritos
    if (favs.soloFavoritos) {
      filtrados = filtrados.where((p) => favs.esFavorito(p.idProducto)).toList();
    }

    // Ordenamiento
    switch (filtros.orden) {
      case 'precio-asc':
        filtrados.sort((a, b) => a.precioMinimo.compareTo(b.precioMinimo));
        break;
      case 'precio-desc':
        filtrados.sort((a, b) => b.precioMinimo.compareTo(a.precioMinimo));
        break;
      case 'nombre-az':
        filtrados.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        break;
      case 'recientes':
      default:
        filtrados.sort((a, b) => b.idProducto.compareTo(a.idProducto));
        break;
    }

    return filtrados;
  }

  void _mostrarSelectorOrden(BuildContext context, FiltersState filtros) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: FashionColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final opciones = [
          {'clave': 'recientes', 'label': 'Más recientes'},
          {'clave': 'precio-asc', 'label': 'Menor precio primero'},
          {'clave': 'precio-desc', 'label': 'Mayor precio primero'},
          {'clave': 'nombre-az', 'label': 'Nombre alfabético (A-Z)'},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text(
                    'Ordenar prendas',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: FashionColors.inkPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: FashionColors.borderSubtle, height: 1),
                const SizedBox(height: 8),
                ...opciones.map((op) {
                  final seleccionado = filtros.orden == op['clave'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                    leading: Icon(
                      seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: seleccionado ? FashionColors.brandAccent : FashionColors.inkSecondary,
                    ),
                    title: Text(
                      op['label']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                        color: seleccionado ? FashionColors.inkPrimary : FashionColors.inkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      ref.read(filtersProvider.notifier).establecerOrden(op['clave']!);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtros = ref.watch(filtersProvider);
    final favs = ref.watch(favoritesProvider);

    final productosFiltrados = _filtrarYOrdenar(filtros, favs);
    final totalProductos = productosFiltrados.length;
    final totalPaginas = (totalProductos / _porPagina).ceil().clamp(1, 9999);

    if (_paginaActual > totalPaginas) {
      _paginaActual = totalPaginas;
    }

    final inicio = (_paginaActual - 1) * _porPagina;
    final fin = (inicio + _porPagina).clamp(0, totalProductos);
    final productosPaginados = totalProductos > 0 ? productosFiltrados.sublist(inicio, fin) : <Product>[];

    final categoriaActiva = _categorias.where((c) => c.idCategoria == filtros.categoriaId).firstOrNull;
    final catalogoActivo = _catalogos.where((c) => c.idCatalogo == filtros.catalogoId).firstOrNull;

    final tieneFiltrosActivos = filtros.categoriaId != null ||
        filtros.catalogoId != null ||
        filtros.busqueda.trim().isNotEmpty ||
        favs.soloFavoritos ||
        _soloDisponibles;

    return PublicShellLayout(
      currentIndex: favs.soloFavoritos ? 2 : 1,
      child: RefreshIndicator(
        color: FashionColors.brandAccent,
        backgroundColor: FashionColors.surfaceCard,
        onRefresh: _cargarCatalogData,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // BARRA DE BÚSQUEDA Y CONTROL DE FILTROS SUPERIOR (ESTILO MINERAL NEO-ATELIER)
            SliverToBoxAdapter(
              child: Container(
                color: FashionColors.canvasBackground,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo de búsqueda con estilo Pill en surfaceMuted (#EBEEF3)
                    TextField(
                      controller: _searchController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: FashionColors.inkPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar prendas, estilos, colecciones...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: FashionColors.inkSecondary,
                        ),
                        prefixIcon: const Icon(Icons.search, color: FashionColors.inkSecondary, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: FashionColors.inkSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(filtersProvider.notifier).establecerBusqueda('');
                                  setState(() => _paginaActual = 1);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 18),
                        filled: true,
                        fillColor: FashionColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: FashionColors.brandAccent, width: 1.2),
                        ),
                      ),
                      onChanged: (val) {
                        ref.read(filtersProvider.notifier).establecerBusqueda(val);
                        setState(() => _paginaActual = 1);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Fila de chips de categorías horizontales (#14161F activo, #FFFFFF inactivo)
                    if (_categorias.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: const Text('Todo'),
                                selected: filtros.categoriaId == null,
                                selectedColor: FashionColors.inkPrimary,
                                backgroundColor: FashionColors.surfaceMuted,
                                side: BorderSide(
                                  color: filtros.categoriaId == null ? FashionColors.inkPrimary : FashionColors.borderSubtle,
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: filtros.categoriaId == null ? Colors.white : FashionColors.inkPrimary,
                                ),
                                onSelected: (_) {
                                  ref.read(filtersProvider.notifier).establecerCategoria(null);
                                  setState(() => _paginaActual = 1);
                                },
                              ),
                            ),
                            ..._categorias.map((cat) {
                              final sel = filtros.categoriaId == cat.idCategoria;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(cat.nombre),
                                  selected: sel,
                                  selectedColor: FashionColors.inkPrimary,
                                  backgroundColor: FashionColors.surfaceMuted,
                                  side: BorderSide(
                                    color: sel ? FashionColors.inkPrimary : FashionColors.borderSubtle,
                                  ),
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                    color: sel ? Colors.white : FashionColors.inkPrimary,
                                  ),
                                  onSelected: (val) {
                                    ref.read(filtersProvider.notifier).establecerCategoria(val ? cat.idCategoria : null);
                                    setState(() => _paginaActual = 1);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Barra de estado de filtros y botones de orden / stock
                    Row(
                      children: [
                        Text(
                          favs.soloFavoritos
                              ? 'Mis favoritos ($totalProductos)'
                              : '$totalProductos prenda${totalProductos == 1 ? '' : 's'}',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                        const Spacer(),
                        // Interruptor de solo disponibles
                        FilterChip(
                          label: Text(
                            'En stock',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: _soloDisponibles ? FontWeight.w700 : FontWeight.w500,
                              color: _soloDisponibles ? FashionColors.slateAccent : FashionColors.inkSecondary,
                            ),
                          ),
                          selected: _soloDisponibles,
                          selectedColor: FashionColors.slateAccent.withValues(alpha: 0.12),
                          backgroundColor: FashionColors.surfaceMuted,
                          side: BorderSide(
                            color: _soloDisponibles ? FashionColors.slateAccent : FashionColors.borderSubtle,
                          ),
                          checkmarkColor: FashionColors.slateAccent,
                          onSelected: (val) {
                            setState(() {
                              _soloDisponibles = val;
                              _paginaActual = 1;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        // Botón de ordenar
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: FashionColors.surfaceMuted,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: FashionColors.borderSubtle),
                          ),
                          onPressed: () => _mostrarSelectorOrden(context, filtros),
                          icon: const Icon(Icons.sort_rounded, size: 16, color: FashionColors.inkPrimary),
                          label: Text(
                            'Ordenar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FashionColors.inkPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Chips de filtros activos eliminables
                    if (tieneFiltrosActivos) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (favs.soloFavoritos)
                            Chip(
                              avatar: const Icon(Icons.favorite, size: 14, color: Colors.white),
                              backgroundColor: FashionColors.brandAccent,
                              label: const Text('Favoritos', style: TextStyle(color: Colors.white, fontSize: 11)),
                              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                              onDeleted: () => ref.read(favoritesProvider.notifier).setSoloFavoritos(false),
                            ),
                          if (categoriaActiva != null)
                            Chip(
                              backgroundColor: FashionColors.surfaceMuted,
                              label: Text('Cat: ${categoriaActiva.nombre}', style: const TextStyle(fontSize: 11, color: FashionColors.inkPrimary)),
                              deleteIcon: const Icon(Icons.close, size: 14, color: FashionColors.inkSecondary),
                              onDeleted: () => ref.read(filtersProvider.notifier).establecerCategoria(null),
                            ),
                          if (catalogoActivo != null)
                            Chip(
                              backgroundColor: FashionColors.surfaceMuted,
                              label: Text('Col: ${catalogoActivo.nombre}', style: const TextStyle(fontSize: 11, color: FashionColors.inkPrimary)),
                              deleteIcon: const Icon(Icons.close, size: 14, color: FashionColors.inkSecondary),
                              onDeleted: () => ref.read(filtersProvider.notifier).establecerCatalogo(null),
                            ),
                          if (filtros.busqueda.trim().isNotEmpty)
                            Chip(
                              backgroundColor: FashionColors.surfaceMuted,
                              label: Text('"${filtros.busqueda}"', style: const TextStyle(fontSize: 11, color: FashionColors.inkPrimary)),
                              deleteIcon: const Icon(Icons.close, size: 14, color: FashionColors.inkSecondary),
                              onDeleted: () {
                                _searchController.clear();
                                ref.read(filtersProvider.notifier).establecerBusqueda('');
                              },
                            ),
                          ActionChip(
                            label: const Text('Limpiar todo', style: TextStyle(fontSize: 11, color: FashionColors.statusDanger, fontWeight: FontWeight.w600)),
                            backgroundColor: FashionColors.surfaceCard,
                            side: const BorderSide(color: FashionColors.borderSubtle),
                            onPressed: _limpiarTodosLosFiltros,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // CONTENIDO PRINCIPAL: LOADING, ERROR, EMPTY O GRID
            if (_cargando)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: FashionColors.inkPrimary),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 52, color: FashionColors.statusDanger),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: FashionColors.inkPrimary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FashionColors.inkPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _cargarCatalogData,
                          child: const Text('Reintentar conexión'),
                        )
                      ],
                    ),
                  ),
                ),
              )
            else if (productosFiltrados.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AtelierEmptyStateIllustration(
                          type: AtelierEmptyStateType.emptySearch,
                          size: 130,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          favs.soloFavoritos
                              ? 'No tienes prendas guardadas en tus favoritos'
                              : 'No encontramos prendas con los filtros aplicados',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prueba buscando con otros términos o restableciendo los filtros seleccionados.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkSecondary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FashionColors.inkPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          onPressed: _limpiarTodosLosFiltros,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Restablecer filtros'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // CUADRÍCULA DE PRENDAS LOOKBOOK
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.63,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ProductCardWidget(
                        producto: productosPaginados[index],
                        promocionesVigentes: _promociones,
                      );
                    },
                    childCount: productosPaginados.length,
                  ),
                ),
              ),

              // CONTROLES DE PAGINACIÓN CLIENTE
              if (totalPaginas > 1)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: FashionColors.inkPrimary),
                          onPressed: _paginaActual > 1
                              ? () {
                                  setState(() => _paginaActual--);
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Página $_paginaActual de $totalPaginas',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: FashionColors.inkPrimary),
                          onPressed: _paginaActual < totalPaginas
                              ? () {
                                  setState(() => _paginaActual++);
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

              // Clearance inferior para el Floating Pill Dock
              const SliverToBoxAdapter(
                child: SizedBox(height: 96),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
