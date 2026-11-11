// @source-mirror: src/components/escaparate/ModalGuiaMedidas.vue
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';

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
        height: MediaQuery.of(context).size.height * 0.86,
        decoration: const BoxDecoration(
          color: FashionColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: FashionColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Cabecera modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AtelierMonogram(size: 28),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.straighten_rounded, size: 16, color: FashionColors.brandAccent),
                              const SizedBox(width: 5),
                              Text(
                                'GUÍA DE TALLAS ATELIER',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: FashionColors.brandAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Medidas Corporales',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: FashionColors.inkPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Referencia anatómica en centímetros (cm)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: FashionColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: FashionColors.inkPrimary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: FashionColors.borderSubtle),

            // Contenido con tabla arquitectónica e indicaciones
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabla de medidas arquitectónica
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: FashionColors.borderSubtle),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Table(
                        border: TableBorder.symmetric(
                          inside: const BorderSide(color: FashionColors.borderSubtle, width: 0.8),
                        ),
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: FashionColors.inkPrimary),
                            children: [
                              _buildHeaderCell('Talla'),
                              _buildHeaderCell('Busto'),
                              _buildHeaderCell('Cintura'),
                              _buildHeaderCell('Cadera'),
                              _buildHeaderCell('Largo'),
                            ],
                          ),
                          ...medidas.map(
                            (m) => TableRow(
                              decoration: BoxDecoration(
                                color: m['talla'] == 'M'
                                    ? FashionColors.surfaceMuted.withValues(alpha: 0.5)
                                    : FashionColors.surfaceCard,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Text(
                                    m['talla']!,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: FashionColors.inkPrimary,
                                    ),
                                  ),
                                ),
                                _buildDataCell(m['busto']!),
                                _buildDataCell(m['cintura']!),
                                _buildDataCell(m['cadera']!),
                                _buildDataCell(m['largo']!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cómo tomar medidas (Tarjeta Mineral)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: FashionColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FashionColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: FashionColors.brandAccent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '¿CÓMO TOMAR TUS MEDIDAS?',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: FashionColors.inkPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildMeasureTip('Busto', 'Rodea la parte más amplia del pecho manteniendo la cinta horizontal.'),
                          _buildMeasureTip('Cintura', 'Mide alrededor de la parte más estrecha del torso, sin apretar.'),
                          _buildMeasureTip('Cadera', 'Rodea la parte más amplia de la cadera y los glúteos.'),
                          _buildMeasureTip('Largo', 'Compara el largo indicado con una prenda propia que te quede cómoda.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Estas medidas son orientativas y corresponden a la confección estándar de sastrería. Si estás entre dos tallas, te sugerimos elegir la mayor para permitir entalle personalizado.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: FashionColors.inkSecondary,
                        height: 1.45,
                      ),
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

  static Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FashionColors.inkPrimary,
        ),
      ),
    );
  }

  static Widget _buildMeasureTip(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkPrimary),
          children: [
            TextSpan(
              text: '$title: ',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
            ),
            TextSpan(
              text: desc,
              style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
