// @source-mirror: src/components/escaparate/TarjetaProducto.vue, src/components/escaparate/ModalGuiaMedidas.vue, src/components/carrito/CajonCotizacion.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/fashion_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_models.dart';
import '../../data/services/promotion_service.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';

// --- TARJETA DE PRODUCTO (ProductCardWidget) ---

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
                            color: FashionColors.blanco.withOpacity(0.9),
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
                      color: Colors.white.withOpacity(0.55),
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

class SizeGuideModal {
  static const List<Map<String, String>> medidas = [
    {'talla': 'XS', 'busto': '78–82', 'cintura': '60–64', 'cadera': '84–88', 'largo': '54–56'},
    {'talla': 'S', 'busto': '83–87', 'cintura': '65–69', 'cadera': '89–93', 'largo': '56–58'},
    {'talla': 'M', 'busto': '88–92', 'cintura': '70–74', 'cadera': '94–98', 'largo': '58–60'},
    {'talla': 'L', 'busto': '93–99', 'cintura': '75–81', 'cadera': '99–105', 'largo': '60–62'},
    {'talla': 'XL', 'busto': '100–106', 'cintura': '82–88', 'cadera': '106–112', 'largo': '62–64'},
  ];

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: FashionColors.blanco,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Cabecera modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.straighten_rounded, size: 18, color: FashionColors.rosaCorporativo),
                          SizedBox(width: 6),
                          Text(
                            'GUÍA DE TALLAS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: FashionColors.rosaCorporativo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Medidas corporales',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: FashionColors.negro,
                        ),
                      ),
                      const Text(
                        'Medidas de referencia en centímetros (cm)',
                        style: TextStyle(fontSize: 12, color: FashionColors.gris),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: FashionColors.gris),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Contenido con tabla e indicaciones
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabla de medidas
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: FashionColors.borde),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Table(
                        border: TableBorder.symmetric(
                          inside: const BorderSide(color: FashionColors.borde, width: 0.5),
                        ),
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: FashionColors.arenaSuave),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Talla', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Busto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Cintura', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Cadera', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Largo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ],
                          ),
                          ...medidas.map(
                            (m) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(m['talla']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(m['busto']!, style: const TextStyle(fontSize: 12)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(m['cintura']!, style: const TextStyle(fontSize: 12)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(m['cadera']!, style: const TextStyle(fontSize: 12)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(m['largo']!, style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cómo tomar medidas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FashionColors.crema,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FashionColors.borde),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Cómo tomar tus medidas?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: FashionColors.negro,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildMeasureTip('Busto', 'Rodea la parte más amplia del pecho manteniendo la cinta horizontal.'),
                          _buildMeasureTip('Cintura', 'Mide alrededor de la parte más estrecha del torso, sin apretar.'),
                          _buildMeasureTip('Cadera', 'Rodea la parte más amplia de la cadera y los glúteos.'),
                          _buildMeasureTip('Largo', 'Compara el largo indicado con una prenda propia que te quede cómoda.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Estas medidas son orientativas y pueden variar según el corte, la tela y la silueta del modelo. Si estás entre dos tallas, te sugerimos elegir la mayor.',
                      style: TextStyle(fontSize: 11, color: FashionColors.gris, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMeasureTip(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.montserrat(fontSize: 12, color: FashionColors.texto),
          children: [
            TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: desc),
          ],
        ),
      ),
    );
  }
}

// --- CAJÓN DE BOLSA DE COMPRAS (CartDrawerWidget) ---

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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bolsa de Compras',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: FashionColors.negro,
                      ),
                    ),
                    Text(
                      '${cartState.totalPrendas} prenda(s) seleccionada(s)',
                      style: const TextStyle(fontSize: 12, color: FashionColors.gris),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: FashionColors.texto),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 56, color: FashionColors.borde),
                          const SizedBox(height: 14),
                          Text(
                            'Tu bolsa de compras está vacía.',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: FashionColors.texto,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Explora el escaparate y añade tus piezas favoritas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: FashionColors.gris),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FashionColors.blanco,
                          borderRadius: BorderRadius.circular(10),
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
                                          color: FashionColors.rosaCorporativo,
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

                                  // Controles cantidad
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: FashionColors.borde),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                ref
                                                    .read(cartProvider.notifier)
                                                    .actualizarCantidad(item.varianteId, item.cantidad - 1);
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.remove, size: 14, color: FashionColors.texto),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '${item.cantidad}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                ref
                                                    .read(cartProvider.notifier)
                                                    .actualizarCantidad(item.varianteId, item.cantidad + 1);
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.add, size: 14, color: FashionColors.texto),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: FashionColors.rojo),
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
                      );
                    },
                  ),
          ),

          // Footer
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: FashionColors.arenaSuave,
                border: Border(top: BorderSide(color: FashionColors.borde)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total estimado',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FashionColors.texto,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatearCOP(cartState.totalMonto),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: FashionColors.rosaCorporativo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_outline_rounded, size: 16),
                      label: const Text('Ir a pagar / Completar pedido'),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/carrito');
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).vaciarCarrito();
                    },
                    child: const Text('Vaciar bolsa', style: TextStyle(fontSize: 12, color: FashionColors.gris)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF047857)),
                    label: const Text('Asistencia por WhatsApp', style: TextStyle(color: Color(0xFF047857))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      backgroundColor: const Color(0xFFECFDF5),
                    ),
                    onPressed: () => _abrirWhatsApp(context, items),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
