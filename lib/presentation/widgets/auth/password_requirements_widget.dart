// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';

class PasswordRequirementsWidget extends StatelessWidget {
  final String password;

  const PasswordRequirementsWidget({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FashionColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FashionColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: FashionColors.inkPrimary),
              const SizedBox(width: 6),
              Text(
                'Requisitos de seguridad:',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.inkPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 4.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 4,
            children: requisitosPassword.map((req) {
              final ok = req.cumple(password);
              return Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 15,
                    color: ok ? FashionColors.statusSuccess : FashionColors.inkSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      req.texto,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: ok ? FashionColors.statusSuccess : FashionColors.inkSecondary,
                        fontWeight: ok ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
