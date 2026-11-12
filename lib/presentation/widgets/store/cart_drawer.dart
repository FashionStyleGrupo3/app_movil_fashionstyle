// @source-mirror: src/components/carrito/CajonCotizacion.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/cart/cart_item.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';

class CartDrawerWidget extends ConsumerWidget {
  const CartDrawerWidget({super.key});

  Future<void> _abrirWhatsApp(BuildContext context, List<CartItem> items) async {
    const numero = '573001234567';
    var texto = 'Hola Servicio al Cliente FashionStyle, requiero asistencia con mi selección:\n';
    if (items.isNotEmpty) {
      for (final item in items) {
        texto += '- ${item.nombre} (Talla: ${item.talla}) x${item.cantidad}\n';
      }
    }

    final url = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(texto)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final items = cartState.items;

    return Container(
      color: FashionColors.canvasBackground,
      child: Column(
        children: [
          // Header del Carrito de Compras
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: FashionColors.surfaceCard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carrito de Compras',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.inkPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${cartState.totalPrendas} prenda(s) seleccionada(s)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: FashionColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: FashionColors.inkPrimary, size: 22),
                  tooltip: 'Cerrar',
                  onPressed: () {
                    ref.read(cartProvider.notifier).cerrarCajon();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: FashionColors.borderSubtle),

          // Lista de Artículos o Estado Vacío
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AtelierEmptyStateIllustration(
                            type: AtelierEmptyStateType.emptyBag,
                            size: 130,
                            title: 'Tu bolsa está vacía',
                            subtitle: 'Explora las piezas exclusivas de nuestro catálogo y viste tu propio estilo.',
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.inkPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.grid_view_rounded, size: 18),
                            label: Text(
                              'Explorar Catálogo',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () {
                              ref.read(cartProvider.notifier).cerrarCajon();
                              Navigator.pop(context);
                              context.go('/catalogo');
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Banner informativo del gesto deslizable
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: FashionColors.surfaceMuted,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swipe_left_rounded, size: 16, color: FashionColors.inkSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Desliza un artículo a la izquierda para retirarlo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: FashionColors.inkSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Dismissible(
                              key: Key('cart_item_${item.varianteId}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: FashionColors.statusDanger,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Retirar',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                  ],
                                ),
                              ),
                              onDismissed: (_) {
                                ref.read(cartProvider.notifier).eliminarPrenda(item.varianteId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"${item.nombre}" retirada de la bolsa'),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'DESHACER',
                                      textColor: FashionColors.brandAccent,
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).actualizarCantidad(item.varianteId, item.cantidad);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: FashionColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: FashionColors.borderSubtle),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Miniatura 3:4 con radio 14px
                                    Container(
                                      width: 68,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: FashionColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: FashionColors.borderSubtle),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: item.imagen.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: item.imagen,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Center(
                                                child: Icon(Icons.checkroom_rounded, size: 24, color: FashionColors.inkMuted),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(Icons.checkroom_rounded, size: 24, color: FashionColors.inkMuted),
                                            ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Info de prenda y variaciones
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nombre,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: FashionColors.inkPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Chip de Talla
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: FashionColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Talla: ${item.talla}',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: FashionColors.inkPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                CurrencyFormatter.formatearCOP(item.precio),
                                                style: FashionTheme.priceTextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: FashionColors.inkPrimary,
                                                ),
                                              ),
                                              if (item.precioOriginal > item.precio) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  CurrencyFormatter.formatearCOP(item.precioOriginal),
                                                  style: FashionTheme.priceTextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    decoration: TextDecoration.lineThrough,
                                                    color: FashionColors.inkSecondary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: FashionColors.statusDanger.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '-${item.porcentajeDescuento}%',
                                                    style: GoogleFonts.jetBrainsMono(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: FashionColors.statusDanger,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          // Steppers táctiles - / +
                                          Row(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: FashionColors.surfaceMuted,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.remove_rounded, size: 16),
                                                      padding: const EdgeInsets.all(4),
                                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                      onPressed: item.cantidad > 1
                                                          ? () {
                                                              ref.read(cartProvider.notifier).actualizarCantidad(
                                                                    item.varianteId,
                                                                    item.cantidad - 1,
                                                                  );
                                                            }
                                                          : null,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: Text(
                                                        '${item.cantidad}',
                                                        style: GoogleFonts.jetBrainsMono(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13,
                                                          color: FashionColors.inkPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add_rounded, size: 16),
                                                      padding: const EdgeInsets.all(4),
                                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                      onPressed: () {
                                                        ref.read(cartProvider.notifier).actualizarCantidad(
                                                              item.varianteId,
                                                              item.cantidad + 1,
                                                            );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: FashionColors.inkSecondary),
                                                tooltip: 'Retirar',
                                                onPressed: () {
                                                  ref.read(cartProvider.notifier).eliminarPrenda(item.varianteId);
                                                },
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
                    ],
                  ),
          ),

          // Sartorial Summary Block & Checkout
          if (items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: FashionColors.surfaceCard,
                border: Border(top: BorderSide(color: FashionColors.borderSubtle)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal estimado',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: FashionColors.inkSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatearCOP(cartState.totalMonto),
                        style: FashionTheme.priceTextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: FashionColors.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.brandAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/carrito');
                      },
                      child: Text(
                        'Proceder al Pago',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: FashionColors.inkPrimary, width: 1.2),
                        foregroundColor: FashionColors.inkPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: Text(
                        'Cotizar / Asistencia por WhatsApp',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () => _abrirWhatsApp(context, items),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
