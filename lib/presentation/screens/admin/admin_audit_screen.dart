// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/audit_text_formatter.dart';
import 'package:fashion_style_mobile/data/services/security_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:google_fonts/google_fonts.dart';

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
                ? const Center(child: CircularProgressIndicator(color: FashionColors.brandAccent))
                : _auditorias.isEmpty
                    ? const Center(child: Text('No hay registros de auditoría'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                        itemCount: _auditorias.length,
                        itemBuilder: (context, index) {
                          final a = _auditorias[index];
                          final fecha = a['created_at']?.toString() ?? '';
                          final desc = AuditTextFormatter.describirAuditoria(a);
                          final dia = AuditTextFormatter.etiquetaDia(fecha);
                          final relativo = AuditTextFormatter.tiempoRelativo(fecha);
                          final usuarioFmt = AuditTextFormatter.formatearUsuario(a['user'] ?? a['usuario']);

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
                            child: ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: FashionColors.surfaceMuted, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.history, color: FashionColors.brandAccent, size: 20),
                              ),
                              title: Text(desc.titulo, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
                              subtitle: Text(
                                '$dia · $relativo · Usuario: $usuarioFmt',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: FashionColors.inkSecondary),
                              ),
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
