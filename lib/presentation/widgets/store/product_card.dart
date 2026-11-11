// @source-mirror: src/components/escaparate/TarjetaProducto.vue, src/components/escaparate/ModalGuiaMedidas.vue, src/components/carrito/CajonCotizacion.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/cart/cart_item.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/price_info.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/cart_drawer.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/size_guide_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductCardWidget extends ConsumerWidget {
  final Product producto;
  final List<Promotion> promocionesVigentes;

  const ProductCardWidget({
    super.key,
    required this.producto,
    this.promocionesVigentes = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final favoritesState = ref.watch(favoritesProvider);
    final esFavorito = favoritesState.esFavorito(producto.idProducto);

    final variantes = producto.variantes;
    final stockTotal = producto.stockTotal;
    final agotado = stockTotal <= 0;
    final deshabilitado = !producto.activo || agotado;

    final precioMinimo = producto.precioMinimo;
    final precios = variantes.map((v) => v.precioVenta).where((p) => p > 0).toSet();
    final preciosDistintos = precios.length > 1;

    final infoPrecio = PromotionService.instance.calcularPrecioPromocional(
      producto,
      precioMinimo,
      promocionesVigentes,
    );

    final subtituloPartes = [
      producto.categoria?.nombre,
      producto.catalogo?.nombre,
    ].where((s) => s != null && s.isNotEmpty).toList();
    final subtitulo = subtituloPartes.join(' • ');

    return GestureDetector(
      onTap: deshabilitado
          ? null
          : () {
              context.push('/producto/${producto.idProducto}');
            },
      child: Container(
        decoration: BoxDecoration(
          color: FashionColors.blanco,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FashionColors.borde),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto y badges superiores
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: FashionColors.arenaSuave,
                    child: producto.primeraImagenUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: producto.primeraImagenUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: FashionColors.arenaSuave,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: FashionColors.pizarra,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: FashionColors.arenaSuave,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: FashionColors.gris,
                                size: 36,
                              ),
                            ),
                          )
                        : Container(
                            color: FashionColors.arenaSuave,
                            child: const Icon(
                              Icons.checkroom_outlined,
                              color: FashionColors.gris,
                              size: 40,
                            ),
                          ),
                  ),

                  // Insignia superior izquierda
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Builder(
                      builder: (context) {
                        if (infoPrecio.tieneDescuento && !deshabilitado) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: FashionColors.rosaCorporativo,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${infoPrecio.porcentaje}%',
                              style: const TextStyle(
                                color: FashionColors.blanco,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        } else if (agotado) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: FashionColors.rojo,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Agotado',
                              style: TextStyle(
                                color: FashionColors.blanco,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        } else if (stockTotal > 0 && stockTotal <= 5) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC2410C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Últimas piezas',
                              style: TextStyle(
                                color: FashionColors.blanco,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // Botón de Favorito superior derecho
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          ref.read(favoritesProvider.notifier).alternar(
                                producto.idProducto,
                                estaAutenticado: authState.estaAutenticado,
                              );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: FashionColors.blanco.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: esFavorito ? FashionColors.rojo : FashionColors.texto,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overlay si está deshabilitado
                  if (deshabilitado)
                    Container(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                ],
              ),
            ),

            // Información de texto inferior
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FashionColors.negro,
                    ),
                  ),
                  if (subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: FashionColors.gris,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (precioMinimo <= 0)
                    const Text(
                      'Precio por confirmar',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: FashionColors.gris,
                      ),
                    )
                  else
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        if (preciosDistintos)
                          const Text(
                            'Desde ',
                            style: TextStyle(
                              fontSize: 11,
                              color: FashionColors.gris,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Text(
                          CurrencyFormatter.formatearCOP(infoPrecio.precioFinal),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: infoPrecio.tieneDescuento
                                ? FashionColors.rosaCorporativo
                                : FashionColors.negro,
                          ),
                        ),
                        if (infoPrecio.tieneDescuento)
                          Text(
                            CurrencyFormatter.formatearCOP(infoPrecio.precioOriginal),
                            style: const TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: FashionColors.gris,
                            ),
                          ),
                      ],
                    ),
                  if (deshabilitado) ...[
                    const SizedBox(height: 4),
                    Text(
                      !producto.activo ? 'No disponible' : 'Agotado',
                      style: const TextStyle(
                        fontSize: 11,
                        color: FashionColors.rojo,
                        fontWeight: FontWeight.w600,
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
}

// --- MODAL DE GUÍA DE MEDIDAS (SizeGuideModal) ---
