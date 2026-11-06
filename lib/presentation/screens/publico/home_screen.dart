// @source-mirror: src/views/publico/VistaInicio.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/network/change_bus.dart';
import '../../../core/utils/image_url_resolver.dart';
import '../../../data/models/product_models.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/promotion_service.dart';
import '../../layouts/public_shell_layout.dart';
import '../../providers/filters_provider.dart';
import '../../widgets/storefront_widgets.dart';

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
          _error = 'No se pudieron cargar los datos de la portada.';
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
        duration: const Duration(milliseconds: 600),
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
        texto: 'Moda minimalista para la nueva temporada.',
        fotoUrl: imagenesPortadas.isNotEmpty ? imagenesPortadas.first : '',
        imagenesPrendas: imagenesPortadas,
        totalPrendas: _productos.length,
      )
    ];
  }

  List<_CategoriaDestacada> _obtenerCategoriasDestacadas() {
    return _categorias.map((cat) {
      final prendasCat = _productos.where((p) => p.categoria?.idCategoria == cat.idCategoria).toList();
      String imagen = '';
      if (cat.original['imagen'] != null) {
        imagen = ImageUrlResolver.resolve(cat.original['imagen']);
      } else if (prendasCat.isNotEmpty) {
        imagen = prendasCat.first.primeraImagenUrl;
      }
      return _CategoriaDestacada(
        id: cat.idCategoria,
        nombre: cat.nombre,
        imagenUrl: imagen,
        totalPrendas: prendasCat.length,
      );
    }).toList()
      ..sort((a, b) => b.totalPrendas.compareTo(a.totalPrendas));
  }

  List<Product> _obtenerImprescindibles() {
    final lista = List<Product>.from(_productos);
    lista.sort((a, b) => b.idProducto.compareTo(a.idProducto));
    return lista.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PublicShellLayout(
      currentIndex: 0,
      child: RefreshIndicator(
        color: FashionColors.rosaCorporativo,
        onRefresh: _cargarDatos,
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: FashionColors.rosaCorporativo),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 54, color: FashionColors.peligro),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: FashionColors.textoOscuro),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.negroElegante,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _cargarDatos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          )
                        ],
                      ),
                    ),
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // HERO CAROUSEL
                      _construirHeroSection(),

                      const SizedBox(height: 24),

                      // CATEGORÍAS DESTACADAS
                      _construirSeccionCategorias(),

                      const SizedBox(height: 32),

                      // IMPRESCINDIBLES DE LA TEMPORADA
                      _construirSeccionImprescindibles(),

                      const SizedBox(height: 48),

                      // BANNER INFORMATIVO INFERIOR (Envíos, Calidad, Atención)
                      _construirBannerInformativo(),

                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }

  Widget _construirHeroSection() {
    final diapositivas = _obtenerDiapositivas();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _pageController,
              itemCount: diapositivas.length,
              onPageChanged: (i) {
                setState(() => _diapositivaActual = i);
              },
              itemBuilder: (context, index) {
                final d = diapositivas[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          FashionColors.cremaSuave.withOpacity(0.5),
                          FashionColors.fondoClaro,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Imagen de portada
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: d.fotoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: d.fotoUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (_, __) => Container(
                                      color: FashionColors.grisBorde,
                                      child: const Center(
                                        child: CircularProgressIndicator(color: FashionColors.rosaCorporativo),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: FashionColors.grisBorde,
                                      child: const Icon(Icons.style, size: 48, color: FashionColors.textoMuted),
                                    ),
                                  )
                                : Container(
                                    color: FashionColors.rosaSuave,
                                    child: const Icon(Icons.style, size: 48, color: FashionColors.rosaOscuro),
                                  ),
                          ),
                        ),
                        // Contenido textual y CTA
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: FashionColors.rosaSuave,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'COLECCIÓN EXCLUSIVA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: FashionColors.rosaOscuro,
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
                                  color: FashionColors.textoOscuro,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d.texto,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: FashionColors.textoMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FashionColors.negroElegante,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      if (d.id != null) {
                                        ref.read(filtersProvider.notifier).establecerCatalogo(d.id);
                                      }
                                      context.go('/catalogo');
                                    },
                                    child: const Text('Explorar colección', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${d.totalPrendas} prendas · Premium',
                                      style: const TextStyle(fontSize: 11, color: FashionColors.textoMuted),
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (diapositivas.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  diapositivas.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _diapositivaActual == index ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _diapositivaActual == index
                          ? FashionColors.rosaCorporativo
                          : FashionColors.grisBorde,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirSeccionCategorias() {
    final categorias = _obtenerCategoriasDestacadas().take(3).toList();
    if (categorias.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categorías destacadas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: FashionColors.textoOscuro,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(filtersProvider.notifier).limpiarFiltros();
                  context.go('/catalogo');
                },
                icon: const Icon(Icons.arrow_forward, size: 16, color: FashionColors.rosaCorporativo),
                label: const Text(
                  'Ver todo',
                  style: TextStyle(fontSize: 13, color: FashionColors.rosaCorporativo, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: categorias.map((cat) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(filtersProvider.notifier).establecerCategoria(cat.id);
                      context.go('/catalogo');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.fondoClaro,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FashionColors.grisBorde),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: cat.imagenUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: cat.imagenUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: FashionColors.rosaSuave),
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.checkroom,
                                        size: 28,
                                        color: FashionColors.rosaOscuro,
                                      ),
                                    )
                                  : const Icon(Icons.checkroom, size: 28, color: FashionColors.rosaOscuro),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${cat.totalPrendas} prendas',
                            style: const TextStyle(fontSize: 11, color: FashionColors.textoMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _construirSeccionImprescindibles() {
    final imprescindibles = _obtenerImprescindibles();
    if (imprescindibles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Imprescindibles',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: FashionColors.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Las piezas más deseadas de la temporada',
                    style: TextStyle(fontSize: 12, color: FashionColors.textoMuted),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: FashionColors.textoOscuro),
                tooltip: 'Filtrar catálogo',
                onPressed: () => context.go('/catalogo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: imprescindibles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              return ProductCardWidget(
                producto: imprescindibles[index],
                promocionesVigentes: _promociones,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _construirBannerInformativo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FashionColors.negroElegante,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: FashionColors.rosaCorporativo, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Envíos a todo el país',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Seguimiento en tiempo real con guía oficial',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: Colors.white24, height: 28),
          Row(
            children: [
              Icon(Icons.verified_outlined, color: FashionColors.rosaCorporativo, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calidad garantizada',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Telas y confección boutique de alta gama',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: Colors.white24, height: 28),
          Row(
            children: [
              Icon(Icons.lock_outline, color: FashionColors.rosaCorporativo, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagos 100% seguros',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Integración protegida vía Wompi Bancolombia',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

class _CategoriaDestacada {
  final int id;
  final String nombre;
  final String imagenUrl;
  final int totalPrendas;

  const _CategoriaDestacada({
    required this.id,
    required this.nombre,
    required this.imagenUrl,
    required this.totalPrendas,
  });
}
