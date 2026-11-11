// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/constants/payment_constants.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/audit_text_formatter.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/models/audit/audit_models.dart';
import 'package:fashion_style_mobile/data/models/payment/bank_account_config.dart';
import 'package:fashion_style_mobile/data/models/payment/parallel_payment_control.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_detail.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_model.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sales_summary.dart';
import 'package:fashion_style_mobile/data/services/payment_config_service.dart';
import 'package:fashion_style_mobile/data/services/pos_sale_service.dart';
import 'package:fashion_style_mobile/data/services/security_service.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_account_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_payments_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_security_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/forgot_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/login_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/register_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/reset_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/verify_email_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/auth_brand_banner.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/password_requirements_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  bool _cargando = true;
  List<Map<String, dynamic>> _auditorias = [];
  String _filtroModelo = '';

  @override
  void initState() {
    super.initState();
    _cargarAuditorias();
  }

  Future<void> _cargarAuditorias() async {
    setState(() => _cargando = true);
    try {
      final res = await SecurityService.instance.obtenerAuditorias(
        _filtroModelo.isNotEmpty ? {'modelo': _filtroModelo} : null,
      );
      if (mounted) {
        setState(() {
          _auditorias = res.lista;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelos = ['', 'Producto', 'Venta', 'Inventario', 'User'];

    return AdminShellLayout(
      currentPath: '/admin/seguridad/auditoria',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: modelos.map((m) {
                  final sel = _filtroModelo == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(m.isEmpty ? 'Todo el historial' : m, style: TextStyle(fontSize: 11, color: sel ? Colors.white : FashionColors.textoOscuro)),
                      selected: sel,
                      selectedColor: FashionColors.negroElegante,
                      onSelected: (_) {
                        setState(() => _filtroModelo = m);
                        _cargarAuditorias();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
                : _auditorias.isEmpty
                    ? const Center(child: Text('No hay registros de auditoría'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _auditorias.length,
                        itemBuilder: (context, index) {
                          final a = _auditorias[index];
                          final fecha = a['created_at']?.toString() ?? '';
                          final desc = AuditTextFormatter.describirAuditoria(a);
                          final dia = AuditTextFormatter.etiquetaDia(fecha);
                          final relativo = AuditTextFormatter.tiempoRelativo(fecha);
                          final usuarioFmt = AuditTextFormatter.formatearUsuario(a['user'] ?? a['usuario']);

                          return Card(
                            elevation: 0.5,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.history, color: FashionColors.pizarra),
                              title: Text(desc.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('$dia · $relativo · Usuario: $usuarioFmt', style: const TextStyle(fontSize: 11, color: FashionColors.textoMuted)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. CONFIGURACIÓN DE CUENTA STAFF (VistaEditarCuenta.vue)
// ============================================================================
