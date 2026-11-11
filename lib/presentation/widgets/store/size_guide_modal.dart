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
import 'package:fashion_style_mobile/presentation/widgets/store/product_card.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
