// @source-mirror: src/components/escaparate/TarjetaProducto.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';

/// Tarjeta de prenda editorial lookbook con proporción 3:4, estética Neo-Atelier
/// y tipografía Space Grotesk / Plus Jakarta Sans / JetBrains Mono.
class ProductCardWidget extends ConsumerStatefulWidget {
  final Product producto;
  final List<Promotion> promocionesVigentes;

  const ProductCardWidget({
    super.key,
    required this.producto,
    this.promocionesVigentes = const [],
  });

  @override
  ConsumerState<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends ConsumerState<ProductCardWidget> {
  bool _quickAddActive = false;

  void _onQuickAdd() {
    setState(() => _quickAddActive = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _quickAddActive = false);
    });

    final variantes = widget.producto.variantes;
    if (variantes.length == 1 && variantes.first.stock > 0) {
      ref.read(cartProvider.notifier).agregarPrenda(
            widget.producto,
            variantes.first,
            1,
          );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Se agregó ${widget.producto.nombre} a tu carrito!'),
          duration: const Duration(milliseconds: 1600),
          action: SnackBarAction(
            label: 'VER CARRITO',
            textColor: FashionColors.arena,
            onPressed: () => context.go('/carrito'),
          ),
        ),
      );
    } else {
      context.push('/producto/${widget.producto.idProducto}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final favoritesState = ref.watch(favoritesProvider);
    final esFavorito = favoritesState.esFavorito(widget.producto.idProducto);

    final variantes = widget.producto.variantes;
    final stockTotal = widget.producto.stockTotal;
    final agotado = stockTotal <= 0;
    final deshabilitado = !widget.producto.activo || agotado;

    final precioMinimo = widget.producto.precioMinimo;
    final precios = variantes.map((v) => v.precioVenta).where((p) => p > 0).toSet();
    final preciosDistintos = precios.length > 1;

    final infoPrecio = PromotionService.instance.calcularPrecioPromocional(
      widget.producto,
      precioMinimo,
      widget.promocionesVigentes,
    );

    final categoriaNombre = widget.producto.categoria?.nombre.toUpperCase() ?? 'COLECCIÓN';

    return GestureDetector(
      onTap: deshabilitado
          ? null
          : () {
              context.push('/producto/${widget.producto.idProducto}');
            },
      child: Container(
        decoration: BoxDecoration(
          color: FashionColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FashionColors.borderSubtle, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lookbook Image Frame con proporción aproximada 3:4
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: FashionColors.surfaceMuted,
                    child: widget.producto.primeraImagenUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.producto.primeraImagenUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 600,
                            placeholder: (context, url) => Container(
                              color: FashionColors.surfaceMuted,
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: FashionColors.inkSecondary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),

                  // Insignia superior izquierda (Descuento / Stock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Builder(
                      builder: (context) {
                        if (infoPrecio.tieneDescuento && !deshabilitado) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: FashionColors.brandAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '-${infoPrecio.porcentaje}%',
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          );
                        } else if (agotado) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: FashionColors.statusDanger,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Agotado',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        } else if (stockTotal > 0 && stockTotal <= 5) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: FashionColors.editorialOchre,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Últimas piezas',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // Botón de Favorito superior derecho (#FFFFFF con 0.92 alpha)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          ref.read(favoritesProvider.notifier).alternar(
                                widget.producto.idProducto,
                                estaAutenticado: authState.estaAutenticado,
                              );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            border: Border.all(color: FashionColors.borderSubtle, width: 0.8),
                          ),
                          child: Icon(
                            esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: esFavorito ? FashionColors.statusDanger : FashionColors.inkPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Botón táctil Quick-Add inferior derecho de la imagen (38x38, radius 12px)
                  if (!deshabilitado)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _onQuickAdd,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _quickAddActive ? FashionColors.brandAccent : FashionColors.inkPrimary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: FashionColors.inkPrimary.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Overlay si está deshabilitado
                  if (deshabilitado)
                    Container(
                      color: Colors.white.withValues(alpha: 0.60),
                    ),
                ],
              ),
            ),

            // Bloque de información inferior
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Categoría Kicker (Space Grotesk 10px, uppercase)
                  Text(
                    categoriaNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: FashionColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Nombre de Prenda (Plus Jakarta Sans w600)
                  Text(
                    widget.producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: FashionColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Precio COP (JetBrains Mono tabular figures)
                  if (precioMinimo <= 0)
                    Text(
                      'Precio por confirmar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: FashionColors.inkSecondary,
                      ),
                    )
                  else
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        if (preciosDistintos)
                          Text(
                            'Desde ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: FashionColors.inkSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Text(
                          CurrencyFormatter.formatearCOP(infoPrecio.precioFinal),
                          style: FashionTheme.priceTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: infoPrecio.tieneDescuento
                                ? FashionColors.brandAccent
                                : FashionColors.inkPrimary,
                          ),
                        ),
                        if (infoPrecio.tieneDescuento)
                          Text(
                            CurrencyFormatter.formatearCOP(infoPrecio.precioOriginal),
                            style: FashionTheme.priceTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                              color: FashionColors.inkSecondary,
                            ),
                          ),
                      ],
                    ),
                  if (deshabilitado) ...[
                    const SizedBox(height: 4),
                    Text(
                      !widget.producto.activo ? 'No disponible' : 'Agotado',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: FashionColors.statusDanger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: FashionColors.surfaceMuted,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checkroom_rounded, size: 36, color: FashionColors.inkMuted),
            const SizedBox(height: 6),
            Text(
              'COLECCIÓN',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: FashionColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
