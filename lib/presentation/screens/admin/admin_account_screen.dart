// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_data_section.dart';

/// Pantalla Unificada de Configuración de Cuenta de Administrador / Staff.
///
/// Integra directamente el componente de dominio [SeccionMisDatos], eliminando la
/// triangulación y redundancia de perfiles, garantizando una única fuente de verdad
/// para datos personales, avatar y cambio de credenciales de seguridad.
class AdminAccountScreen extends StatelessWidget {
  const AdminAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShellLayout(
      currentPath: '/admin/cuenta',
      child: SeccionMisDatos(),
    );
  }
}
