// @source-mirror: src/views/publico/VistaDetallePrenda.vue, src/components/escaparate/VisorDetalleProducto.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/network/change_bus.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product_models.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/promotion_service.dart';
import '../../layouts/public_shell_layout.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/storefront_widgets.dart';

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

        // Seleccionar por defecto la primera variante con stock disponible, o la primera
        final varianteInicial = prod.variantes.firstWhere(
          (v) => v.stock > 0,
          orElse: () => prod.variantes.isNotEmpty
              ? prod.variantes.first
              : const ProductVariant(
                  idVariante: 0,
                  talla: 'Única',
                  sku: '',
                  precioVenta: 0,
                  precioOriginal: 0,
                  stock: 0,
                ),
        );

        setState(() {
          _producto = prod;
          _promociones = promos;
          _varianteSeleccionada = varianteInicial;
          _cantidad = 1;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo conectar con el servidor para obtener los detalles de la prenda.';
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
        setState(() {
          _producto = prod;
          _promociones = promos;

          // Mantener o actualizar la variante seleccionada si aún existe
          if (_varianteSeleccionada != null) {
            final actualizada = prod.variantes.where((v) => v.idVariante == _varianteSeleccionada!.idVariante).firstOrNull;
            if (actualizada != null) {
              _varianteSeleccionada = actualizada;
              if (actualizada.stock > 0 && _cantidad > actualizada.stock) {
                _cantidad = actualizada.stock;
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  void _seleccionarVariante(ProductVariant v) {
    setState(() {
      _varianteSeleccionada = v;
      _cantidad = 1;
    });
  }

  void _cambiarCantidad(int delta) {
    if (_varianteSeleccionada == null) return;
    final maxStock = _varianteSeleccionada!.stock;
    if (maxStock <= 0) return;

    final nueva = (_cantidad + delta).clamp(1, maxStock);
    setState(() => _cantidad = nueva);
  }

  void _agregarAlCarrito() {
    if (_producto == null || _varianteSeleccionada == null) return;

    if (_varianteSeleccionada!.stock < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta talla se encuentra actualmente agotada.'),
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
        content: Text(
          'Se añadió ${_producto!.nombre} (${_varianteSeleccionada!.talla}) a tu bolsa.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: FashionColors.negroElegante,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver bolsa',
          textColor: FashionColors.rosaCorporativo,
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
              child: CircularProgressIndicator(color: FashionColors.rosaCorporativo),
            )
          : _error != null
              ? Center(
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // BOTÓN RETROCEDER
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: FashionColors.textoOscuro),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/catalogo');
                  }
                },
              ),
              const Text(
                'Volver al catálogo',
                style: TextStyle(fontSize: 13, color: FashionColors.textoMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // GALERÍA DE IMÁGENES
        Stack(
          children: [
            Container(
              height: 380,
              color: Colors.white,
              child: listaImagenes.isNotEmpty
                  ? PageView.builder(
                      controller: _galeriaController,
                      itemCount: listaImagenes.length,
                      onPageChanged: (i) => setState(() => _imagenIndice = i),
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: listaImagenes[index],
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Container(
                            color: FashionColors.fondoClaro,
                            child: const Center(
                              child: CircularProgressIndicator(color: FashionColors.rosaCorporativo),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: FashionColors.fondoClaro,
                            child: const Icon(Icons.broken_image, size: 64, color: FashionColors.textoMuted),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: FashionColors.fondoClaro,
                      child: const Center(
                        child: Icon(Icons.style, size: 64, color: FashionColors.rosaSuave),
                      ),
                    ),
            ),
            // Botón de favoritos superior derecho
            Positioned(
              top: 12,
              right: 16,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: IconButton(
                  icon: Icon(
                    esFavorito ? Icons.favorite : Icons.favorite_border,
                    color: esFavorito ? FashionColors.rosaCorporativo : FashionColors.textoOscuro,
                  ),
                  onPressed: () {
                    ref.read(favoritesProvider.notifier).alternar(
                          prod.idProducto,
                          estaAutenticado: authState.estaAutenticado,
                        );
                  },
                ),
              ),
            ),
            // Insignia de descuento si aplica
            if (infoPrecio.tieneDescuento)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FashionColors.rosaCorporativo,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${infoPrecio.porcentaje}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),

        // INDICADORES DE PÁGINA DE LA GALERÍA
        if (listaImagenes.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                listaImagenes.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _imagenIndice == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _imagenIndice == i ? FashionColors.rosaCorporativo : FashionColors.grisBorde,
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: FashionColors.rosaOscuro,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                prod.nombre,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: FashionColors.textoOscuro,
                ),
              ),
              const SizedBox(height: 12),

              // PRECIOS
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    CurrencyFormatter.formatearCOP(precioFinal),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: infoPrecio.tieneDescuento ? FashionColors.rosaCorporativo : FashionColors.textoOscuro,
                    ),
                  ),
                  if (infoPrecio.tieneDescuento) ...[
                    const SizedBox(width: 10),
                    Text(
                      CurrencyFormatter.formatearCOP(precioBase),
                      style: const TextStyle(
                        fontSize: 16,
                        color: FashionColors.textoMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: FashionColors.grisBorde),
              const SizedBox(height: 16),

              // SELECTOR DE TALLAS / VARIANTES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selecciona tu talla',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FashionColors.textoOscuro),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.straighten, size: 16, color: FashionColors.rosaOscuro),
                    label: const Text(
                      'Guía de medidas',
                      style: TextStyle(fontSize: 12, color: FashionColors.rosaOscuro, fontWeight: FontWeight.w600),
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
                    borderRadius: BorderRadius.circular(8),
                    onTap: sinStock ? null : () => _seleccionarVariante(v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: seleccionada
                            ? FashionColors.negroElegante
                            : (sinStock ? FashionColors.fondoClaro : Colors.white),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: seleccionada
                              ? FashionColors.negroElegante
                              : (sinStock ? FashionColors.grisBorde : FashionColors.textoOscuro),
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
                              : (sinStock ? FashionColors.textoMuted : FashionColors.textoOscuro),
                          decoration: sinStock ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // INDICADOR DE STOCK DISPONIBLE
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
                    const SizedBox(width: 6),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FashionColors.textoOscuro),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: FashionColors.grisBorde),
                        borderRadius: BorderRadius.circular(8),
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
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 11, color: FashionColors.textoMuted)),
                        Text(
                          CurrencyFormatter.formatearCOP(precioFinal * _cantidad),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: FashionColors.textoOscuro,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // BOTÓN PRINCIPAL: AGREGAR A LA BOLSA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.negroElegante,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: FashionColors.grisBorde,
                    disabledForegroundColor: FashionColors.textoMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: agotado ? null : _agregarAlCarrito,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    agotado ? 'Talla no disponible' : 'Agregar a mi selección',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: FashionColors.grisBorde),
              const SizedBox(height: 16),

              // DESCRIPCIÓN DEL PRODUCTO
              const Text(
                'Descripción de la prenda',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.textoOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                prod.descripcion.isNotEmpty
                    ? prod.descripcion
                    : 'Prenda de confección nacional elaborada con telas de alta calidad, corte estructurado y acabados de precisión boutique.',
                style: const TextStyle(fontSize: 14, height: 1.5, color: FashionColors.textoOscuro),
              ),

              const SizedBox(height: 24),

              // GARANTÍA Y BENEFICIOS BOUTIQUE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FashionColors.fondoClaro,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FashionColors.grisBorde),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 20, color: FashionColors.rosaCorporativo),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Envíos asegurados a toda Colombia (Servientrega, Interrapidísimo, Coordinadora)',
                            style: TextStyle(fontSize: 12, color: FashionColors.textoOscuro),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.verified_outlined, size: 20, color: FashionColors.rosaCorporativo),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Garantía directa de 30 días en costuras y cierres',
                            style: TextStyle(fontSize: 12, color: FashionColors.textoOscuro),
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

        const SizedBox(height: 32),
      ],
    );
  }
}
