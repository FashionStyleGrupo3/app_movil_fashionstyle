import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';

/// Emblema e isotipo oficial de FashionStyle Boutique & Atelier (Neo-Atelier).
///
/// Representa el octágono sartorial con monograma FS entrelazado
/// y acento de puntada diagonal Terracotta (#B83A24).
class FashionBrandEmblem extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color fillColor;
  final bool conSombra;

  const FashionBrandEmblem({
    super.key,
    this.size = 36,
    this.primaryColor = FashionColors.inkPrimary,
    this.secondaryColor = FashionColors.inkSecondary,
    this.accentColor = FashionColors.brandAccent,
    this.fillColor = FashionColors.surfaceCard,
    this.conSombra = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: conSombra
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            )
          : null,
      child: AtelierMonogram(
        size: size,
        primaryColor: primaryColor,
        accentColor: accentColor,
        surfaceColor: fillColor,
      ),
    );
  }
}

/// Cabecera de marca con isotipo y tipografía editorial Neo-Atelier (Space Grotesk + Plus Jakarta Sans).
class FashionBrandHeader extends StatelessWidget {
  final double emblemSize;
  final bool compacto;
  final VoidCallback? onTap;

  const FashionBrandHeader({
    super.key,
    this.emblemSize = 32,
    this.compacto = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FashionBrandEmblem(
            size: emblemSize,
            conSombra: false,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FASHIONSTYLE',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: compacto ? 15 : 17,
                  letterSpacing: -0.4,
                  color: FashionColors.inkPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                'FASHIONSTYLE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: compacto ? 8 : 9,
                  letterSpacing: 1.6,
                  color: FashionColors.brandAccent,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
