// @source-mirror: src/components/escaparate/TarjetaProducto.vue, src/components/escaparate/ModalGuiaMedidas.vue, src/components/carrito/CajonCotizacion.vue
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
import 'package:fashion_style_mobile/presentation/widgets/common/fashion_brand_emblem.dart';

class CartDrawerWidget extends ConsumerWidget {
  const CartDrawerWidget({super.key});

  Future<void> _abrirWhatsApp(BuildContext context, List<CartItem> items) async {
    const numero = '573001234567';
    var texto = 'Hola Servicio al Cliente FashionStyle, requiero asistencia con mi pedido.\n';
    if (items.isNotEmpty) {
      texto += 'Tengo dudas sobre los siguientes artículos en mi bolsa:\n';
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

    return SafeArea(
      child: Column(
        children: [
          // Drag handle gestual en la parte superior para indicar que se puede deslizar
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FashionColors.borde,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FashionBrandEmblem(size: 26, conSombra: false),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bolsa de Compras',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.negro,
                          ),
                        ),
                        Text(
                          '${cartState.totalPrendas} prenda(s) seleccionada(s)',
                          style: const TextStyle(fontSize: 11, color: FashionColors.gris),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: FashionColors.texto),
                  tooltip: 'Cerrar bolsa',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items List con gestos Dismissible
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FashionBrandEmblem(size: 64, conSombra: true),
                          const SizedBox(height: 18),
                          Text(
                            'Tu bolsa de compras está vacía',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: FashionColors.negro,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Explora las piezas exclusivas de nuestro atelier y agrégalas a tu selección.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: FashionColors.gris),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.negro,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.grid_view_rounded, size: 18),
                            label: const Text('Explorar Catálogo'),
                            onPressed: () {
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
                      // Banner informativo sutil del gesto deslizable
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: FashionColors.arenaSuave,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swipe_left_rounded, size: 16, color: FashionColors.pizarra),
                            SizedBox(width: 6),
                            Text(
                              'Desliza un artículo a la izquierda para eliminarlo',
                              style: TextStyle(fontSize: 11, color: FashionColors.pizarra, fontWeight: FontWeight.w500),
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
                                  color: FashionColors.rojo,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    SizedBox(width: 6),
                                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
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
                                      textColor: FashionColors.arenaOscura,
                                      onPressed: () {
                                        // Restaurar item
                                        ref.read(cartProvider.notifier).actualizarCantidad(item.varianteId, item.cantidad);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: FashionColors.blanco,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: FashionColors.borde),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Imagen miniatura
                                    Container(
                                      width: 64,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: FashionColors.arenaSuave,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: item.imagen.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: item.imagen,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(
                                                Icons.image_not_supported_outlined,
                                                size: 24,
                                                color: FashionColors.gris,
                                              ),
                                            )
                                          : const Icon(Icons.checkroom_outlined, color: FashionColors.gris),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info prenda
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nombre,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: FashionColors.negro,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Talla: ${item.talla}',
                                            style: const TextStyle(fontSize: 12, color: FashionColors.gris),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                CurrencyFormatter.formatearCOP(item.precio),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: FashionColors.negro,
                                                ),
                                              ),
                                              if (item.precioOriginal > item.precio) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  CurrencyFormatter.formatearCOP(item.precioOriginal),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    decoration: TextDecoration.lineThrough,
                                                    color: FashionColors.gris,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Controles de cantidad táctiles
                                          Row(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: FashionColors.arenaSuave,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.remove, size: 16),
                                                      padding: const EdgeInsets.all(4),
                                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                      onPressed: () {
                                                        ref.read(cartProvider.notifier).actualizarCantidad(
                                                              item.varianteId,
                                                              item.cantidad - 1,
                                                            );
                                                      },
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: Text(
                                                        '${item.cantidad}',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add, size: 16),
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
                                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: FashionColors.gris),
                                                tooltip: 'Eliminar',
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

          // Footer / Checkout
          if (items.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal estimado',
                        style: TextStyle(fontSize: 14, color: FashionColors.gris),
                      ),
                      Text(
                        CurrencyFormatter.formatearCOP(cartState.totalMonto),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: FashionColors.negro,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.negro,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/carrito');
                      },
                      child: const Text(
                        'Proceder al pago',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                      foregroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Cotizar / Asistencia por WhatsApp'),
                    onPressed: () => _abrirWhatsApp(context, items),
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
