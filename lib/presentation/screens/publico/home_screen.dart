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
import 'package:fashion_style_mobile/presentation/widgets/common/fashion_brand_emblem.dart';
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

  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _diapositivaActual = 0;
  Timer? _temporizadorCarrusel;
  StreamSubscription<DataChangeEvent>? _busSub;

  int _tabFiltroRapido = 0; // 0: Todos, 1: Novedades, 2: Con descuento

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
          _categorias = resultados[1] as List<Category>;
          _colecciones = resultados[2] as List<Catalog>;
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
          _categorias = resultados[1] as List<Category>;
          _colecciones = resultados[2] as List<Catalog>;
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
          texto: col.descripcion.isNotEmpty ? col.descripcion : 'Piezas seleccionadas de nuestra colección.',
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
        color: FashionColors.negro,
        backgroundColor: Colors.white,
        displacement: 20,
        onRefresh: _cargarDatos,
        child: _cargando
            ? _construirSkeletonCarga()
            : _error != null
                ? _construirVistaError()
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      // 1. EMBLEMA DE PORTADA E IDENTIDAD VISUAL DE LA MARCA
                      _construirBannerEmblemaPortada(),

                      const SizedBox(height: 16),

                      // 2. HERO CAROUSEL TÁCTIL (Deslizamiento horizontal)
                      _construirHeroSection(),

                      const SizedBox(height: 24),

                      // 3. CATEGORÍAS EN BURBUJAS DESLIZABLES (Estilo Stories Móvil)
                      _construirCategoriasHistorias(),

                      const SizedBox(height: 24),

                      // 4. PRENDAS DESTACADAS CON CHIPS DE FILTRO RÁPIDO
                      _construirSeccionPrendasDestacadas(),

                      const SizedBox(height: 32),

                      // 5. PILARES DE LA MARCA EN CARRUSEL HORIZONTAL TÁCTIL
                      _construirValoresMarca(),
                    ],
                  ),
      ),
    );
  }

  /// 1. Emblema distintivo de portada para la aplicación móvil
  Widget _construirBannerEmblemaPortada() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FashionColors.borde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Símbolo e Isotipo Oficial central
          const Hero(
            tag: 'fashion_style_app_emblem',
            child: FashionBrandEmblem(
              size: 54,
              conSombra: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: FashionColors.arenaSuave,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ATELIER OFICIAL',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: FashionColors.pizarra,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.touch_app_outlined, size: 14, color: FashionColors.gris),
                    const SizedBox(width: 4),
                    const Text('Desliza', style: TextStyle(fontSize: 10, color: FashionColors.gris)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Moda & Sastrería Fina',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: FashionColors.negro,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Piezas atemporales con confección boutique.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: FashionColors.gris,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Carrusel Hero táctil con PageView y gestos de deslizamiento
  Widget _construirHeroSection() {
    final diapositivas = _obtenerDiapositivas();

    return Column(
      children: [
        SizedBox(
          height: 330,
          child: PageView.builder(
            controller: _pageController,
            itemCount: diapositivas.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _diapositivaActual = i),
            itemBuilder: (context, index) {
              final d = diapositivas[index];
              final activa = _diapositivaActual == index;

              return AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: activa ? 0 : 8,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (d.id != null) {
                      ref.read(filtersProvider.notifier).establecerCatalogo(d.id);
                    }
                    context.go('/catalogo');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: FashionColors.borde),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Imagen de portada
                        if (d.fotoUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: d.fotoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: FashionColors.arenaSuave),
                            errorWidget: (_, __, ___) => Container(
                              color: FashionColors.arenaSuave,
                              child: const Center(
                                child: Icon(Icons.image_outlined, size: 48, color: FashionColors.gris),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: FashionColors.arenaSuave,
                            child: const Center(
                              child: FashionBrandEmblem(size: 64, conSombra: false),
                            ),
                          ),

                        // Gradiente de lectura oscuro elegante
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                                stops: const [0.4, 0.65, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Contenido textual inferior
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'COLECCIÓN ATELIER',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                d.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d.texto,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Ver colección',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: FashionColors.negro,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_rounded, size: 14, color: FashionColors.negro),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${d.totalPrendas} prendas',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (diapositivas.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              diapositivas.length,
              (index) {
                final activa = _diapositivaActual == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: activa ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: activa ? FashionColors.negro : FashionColors.borde,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// 3. Categorías en burbujas con scroll horizontal fluido
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
                'Categorías',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: FashionColors.negro,
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
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: FashionColors.pizarra,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: FashionColors.pizarra),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: FashionColors.arenaOscura, width: 1.5),
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: imagen.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imagen,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: FashionColors.arenaSuave),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.checkroom_rounded,
                                    size: 24,
                                    color: FashionColors.pizarra,
                                  ),
                                )
                              : const Icon(Icons.checkroom_rounded, size: 24, color: FashionColors.pizarra),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FashionColors.negro,
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

  /// 4. Prendas destacadas con pestañas rápidas y grid de 2 columnas
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
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: FashionColors.negro,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20, color: FashionColors.negro),
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
              child: const Text('No hay prendas en esta selección', style: TextStyle(color: FashionColors.gris)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? FashionColors.negro : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? FashionColors.negro : FashionColors.borde,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            color: activo ? Colors.white : FashionColors.texto,
          ),
        ),
      ),
    );
  }

  /// 5. Pilares de servicio en carrusel horizontal deslizable
  Widget _construirValoresMarca() {
    final valores = [
      _PilarMarca(
        icono: Icons.local_shipping_outlined,
        titulo: 'Envíos Nacionales',
        descripcion: 'Cobertura oficial con rastreo de guía en tiempo real.',
      ),
      _PilarMarca(
        icono: Icons.verified_outlined,
        titulo: 'Calidad Atelier',
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
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: FashionColors.negro,
            ),
          ),
        ),
        const SizedBox(height: 10),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FashionColors.borde),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FashionColors.arenaSuave,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(v.icono, color: FashionColors.negro, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            v.titulo,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: FashionColors.negro,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v.descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: FashionColors.gris),
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
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FashionColors.borde),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FashionColors.borde),
          ),
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
                  color: Colors.white,
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
            const Icon(Icons.cloud_off_rounded, size: 52, color: FashionColors.peligro),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: FashionColors.texto),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.negro,
                foregroundColor: Colors.white,
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
