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
          _error = 'Error al cargar los detalles de la prenda.';
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
          backgroundColor: FashionColors.peligro,
        ),
      );
      return;
    }

    ref.read(cartProvider.notifier).agregarPrenda(
          _producto!,
          _varianteSeleccionada!,
          _cantidad,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Se agregó ${_producto!.nombre} (${_varianteSeleccionada!.talla}) x$_cantidad a tu bolsa!'),
        backgroundColor: FashionColors.negro,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'VER BOLSA',
          textColor: FashionColors.arenaOscura,
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
              child: CircularProgressIndicator(color: FashionColors.negro),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 52, color: FashionColors.peligro),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negro),
                          onPressed: () => context.go('/catalogo'),
                          child: const Text('Volver al catálogo', style: TextStyle(color: Colors.white)),
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
            color: FashionColors.negro,
            onRefresh: _cargarDetalle,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // BARRA SUPERIOR DE NAVEGACIÓN FLOTANTE (Volver + Favorito)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        elevation: 0.5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/catalogo');
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.arrow_back_rounded, size: 20, color: FashionColors.negro),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Volver al catálogo',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: FashionColors.pizarra,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: IconButton(
                          icon: Icon(
                            esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: esFavorito ? FashionColors.rojo : FashionColors.negro,
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

                // GALERÍA DE IMÁGENES TÁCTIL CON INTERACTIVE VIEWER (Pinch to zoom)
                Stack(
                  children: [
                    Container(
                      height: 400,
                      color: Colors.white,
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
                                    placeholder: (_, __) => Container(
                                      color: FashionColors.arenaSuave,
                                      child: const Center(
                                        child: CircularProgressIndicator(color: FashionColors.negro),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: FashionColors.arenaSuave,
                                      child: const Icon(Icons.broken_image_rounded, size: 48, color: FashionColors.gris),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: FashionColors.arenaSuave,
                              child: const Center(
                                child: Icon(Icons.checkroom_rounded, size: 64, color: FashionColors.gris),
                              ),
                            ),
                    ),
                    // Badge de descuento
                    if (infoPrecio.tieneDescuento)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: FashionColors.negro,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${infoPrecio.porcentaje}% OFF',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
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
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Pellizca para zoom', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // INDICADORES DE FOTO (Pills)
                if (listaImagenes.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        listaImagenes.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _imagenIndice == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _imagenIndice == i ? FashionColors.negro : FashionColors.borde,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),

                // BLOQUE DE INFORMACIÓN DE PRENDA
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtituloCategoria.isNotEmpty)
                        Text(
                          subtituloCategoria.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: FashionColors.pizarra,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        prod.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: FashionColors.negro,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // PRECIOS
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            CurrencyFormatter.formatearCOP(precioFinal),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: FashionColors.negro,
                            ),
                          ),
                          if (infoPrecio.tieneDescuento) ...[
                            const SizedBox(width: 10),
                            Text(
                              CurrencyFormatter.formatearCOP(precioBase),
                              style: const TextStyle(
                                fontSize: 16,
                                color: FashionColors.gris,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: FashionColors.borde),
                      const SizedBox(height: 16),

                      // SELECTOR DE TALLAS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selecciona tu talla',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: FashionColors.negro),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.straighten, size: 16, color: FashionColors.pizarra),
                            label: const Text(
                              'Guía de medidas',
                              style: TextStyle(fontSize: 12, color: FashionColors.pizarra, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => SizeGuideModal.show(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // BOTONES DE TALLAS
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: prod.variantes.map((v) {
                          final seleccionada = _varianteSeleccionada?.idVariante == v.idVariante;
                          final sinStock = v.stock <= 0;

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: sinStock ? null : () => _seleccionarVariante(v),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: seleccionada
                                    ? FashionColors.negro
                                    : (sinStock ? FashionColors.arenaSuave : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: seleccionada
                                      ? FashionColors.negro
                                      : (sinStock ? FashionColors.borde : FashionColors.borde),
                                  width: seleccionada ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                v.talla,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: seleccionada
                                      ? Colors.white
                                      : (sinStock ? FashionColors.gris : FashionColors.texto),
                                  decoration: sinStock ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // ESTADO DE STOCK
                      if (agotado)
                        const Row(
                          children: [
                            Icon(Icons.cancel_outlined, color: FashionColors.peligro, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Agotado en esta talla',
                              style: TextStyle(color: FashionColors.peligro, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else if (stockActual <= 5)
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: FashionColors.aviso, size: 16),
                            SizedBox(width: 6),
                            Text(
                              '¡Solo quedan $stockActual unidades disponibles!',
                              style: const TextStyle(color: FashionColors.aviso, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: FashionColors.verdeExito, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Disponible ($stockActual unidades en stock)',
                              style: const TextStyle(color: FashionColors.verdeExito, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // SELECTOR DE CANTIDAD
                      if (!agotado) ...[
                        Row(
                          children: [
                            const Text(
                              'Cantidad:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FashionColors.texto),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: FashionColors.borde),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _cantidad > 1 ? () => _cambiarCantidad(-1) : null,
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 36),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_cantidad',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: _cantidad < stockActual ? () => _cambiarCantidad(1) : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // DESCRIPCIÓN
                      if (prod.descripcion.isNotEmpty) ...[
                        Text(
                          'Detalles de la prenda',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: FashionColors.negro),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prod.descripcion,
                          style: const TextStyle(fontSize: 13, height: 1.5, color: FashionColors.texto),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // SKU Y COLOR
                      if (_varianteSeleccionada?.sku != null && _varianteSeleccionada!.sku.isNotEmpty)
                        Text(
                          'SKU: ${_varianteSeleccionada!.sku}',
                          style: const TextStyle(fontSize: 11, color: FashionColors.gris),
                        ),
                      if (prod.color.isNotEmpty)
                        Text(
                          'Tono / Color: ${prod.color}',
                          style: const TextStyle(fontSize: 11, color: FashionColors.gris),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // BARRA FIJA INFERIOR ERGONÓMICA PARA PULGAR MÓVIL
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: FashionColors.borde, width: 0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 11, color: FashionColors.gris)),
                  Text(
                    CurrencyFormatter.formatearCOP(precioFinal * _cantidad),
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: FashionColors.negro,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.negro,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: FashionColors.borde,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: agotado ? null : _agregarAlCarrito,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  label: Text(
                    agotado ? 'Agotado' : 'Añadir a la bolsa',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
