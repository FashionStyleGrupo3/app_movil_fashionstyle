// @source-mirror: src/views/publico/VistaDetallePrenda.vue, src/components/escaparate/VisorDetalleProducto.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/network/change_bus.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/size_guide_modal.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _cargando = true;
  String? _error;

  Product? _producto;
  List<Promotion> _promociones = [];
  ProductVariant? _varianteSeleccionada;
  int _cantidad = 1;
  int _imagenIndice = 0;

  final PageController _galeriaController = PageController();
  StreamSubscription<DataChangeEvent>? _busSub;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
    _iniciarSuscripcionBus();
  }

  @override
  void dispose() {
    _galeriaController.dispose();
    _busSub?.cancel();
    super.dispose();
  }

  void _iniciarSuscripcionBus() {
    _busSub = ChangeBus.instance.stream.listen((evento) {
      const recursos = ['productos', 'promociones', 'inventarios'];
      if (recursos.contains(evento.recurso)) {
        _refrescarSilencioso();
      }
    });
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        ProductService.instance.obtenerProducto(widget.productId),
        PromotionService.instance.obtenerPromocionesVigentes(),
      ]);

      final prod = resultados[0] as Product?;
      final promos = resultados[1] as List<Promotion>;

      if (mounted) {
        if (prod == null) {
          setState(() {
            _error = 'Prenda no encontrada o dada de baja.';
            _cargando = false;
          });
          return;
        }

        ProductVariant? defaultVar;
        if (prod.variantes.isNotEmpty) {
          defaultVar = prod.variantes.firstWhere(
            (v) => v.stock > 0,
            orElse: () => prod.variantes.first,
          );
        }

        setState(() {
          _producto = prod;
          _promociones = promos;
          _varianteSeleccionada = defaultVar;
          _cantidad = 1;
          _imagenIndice = 0;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al sincronizar los detalles de la prenda.';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _refrescarSilencioso() async {
    try {
      final resultados = await Future.wait([
        ProductService.instance.obtenerProducto(widget.productId),
        PromotionService.instance.obtenerPromocionesVigentes(),
      ]);

      final prod = resultados[0] as Product?;
      final promos = resultados[1] as List<Promotion>;

      if (mounted && prod != null) {
        ProductVariant? varActualizada;
        if (_varianteSeleccionada != null) {
          varActualizada = prod.variantes.firstWhere(
            (v) => v.idVariante == _varianteSeleccionada!.idVariante,
            orElse: () => prod.variantes.isNotEmpty ? prod.variantes.first : _varianteSeleccionada!,
          );
        }

        setState(() {
          _producto = prod;
          _promociones = promos;
          if (varActualizada != null) {
            _varianteSeleccionada = varActualizada;
            if (_cantidad > varActualizada.stock && varActualizada.stock > 0) {
              _cantidad = varActualizada.stock;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _seleccionarVariante(ProductVariant variante) {
    setState(() {
      _varianteSeleccionada = variante;
      _cantidad = 1;
    });
  }

  void _cambiarCantidad(int delta) {
    final maxStock = _varianteSeleccionada?.stock ?? 0;
    if (maxStock <= 0) return;
    setState(() {
      _cantidad = (_cantidad + delta).clamp(1, maxStock);
    });
  }

  void _agregarAlCarrito() {
    if (_producto == null || _varianteSeleccionada == null) return;

    if (_varianteSeleccionada!.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta talla se encuentra agotada temporalmente.'),
          backgroundColor: FashionColors.statusDanger,
        ),
      );
      return;
    }

    final precioBase = _varianteSeleccionada!.precioVenta > 0
        ? _varianteSeleccionada!.precioVenta
        : _producto!.precioMinimo;
    final infoPrecio = PromotionService.instance.calcularPrecioPromocional(
      _producto!,
      precioBase,
      _promociones,
    );

    ref.read(cartProvider.notifier).agregarPrenda(
          _producto!,
          _varianteSeleccionada!,
          _cantidad,
          infoPrecio.precioFinal,
          infoPrecio.precioOriginal,
        );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Se agregó ${_producto!.nombre} (${_varianteSeleccionada!.talla}) x$_cantidad a tu carrito!'),
        backgroundColor: FashionColors.inkPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
        action: SnackBarAction(
          label: 'VER CARRITO',
          textColor: FashionColors.arena,
          onPressed: () {
            ref.read(cartProvider.notifier).abrirCajon();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicShellLayout(
      child: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: FashionColors.inkPrimary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 52, color: FashionColors.statusDanger),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 15)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FashionColors.inkPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => context.go('/catalogo'),
                          child: const Text('Volver al catálogo'),
                        ),
                      ],
                    ),
                  ),
                )
              : _construirDetalleCompleto(),
    );
  }

  Widget _construirDetalleCompleto() {
    final prod = _producto!;
    final authState = ref.watch(authProvider);
    final favsState = ref.watch(favoritesProvider);
    final esFavorito = favsState.esFavorito(prod.idProducto);

    // Cálculos de precio con promociones
    final precioBase = _varianteSeleccionada != null && _varianteSeleccionada!.precioVenta > 0
        ? _varianteSeleccionada!.precioVenta
        : prod.precioMinimo;

    final infoPrecio = PromotionService.instance.calcularPrecioPromocional(
      prod,
      precioBase,
      _promociones,
    );

    final precioFinal = infoPrecio.precioFinal;
    final stockActual = _varianteSeleccionada?.stock ?? 0;
    final agotado = stockActual <= 0;

    // Galería de imágenes
    final listaImagenes = prod.imagenes.map((img) => img.urlResuelta).where((u) => u.isNotEmpty).toList();
    if (listaImagenes.isEmpty && prod.primeraImagenUrl.isNotEmpty) {
      listaImagenes.add(prod.primeraImagenUrl);
    }

    final subtituloCategoria = [
      prod.categoria?.nombre,
      prod.catalogo?.nombre,
    ].where((x) => x != null && x.isNotEmpty).join(' · ');

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: FashionColors.inkPrimary,
            backgroundColor: FashionColors.surfaceCard,
            onRefresh: _cargarDetalle,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.zero,
              children: [
                // BARRA SUPERIOR DE NAVEGACIÓN FLOTANTE (Volver + Favorito)
                Container(
                  color: FashionColors.canvasBackground,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Material(
                        color: FashionColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/catalogo');
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.arrow_back_rounded, size: 20, color: FashionColors.inkPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Volver al catálogo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: FashionColors.inkSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: FashionColors.surfaceCard,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: Icon(
                            esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: esFavorito ? FashionColors.brandAccent : FashionColors.inkPrimary,
                          ),
                          onPressed: () {
                            ref.read(favoritesProvider.notifier).alternar(
                                  prod.idProducto,
                                  estaAutenticado: authState.estaAutenticado,
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // GALERÍA DE IMÁGENES INMERSIVA CON INTERACTIVE VIEWER (Pinch to zoom)
                Stack(
                  children: [
                    Container(
                      height: 380,
                      color: FashionColors.surfaceCard,
                      child: listaImagenes.isNotEmpty
                          ? PageView.builder(
                              controller: _galeriaController,
                              itemCount: listaImagenes.length,
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: (i) => setState(() => _imagenIndice = i),
                              itemBuilder: (context, index) {
                                return InteractiveViewer(
                                  panEnabled: true,
                                  minScale: 1.0,
                                  maxScale: 3.5,
                                  child: CachedNetworkImage(
                                    imageUrl: listaImagenes[index],
                                    fit: BoxFit.contain,
                                    memCacheWidth: 1080,
                                    placeholder: (_, __) => Container(
                                      color: FashionColors.surfaceMuted,
                                      child: const Center(
                                        child: CircularProgressIndicator(color: FashionColors.inkPrimary),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: FashionColors.surfaceMuted,
                                      child: const Icon(Icons.broken_image_rounded, size: 48, color: FashionColors.inkSecondary),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: FashionColors.surfaceMuted,
                              child: const Center(
                                child: Icon(Icons.checkroom_rounded, size: 64, color: FashionColors.inkSecondary),
                              ),
                            ),
                    ),
                    // Badge de descuento Terracotta (#B83A24)
                    if (infoPrecio.tieneDescuento)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: FashionColors.brandAccent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: FashionColors.brandAccent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '-${infoPrecio.porcentaje}% OFF',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    // Pista de zoom gestual
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FashionColors.inkPrimary.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Pellizca para zoom',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // INDICADORES DE FOTO (Pills)
                if (listaImagenes.length > 1)
                  Container(
                    color: FashionColors.surfaceCard,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        listaImagenes.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _imagenIndice == i ? 22 : 6,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _imagenIndice == i ? FashionColors.brandAccent : FashionColors.borderSubtle,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ESPECIFICACIÓN ATELIER CON TOP-RADIUS 28PX
                Container(
                  decoration: const BoxDecoration(
                    color: FashionColors.surfaceCard,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kicker y SKU
                      Row(
                        children: [
                          if (subtituloCategoria.isNotEmpty)
                            Expanded(
                              child: Text(
                                subtituloCategoria.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.3,
                                  color: FashionColors.inkSecondary,
                                ),
                              ),
                            ),
                          if (_varianteSeleccionada?.sku != null && _varianteSeleccionada!.sku.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: FashionColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SKU: ${_varianteSeleccionada!.sku}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: FashionColors.inkSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Título en Space Grotesk
                      Text(
                        prod.nombre,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: FashionColors.inkPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // PRECIOS CON JETBRAINS MONO
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            CurrencyFormatter.formatearCOP(precioFinal),
                            style: FashionTheme.priceTextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: FashionColors.inkPrimary,
                            ),
                          ),
                          if (infoPrecio.tieneDescuento) ...[
                            const SizedBox(width: 12),
                            Text(
                              CurrencyFormatter.formatearCOP(precioBase),
                              style: FashionTheme.priceTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: FashionColors.inkSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Divider(color: FashionColors.borderSubtle, height: 1),
                      const SizedBox(height: 18),

                      // SELECTOR DE TALLAS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selecciona tu talla',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: FashionColors.inkPrimary,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.straighten_rounded, size: 16, color: FashionColors.brandAccent),
                            label: Text(
                              'Guía de medidas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: FashionColors.brandAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => SizeGuideModal.show(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // BOTONES DE TALLAS (44x44 TOUCH TARGETS)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: prod.variantes.map((v) {
                          final seleccionada = _varianteSeleccionada?.idVariante == v.idVariante;
                          final sinStock = v.stock <= 0;

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: sinStock ? null : () => _seleccionarVariante(v),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              constraints: const BoxConstraints(minWidth: 46, minHeight: 44),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: seleccionada
                                    ? FashionColors.inkPrimary
                                    : (sinStock ? FashionColors.surfaceMuted : FashionColors.surfaceCard),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: seleccionada
                                      ? FashionColors.inkPrimary
                                      : (sinStock ? FashionColors.borderSubtle : FashionColors.borderSubtle),
                                  width: seleccionada ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                v.talla,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: seleccionada
                                      ? Colors.white
                                      : (sinStock ? FashionColors.inkSecondary : FashionColors.inkPrimary),
                                  decoration: sinStock ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // ESTADO DE STOCK SEMÁNTICO
                      if (agotado)
                        Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: FashionColors.statusDanger, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Agotado en esta talla',
                              style: GoogleFonts.plusJakartaSans(
                                color: FashionColors.statusDanger,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      else if (stockActual <= 5)
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: FashionColors.statusWarning, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '¡Solo quedan $stockActual unidades disponibles!',
                              style: GoogleFonts.plusJakartaSans(
                                color: FashionColors.statusWarning,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: FashionColors.statusSuccess, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Disponible ($stockActual unidades en stock)',
                              style: GoogleFonts.plusJakartaSans(
                                color: FashionColors.statusSuccess,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // SELECTOR DE CANTIDAD
                      if (!agotado) ...[
                        Row(
                          children: [
                            Text(
                              'Cantidad:',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: FashionColors.inkPrimary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: FashionColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18, color: FashionColors.inkPrimary),
                                    onPressed: _cantidad > 1 ? () => _cambiarCantidad(-1) : null,
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 32),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_cantidad',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: FashionColors.inkPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18, color: FashionColors.inkPrimary),
                                    onPressed: _cantidad < stockActual ? () => _cambiarCantidad(1) : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // DESCRIPCIÓN ATELIER
                      if (prod.descripcion.isNotEmpty) ...[
                        Text(
                          'Detalles de la prenda',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prod.descripcion,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            height: 1.5,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (prod.color.isNotEmpty)
                        Text(
                          'Tono / Color: ${prod.color}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // BARRA FIJA INFERIOR ERGONÓMICA EN SAFEAREA CON BOTÓN TERRACOTTA (#B83A24)
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: FashionColors.surfaceCard,
              border: const Border(top: BorderSide(color: FashionColors.borderSubtle, width: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total carrito:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary)),
                    Text(
                      CurrencyFormatter.formatearCOP(precioFinal * _cantidad),
                      style: FashionTheme.priceTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: FashionColors.inkPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FashionColors.brandAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: FashionColors.borderSubtle,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: agotado ? null : _agregarAlCarrito,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                    label: Text(
                      agotado ? 'Agotado' : 'Añadir al carrito',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
