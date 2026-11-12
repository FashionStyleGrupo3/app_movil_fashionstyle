// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';

/// Cabecera Nocturna de Autenticación "Nocturnal Atelier Header".
///
/// Implementa un contenedor arquitectónico en `#14161F` con la retícula de sastrería
/// [AtelierPatternBackground], el monograma vectorial [AtelierMonogram] y tipografía en [Space Grotesk].
class AuthBrandBanner extends StatelessWidget {
  final double height;

  const AuthBrandBanner({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: FashionColors.inkPrimary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo vectorial con retícula técnica y puntadas Terracotta
          const AtelierPatternBackground(
            colorFondo: FashionColors.inkPrimary,
            opacidadReticula: 0.08,
            child: SizedBox.expand(),
          ),

          // Gradiente sutil
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.40),
                  ],
                ),
              ),
            ),
          ),

          // Monograma y marca editorial en Space Grotesk
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FASHIONSTYLE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'FASHIONSTYLE OFICIAL',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: FashionColors.brandAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sastrería contemporánea y confección boutique.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FashionColors.surfaceMuted.withValues(alpha: 0.85),
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
