// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FashionColors.fondoClaro,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FashionColors.grisBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requisitos de seguridad:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FashionColors.textoOscuro),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 4.8,
            children: requisitosPassword.map((req) {
              final ok = req.cumple(password);
              return Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 14,
                    color: ok ? FashionColors.verdeExito : FashionColors.textoMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      req.texto,
                      style: TextStyle(
                        fontSize: 11,
                        color: ok ? FashionColors.verdeExito : FashionColors.textoMuted,
                        fontWeight: ok ? FontWeight.w600 : FontWeight.normal,
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

// ============================================================================
// BANNER VISUAL DE AUTENTICACIÓN (Espejo DisenoAutenticacion.vue)
// ============================================================================
