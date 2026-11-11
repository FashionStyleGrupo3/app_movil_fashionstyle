// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/fashion_brand_emblem.dart';

class AuthBrandBanner extends StatelessWidget {
  final double height;

  const AuthBrandBanner({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUrlResolver.resolve('img/login-modelo.jpg');

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen del backend con fallback offline limpio a asset local
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Image.asset(
              ImageUrlResolver.loginPlaceholderAsset,
              fit: BoxFit.cover,
            ),
            errorWidget: (context, url, error) => Image.asset(
              ImageUrlResolver.loginPlaceholderAsset,
              fit: BoxFit.cover,
            ),
          ),
          // Superposición degradada oscura para contraste editorial
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          // Tipografía corporativa con el Emblema Oficial
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FashionBrandEmblem(
                      size: 28,
                      conSombra: false,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'FASHIONSTYLE',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Boutique & Atelier Oficial · Moda de Alta Gama',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
