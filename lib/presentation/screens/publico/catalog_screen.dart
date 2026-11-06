// @source-mirror: src/views/publico/Vistacatalogo.vue, src/components/escaparate/CuadriculaProductos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/network/change_bus.dart';
import '../../../data/models/product_models.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/promotion_service.dart';
import '../../layouts/public_shell_layout.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/filters_provider.dart';
import '../../widgets/storefront_widgets.dart';

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
          _categorias = resultados[1] as List<Category>;
          _catalogos = resultados[2] as List<Catalog>;
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
          _categorias = resultados[1] as List<Category>;
          _catalogos = resultados[2] as List<Catalog>;
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Ordenar prendas',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: FashionColors.textoOscuro,
                    ),
                  ),
                ),
                const Divider(),
                ...opciones.map((op) {
                  final seleccionado = filtros.orden == op['clave'];
                  return ListTile(
                    leading: Icon(
                      seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: seleccionado ? FashionColors.rosaCorporativo : FashionColors.textoMuted,
                    ),
                    title: Text(
                      op['label']!,
                      style: TextStyle(
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                        color: seleccionado ? FashionColors.rosaCorporativo : FashionColors.textoOscuro,
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
        color: FashionColors.rosaCorporativo,
        onRefresh: _cargarCatalogData,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // BARRA DE BÚSQUEDA Y CONTROL DE FILTROS SUPERIOR
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo de búsqueda con debounce/submit
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar prendas, estilos, colecciones...',
                        prefixIcon: const Icon(Icons.search, color: FashionColors.textoMuted, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(filtersProvider.notifier).establecerBusqueda('');
                                  setState(() => _paginaActual = 1);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        filled: true,
                        fillColor: FashionColors.fondoClaro,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: FashionColors.grisBorde),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: FashionColors.grisBorde),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: FashionColors.rosaCorporativo),
                        ),
                      ),
                      onChanged: (val) {
                        ref.read(filtersProvider.notifier).establecerBusqueda(val);
                        setState(() => _paginaActual = 1);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Fila de chips de categorías horizontales
                    if (_categorias.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: const Text('Todo'),
                                selected: filtros.categoriaId == null,
                                selectedColor: FashionColors.negroElegante,
                                backgroundColor: FashionColors.fondoClaro,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: filtros.categoriaId == null ? Colors.white : FashionColors.textoOscuro,
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
                                  selectedColor: FashionColors.negroElegante,
                                  backgroundColor: FashionColors.fondoClaro,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                    color: sel ? Colors.white : FashionColors.textoOscuro,
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

                    const SizedBox(height: 8),

                    // Barra de estado de filtros y botones de orden / stock
                    Row(
                      children: [
                        Text(
                          favs.soloFavoritos
                              ? 'Mis favoritos ($totalProductos)'
                              : '$totalProductos prenda${totalProductos == 1 ? '' : 's'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FashionColors.textoOscuro),
                        ),
                        const Spacer(),
                        // Interruptor de solo disponibles
                        FilterChip(
                          label: const Text('En stock', style: TextStyle(fontSize: 11)),
                          selected: _soloDisponibles,
                          selectedColor: FashionColors.rosaSuave,
                          checkmarkColor: FashionColors.rosaOscuro,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: _soloDisponibles ? FashionColors.rosaOscuro : FashionColors.textoOscuro,
                          ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: const BorderSide(color: FashionColors.grisBorde),
                          ),
                          onPressed: () => _mostrarSelectorOrden(context, filtros),
                          icon: const Icon(Icons.sort, size: 16, color: FashionColors.textoOscuro),
                          label: const Text('Ordenar', style: TextStyle(fontSize: 12, color: FashionColors.textoOscuro)),
                        ),
                      ],
                    ),

                    // Chips de filtros activos eliminables
                    if (tieneFiltrosActivos) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (favs.soloFavoritos)
                            Chip(
                              avatar: const Icon(Icons.favorite, size: 14, color: Colors.white),
                              backgroundColor: FashionColors.rosaCorporativo,
                              label: const Text('Favoritos', style: TextStyle(color: Colors.white, fontSize: 11)),
                              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                              onDeleted: () => ref.read(favoritesProvider.notifier).setSoloFavoritos(false),
                            ),
                          if (categoriaActiva != null)
                            Chip(
                              backgroundColor: FashionColors.rosaSuave,
                              label: Text('Cat: ${categoriaActiva.nombre}', style: const TextStyle(fontSize: 11, color: FashionColors.rosaOscuro)),
                              deleteIcon: const Icon(Icons.close, size: 14, color: FashionColors.rosaOscuro),
                              onDeleted: () => ref.read(filtersProvider.notifier).establecerCategoria(null),
                            ),
                          if (catalogoActivo != null)
                            Chip(
                              backgroundColor: FashionColors.rosaSuave,
                              label: Text('Col: ${catalogoActivo.nombre}', style: const TextStyle(fontSize: 11, color: FashionColors.rosaOscuro)),
                              deleteIcon: const Icon(Icons.close, size: 14, color: FashionColors.rosaOscuro),
                              onDeleted: () => ref.read(filtersProvider.notifier).establecerCatalogo(null),
                            ),
                          if (filtros.busqueda.trim().isNotEmpty)
                            Chip(
                              backgroundColor: FashionColors.fondoClaro,
                              label: Text('"${filtros.busqueda}"', style: const TextStyle(fontSize: 11)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                _searchController.clear();
                                ref.read(filtersProvider.notifier).establecerBusqueda('');
                              },
                            ),
                          ActionChip(
                            label: const Text('Limpiar todo', style: TextStyle(fontSize: 11, color: FashionColors.peligro)),
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
                  child: CircularProgressIndicator(color: FashionColors.rosaCorporativo),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: FashionColors.peligro),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante),
                          onPressed: _cargarCatalogData,
                          child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
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
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: FashionColors.rosaSuave,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.checkroom_outlined, size: 48, color: FashionColors.rosaOscuro),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          favs.soloFavoritos
                              ? 'No tienes prendas guardadas en tus favoritos'
                              : 'No encontramos prendas con los filtros aplicados',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: FashionColors.textoOscuro,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Prueba buscando con otros términos o ajustando los filtros seleccionados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: FashionColors.textoMuted),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FashionColors.negroElegante,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              // CUADRÍCULA DE PRENDAS
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
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
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: FashionColors.textoOscuro,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
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

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
