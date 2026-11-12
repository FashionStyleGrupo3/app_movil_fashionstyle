import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';

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
    return const SizedBox.shrink();
  }
}

/// Cabecera de marca con tipografía editorial oficial (Space Grotesk).
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
      child: Text(
        'FASHIONSTYLE',
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: compacto ? 15 : 18,
          letterSpacing: -0.4,
          color: FashionColors.inkPrimary,
          height: 1.1,
        ),
      ),
    );
  }
}
