// @source-mirror: src/views/publico/VistaInicio.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/network/change_bus.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/filters_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _cargando = true;
  String? _error;

  List<Product> _productos = [];
  List<Category> _categorias = [];
  List<Catalog> _colecciones = [];
  List<Promotion> _promociones = [];

  final PageController _pageController = PageController();
  int _diapositivaActual = 0;
  Timer? _temporizadorCarrusel;
  StreamSubscription<DataChangeEvent>? _busSub;

  int _tabFiltroRapido = 0; // 0: Todos/Imprescindibles, 1: Novedades, 2: Con descuento

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _iniciarSuscripcionBus();
  }

  @override
  void dispose() {
    _temporizadorCarrusel?.cancel();
    _pageController.dispose();
    _busSub?.cancel();
    super.dispose();
  }

  void _iniciarSuscripcionBus() {
    _busSub = ChangeBus.instance.stream.listen((evento) {
      const recursosRelevantes = [
        'productos',
        'categorias',
        'catalogos',
        'promociones',
        'inventarios',
        'ventas',
        'pedidos',
        'ordenes-produccion'
      ];
      if (recursosRelevantes.contains(evento.recurso)) {
        _recargarSilencioso();
      }
    });
  }

  Future<void> _cargarDatos() async {
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
          _colecciones = {for (var c in resultados[2] as List<Catalog>) c.idCatalogo: c}.values.toList();
          _promociones = resultados[3] as List<Promotion>;
          _cargando = false;
        });
        _iniciarTemporizadorCarrusel();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron sincronizar los datos de la portada.';
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
          _colecciones = {for (var c in resultados[2] as List<Catalog>) c.idCatalogo: c}.values.toList();
          _promociones = resultados[3] as List<Promotion>;
        });
      }
    } catch (_) {}
  }

  void _iniciarTemporizadorCarrusel() {
    _temporizadorCarrusel?.cancel();
    final total = _obtenerDiapositivas().length;
    if (total <= 1) return;

    _temporizadorCarrusel = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final siguiente = (_diapositivaActual + 1) % total;
      _pageController.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  List<_DiapositivaHero> _obtenerDiapositivas() {
    if (_colecciones.isNotEmpty) {
      return _colecciones.map((col) {
        final prendasCol = _productos.where((p) => p.catalogo?.idCatalogo == col.idCatalogo).toList();
        final imagenes = prendasCol
            .map((p) => p.primeraImagenUrl)
            .where((img) => img.isNotEmpty)
            .take(3)
            .toList();

        final foto = col.original['imagen'] != null
            ? ImageUrlResolver.resolve(col.original['imagen'])
            : (imagenes.isNotEmpty ? imagenes.first : '');

        return _DiapositivaHero(
          id: col.idCatalogo,
          titulo: col.nombre,
          texto: col.descripcion.isNotEmpty ? col.descripcion : 'Piezas seleccionadas de nuestra colección sartorial.',
          fotoUrl: foto,
          imagenesPrendas: imagenes,
          totalPrendas: prendasCol.length,
        );
      }).toList();
    }

    final imagenesPortadas = _productos
        .map((p) => p.primeraImagenUrl)
        .where((img) => img.isNotEmpty)
        .take(3)
        .toList();

    return [
      _DiapositivaHero(
        id: null,
        titulo: 'Nueva Colección ${DateTime.now().year}',
        texto: 'Moda minimalista y sastrería de alta gama.',
        fotoUrl: imagenesPortadas.isNotEmpty ? imagenesPortadas.first : '',
        imagenesPrendas: imagenesPortadas,
        totalPrendas: _productos.length,
      )
    ];
  }

  List<Product> _obtenerPrendasFiltradas() {
    var lista = List<Product>.from(_productos);
    if (_tabFiltroRapido == 1) {
      // Novedades (orden descendente por ID)
      lista.sort((a, b) => b.idProducto.compareTo(a.idProducto));
    } else if (_tabFiltroRapido == 2) {
      // Con promoción activa
      final prodIdsConPromo = _promociones
          .where((pr) => pr.idProducto != null)
          .map((pr) => pr.idProducto!)
          .toSet();
      lista = lista.where((p) => prodIdsConPromo.contains(p.idProducto) || p.precioFinalBackend != null).toList();
      if (lista.isEmpty) {
        lista = List<Product>.from(_productos);
      }
    }
    return lista.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PublicShellLayout(
      currentIndex: 0,
      child: RefreshIndicator(
        color: FashionColors.inkPrimary,
        backgroundColor: FashionColors.surfaceCard,
        displacement: 20,
        onRefresh: _cargarDatos,
        child: _cargando
            ? _construirSkeletonCarga()
            : _error != null
                ? _construirVistaError()
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(bottom: 96), // Clearance para Floating Pill Dock
                    children: [
                      const SizedBox(height: 12),

                      // 1. HERO BENTO ASIMÉTRICO (DARK CARD + 2 TILES MINERALES)
                      _construirBentoHero(),

                      const SizedBox(height: 24),

                      // 2. CATEGORÍAS HORIZONTALES (ESTILO HISTORIAS ATELIER)
                      _construirCategoriasHistorias(),

                      const SizedBox(height: 24),

                      // 3. PRENDAS DESTACADAS CON CHIPS DE FILTRO RÁPIDO Y LOOKBOOK GRID
                      _construirSeccionPrendasDestacadas(),

                      const SizedBox(height: 32),

                      // 4. PILARES DE LA MARCA (EXPERIENCIA FASHIONSTYLE)
                      _construirValoresMarca(),
                    ],
                  ),
      ),
    );
  }

  /// 1. Asymmetric Editorial Bento Hero: Dark Card `#14161F` + 2 Mineral Highlight Tiles
  Widget _construirBentoHero() {
    final diapositivas = _obtenerDiapositivas();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta principal Nocturna #14161F con AtelierPatternBackground
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: FashionColors.inkPrimary,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FashionColors.borderSubtle.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fondo decorativo con retícula y puntadas sutiles
                const AtelierPatternBackground(
                  colorFondo: FashionColors.inkPrimary,
                  opacidadReticula: 0.08,
                  child: SizedBox.expand(),
                ),

                // Carrusel de diapositivas
                PageView.builder(
                  controller: _pageController,
                  itemCount: diapositivas.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _diapositivaActual = i),
                  itemBuilder: (context, index) {
                    final d = diapositivas[index];

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Imagen de portada (a la derecha/fondo con gradiente)
                        if (d.fotoUrl.isNotEmpty)
                          Positioned(
                            right: -20,
                            top: 0,
                            bottom: 0,
                            width: 220,
                            child: Opacity(
                              opacity: 0.45,
                              child: CachedNetworkImage(
                                imageUrl: d.fotoUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.transparent),
                                errorWidget: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),

                        // Gradiente de contraste para legibilidad total del texto
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  FashionColors.inkPrimary,
                                  FashionColors.inkPrimary.withValues(alpha: 0.92),
                                  FashionColors.inkPrimary.withValues(alpha: 0.50),
                                ],
                                stops: const [0.45, 0.75, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Contenido textual editorial
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Kicker superior con Monograma y Badge de Colección
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: FashionColors.brandAccent.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: FashionColors.brandAccent.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      'FASHIONSTYLE',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.4,
                                        color: FashionColors.brandAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Titular en Space Grotesk y descripción
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.titulo,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: FashionColors.surfaceCard,
                                      letterSpacing: -0.4,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    d.texto,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      color: FashionColors.surfaceMuted.withValues(alpha: 0.85),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),

                              // Botón de acción Terracotta (#B83A24) y contador de prendas
                              Row(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(100),
                                    onTap: () {
                                      if (d.id != null) {
                                        ref.read(filtersProvider.notifier).establecerCatalogo(d.id);
                                      }
                                      context.go('/catalogo');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: FashionColors.brandAccent,
                                        borderRadius: BorderRadius.circular(100),
                                        boxShadow: [
                                          BoxShadow(
                                            color: FashionColors.brandAccent.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Explorar Colección',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (d.totalPrendas > 0)
                                    Text(
                                      '${d.totalPrendas} piezas',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: FashionColors.surfaceMuted.withValues(alpha: 0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Indicadores de diapositiva inferiores discretos
                if (diapositivas.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        diapositivas.length,
                        (index) {
                          final activa = _diapositivaActual == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: activa ? 18 : 5,
                            height: 4,
                            decoration: BoxDecoration(
                              color: activa ? FashionColors.brandAccent : Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2 Tiles Minerales Complementarios (#FFFFFF / #EBEEF3 con acento Jade #115E59)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FashionColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FashionColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FashionColors.slateAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded, size: 20, color: FashionColors.slateAccent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calidad Garantizada',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FashionColors.inkPrimary,
                              ),
                            ),
                            Text(
                              'Confección local fina',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: FashionColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FashionColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FashionColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FashionColors.brandAccent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_outlined, size: 20, color: FashionColors.brandAccent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pago Protegido',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FashionColors.inkPrimary,
                              ),
                            ),
                            Text(
                              'Wompi Bancolombia',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: FashionColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Categorías en burbujas con scroll horizontal fluido y estética mineral
  Widget _construirCategoriasHistorias() {
    if (_categorias.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Líneas de Diseño',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.inkPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(filtersProvider.notifier).limpiarFiltros();
                  context.go('/catalogo');
                },
                child: Row(
                  children: [
                    Text(
                      'Ver catálogo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: FashionColors.brandAccent,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: FashionColors.brandAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 98,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categorias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = _categorias[index];
              final prendasCat = _productos.where((p) => p.categoria?.idCategoria == cat.idCategoria).toList();
              String imagen = '';
              if (cat.original['imagen'] != null) {
                imagen = ImageUrlResolver.resolve(cat.original['imagen']);
              } else if (prendasCat.isNotEmpty) {
                imagen = prendasCat.first.primeraImagenUrl;
              }

              return GestureDetector(
                onTap: () {
                  ref.read(filtersProvider.notifier).establecerCategoria(cat.idCategoria);
                  context.go('/catalogo');
                },
                child: SizedBox(
                  width: 74,
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: FashionColors.borderSubtle, width: 1.5),
                          color: FashionColors.surfaceCard,
                        ),
                        child: ClipOval(
                          child: imagen.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imagen,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: FashionColors.surfaceMuted),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.checkroom_rounded,
                                    size: 24,
                                    color: FashionColors.inkSecondary,
                                  ),
                                )
                              : const Icon(Icons.checkroom_rounded, size: 24, color: FashionColors.inkSecondary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FashionColors.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 3. Prendas destacadas con pestañas rápidas y lookbook grid de 2 columnas
  Widget _construirSeccionPrendasDestacadas() {
    final prendas = _obtenerPrendasFiltradas();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prendas Destacadas',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.inkPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20, color: FashionColors.inkPrimary),
                tooltip: 'Filtrar',
                onPressed: () => context.go('/catalogo'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pestañas rápidas táctiles (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _chipFiltro('Imprescindibles', 0),
                const SizedBox(width: 8),
                _chipFiltro('Novedades', 1),
                const SizedBox(width: 8),
                _chipFiltro('Ofertas Especiales', 2),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cuadrícula 2 columnas
          if (prendas.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                'No hay prendas en esta selección.',
                style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prendas.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.63,
              ),
              itemBuilder: (context, index) {
                return ProductCardWidget(
                  producto: prendas[index],
                  promocionesVigentes: _promociones,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String label, int index) {
    final activo = _tabFiltroRapido == index;
    return GestureDetector(
      onTap: () => setState(() => _tabFiltroRapido = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? FashionColors.inkPrimary : FashionColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? FashionColors.inkPrimary : FashionColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            color: activo ? Colors.white : FashionColors.inkPrimary,
          ),
        ),
      ),
    );
  }

  /// 4. Pilares de servicio en carrusel horizontal deslizable
  Widget _construirValoresMarca() {
    final valores = [
      _PilarMarca(
        icono: Icons.local_shipping_outlined,
        titulo: 'Envíos Nacionales',
        descripcion: 'Cobertura oficial con rastreo de guía en tiempo real.',
      ),
      _PilarMarca(
        icono: Icons.verified_outlined,
        titulo: 'Calidad Garantizada',
        descripcion: 'Telas seleccionadas y patronaje de alta costura.',
      ),
      _PilarMarca(
        icono: Icons.lock_outline_rounded,
        titulo: 'Pagos Protegidos',
        descripcion: 'Pasarela certificada vía Wompi Bancolombia.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Experiencia FashionStyle',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: FashionColors.inkPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: valores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final v = valores[index];
              return Container(
                width: 250,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FashionColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FashionColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FashionColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(v.icono, color: FashionColors.brandAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            v.titulo,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: FashionColors.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v.descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: FashionColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _construirSkeletonCarga() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: FashionColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FashionColors.borderSubtle),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: FashionColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FashionColors.borderSubtle),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: FashionColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FashionColors.borderSubtle),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 72,
                decoration: const BoxDecoration(
                  color: FashionColors.surfaceCard,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirVistaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: FashionColors.statusDanger),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: FashionColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.inkPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar conexión'),
            )
          ],
        ),
      ),
    );
  }
}

class _DiapositivaHero {
  final int? id;
  final String titulo;
  final String texto;
  final String fotoUrl;
  final List<String> imagenesPrendas;
  final int totalPrendas;

  const _DiapositivaHero({
    required this.id,
    required this.titulo,
    required this.texto,
    required this.fotoUrl,
    required this.imagenesPrendas,
    required this.totalPrendas,
  });
}

class _PilarMarca {
  final IconData icono;
  final String titulo;
  final String descripcion;

  const _PilarMarca({
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });
}
