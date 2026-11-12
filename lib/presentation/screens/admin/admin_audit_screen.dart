// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
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
  String? _error;
  List<Map<String, dynamic>> _auditorias = [];
  String _filtroModelo = '';
  String _busqueda = '';
  int _pagina = 1;
  int _ultimaPagina = 1;
  int _total = 0;

  final Set<int> _expandidos = {};

  final List<Map<String, dynamic>> _opcionesFiltro = [
    {'etiqueta': 'Todo el historial', 'valor': '', 'icono': Icons.history},
    {'etiqueta': 'Producto', 'valor': 'Producto', 'icono': Icons.checkroom_outlined},
    {'etiqueta': 'Venta', 'valor': 'Venta', 'icono': Icons.point_of_sale_outlined},
    {'etiqueta': 'Pedido', 'valor': 'Pedido', 'icono': Icons.local_shipping_outlined},
    {'etiqueta': 'Inventario', 'valor': 'Inventario', 'icono': Icons.inventory_2_outlined},
    {'etiqueta': 'Producción', 'valor': 'Producc', 'icono': Icons.precision_manufacturing_outlined},
    {'etiqueta': 'Usuario', 'valor': 'User', 'icono': Icons.badge_outlined},
    {'etiqueta': 'Factura', 'valor': 'Factura', 'icono': Icons.receipt_long_outlined},
    {'etiqueta': 'Cliente', 'valor': 'Cliente', 'icono': Icons.people_outline},
  ];

  @override
  void initState() {
    super.initState();
    _cargarAuditorias();
  }

  Future<void> _cargarAuditorias({int pagina = 1}) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final params = <String, dynamic>{
        'page': pagina,
      };
      if (_filtroModelo.isNotEmpty) {
        params['modelo'] = _filtroModelo;
      }

      final res = await SecurityService.instance.obtenerAuditorias(params);
      if (mounted) {
        setState(() {
          _auditorias = res.lista;
          _pagina = res.currentPage;
          _ultimaPagina = res.lastPage;
          _total = res.total;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.obtenerMensajeError(e, 'No se pudo consultar la Bitácora de actividades.');
          _cargando = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _auditoriasFiltradas {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _auditorias;

    return _auditorias.where((item) {
      final user = (item['usuario']?['nombre'] ?? item['usuario']?['correo'] ?? '').toString().toLowerCase();
      final modelo = (item['modelo'] ?? '').toString().toLowerCase();
      final accion = (item['accion'] ?? '').toString().toLowerCase();
      final ip = (item['ip'] ?? '').toString().toLowerCase();
      final datosNuevos = (item['datos_nuevos'] ?? '').toString().toLowerCase();
      final datosAnteriores = (item['datos_anteriores'] ?? '').toString().toLowerCase();

      return user.contains(q) ||
          modelo.contains(q) ||
          accion.contains(q) ||
          ip.contains(q) ||
          datosNuevos.contains(q) ||
          datosAnteriores.contains(q);
    }).toList();
  }

  Color _obtenerColorAccion(String accion) {
    switch (accion.toLowerCase()) {
      case 'created':
        return FashionColors.verdeExito;
      case 'deleted':
        return FashionColors.peligro;
      case 'inicio_sesion':
      case 'login':
        return FashionColors.slateAccent;
      case 'updated':
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData _obtenerIconoAccion(String accion) {
    switch (accion.toLowerCase()) {
      case 'created':
        return Icons.add_circle_outline;
      case 'deleted':
        return Icons.delete_outline;
      case 'inicio_sesion':
      case 'login':
        return Icons.login_outlined;
      case 'updated':
      default:
        return Icons.edit_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _auditoriasFiltradas;

    return AdminShellLayout(
      currentPath: '/admin/seguridad/auditoria',
      child: Container(
        color: FashionColors.backgroundCanvas,
        child: Column(
          children: [
            // BARRA DE CONTROL SUPERIOR
            Container(
              color: FashionColors.backgroundCanvas,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Buscador interactivo
                  TextField(
                    onChanged: (v) => setState(() => _busqueda = v),
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar por responsable, modelo, IP o dato...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: FashionColors.textoMuted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: FashionColors.textoMuted),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _busqueda = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: FashionColors.surfaceSecondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FashionColors.bordeClaro),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FashionColors.bordeClaro),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FashionColors.primaryCorporate, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Selector de módulos con chips horizontales
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _opcionesFiltro.map((opcion) {
                        final val = opcion['valor'] as String;
                        final sel = _filtroModelo == val;
                        final icono = opcion['icono'] as IconData;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            avatar: Icon(icono, size: 15, color: sel ? Colors.white : FashionColors.textoMuted),
                            label: Text(
                              opcion['etiqueta'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel ? Colors.white : FashionColors.textoPrincipal,
                              ),
                            ),
                            selected: sel,
                            selectedColor: FashionColors.primaryCorporate,
                            backgroundColor: FashionColors.surfaceSecondary,
                            side: BorderSide(color: sel ? FashionColors.primaryCorporate : FashionColors.bordeClaro),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            showCheckmark: false,
                            onSelected: (_) {
                              setState(() {
                                _filtroModelo = val;
                                _pagina = 1;
                              });
                              _cargarAuditorias(pagina: 1);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // CONTADOR Y CONTROLES DE PAGINACIÓN RÁPIDA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: FashionColors.arenaSuave,
                border: Border(bottom: BorderSide(color: FashionColors.bordeClaro)),
              ),
              child: Row(
                children: [
                  Text(
                    '$_total registros · Página $_pagina de $_ultimaPagina',
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: FashionColors.textoMuted),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: FashionColors.textoPrincipal),
                    tooltip: 'Recargar bitácora',
                    onPressed: () => _cargarAuditorias(pagina: _pagina),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _pagina > 1 ? () => _cargarAuditorias(pagina: _pagina - 1) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: _pagina < _ultimaPagina ? () => _cargarAuditorias(pagina: _pagina + 1) : null,
                  ),
                ],
              ),
            ),

            // LISTADO DE EVENTOS DE AUDITORÍA
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _cargarAuditorias(pagina: _pagina),
                color: FashionColors.primaryCorporate,
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(color: FashionColors.primaryCorporate))
                    : _error != null
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 40),
                                    const Icon(Icons.error_outline, size: 48, color: FashionColors.peligro),
                                    const SizedBox(height: 12),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(fontSize: 13, color: FashionColors.textoPrincipal),
                                    ),
                                    const SizedBox(height: 14),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: FashionColors.primaryCorporate,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _cargarAuditorias(pagina: 1),
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Reintentar'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : filtradas.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.history, size: 48, color: FashionColors.textoMuted),
                                        const SizedBox(height: 12),
                                        Text(
                                          _busqueda.isNotEmpty
                                              ? 'No hay registros que coincidan con "$_busqueda"'
                                              : 'No hay registros para este módulo',
                                          style: GoogleFonts.poppins(fontSize: 13.5, color: FashionColors.textoMuted),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                                itemCount: filtradas.length,
                                itemBuilder: (context, index) {
                                  final a = filtradas[index];
                                  final id = a['id'] ?? index;
                                  final fecha = a['created_at']?.toString() ?? '';
                                  final desc = AuditTextFormatter.describirAuditoria(a);
                                  final dia = AuditTextFormatter.etiquetaDia(fecha);
                                  final relativo = AuditTextFormatter.tiempoRelativo(fecha);
                                  final usuarioFmt = AuditTextFormatter.formatearUsuario(a['usuario'] ?? a['user']);
                                  final colorAccion = _obtenerColorAccion(a['accion']?.toString() ?? '');
                                  final iconoAccion = _obtenerIconoAccion(a['accion']?.toString() ?? '');
                                  final estaExpandido = _expandidos.contains(id);
                                  final tieneDetalles = desc.cambios.isNotEmpty || desc.datos.isNotEmpty;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: FashionColors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: FashionColors.bordeClaro),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: tieneDetalles
                                          ? () {
                                              setState(() {
                                                if (estaExpandido) {
                                                  _expandidos.remove(id);
                                                } else {
                                                  _expandidos.add(id);
                                                }
                                              });
                                            }
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Badge de acción
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: colorAccion.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(iconoAccion, color: colorAccion, size: 20),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        desc.titulo,
                                                        style: GoogleFonts.montserrat(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                          color: FashionColors.textoPrincipal,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        '$dia · $relativo · $usuarioFmt',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 11,
                                                          color: FashionColors.textoMuted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (tieneDetalles)
                                                  Icon(
                                                    estaExpandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                    size: 20,
                                                    color: FashionColors.textoMuted,
                                                  ),
                                              ],
                                            ),

                                            // DETALLES EXPANDIBLES (CAMBIOS O DATOS REGISTRADOS)
                                            if (estaExpandido && tieneDetalles) ...[
                                              const SizedBox(height: 10),
                                              const Divider(height: 1, color: FashionColors.bordeClaro),
                                              const SizedBox(height: 8),

                                              if (desc.cambios.isNotEmpty) ...[
                                                Text(
                                                  'Campos modificados:',
                                                  style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: FashionColors.textoPrincipal),
                                                ),
                                                const SizedBox(height: 6),
                                                ...desc.cambios.map((c) => Padding(
                                                      padding: const EdgeInsets.only(bottom: 4),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('${c.etiqueta}: ', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.textoMuted)),
                                                          Expanded(
                                                            child: Text(
                                                              '${c.antes} → ${c.nuevo}',
                                                              style: GoogleFonts.poppins(fontSize: 11, color: FashionColors.textoPrincipal),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                              ],

                                              if (desc.datos.isNotEmpty) ...[
                                                Text(
                                                  'Datos del registro:',
                                                  style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: FashionColors.textoPrincipal),
                                                ),
                                                const SizedBox(height: 6),
                                                ...desc.datos.map((d) => Padding(
                                                      padding: const EdgeInsets.only(bottom: 4),
                                                      child: Row(
                                                        children: [
                                                          Text('${d.etiqueta}: ', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.textoMuted)),
                                                          Expanded(
                                                            child: Text(d.valor, style: GoogleFonts.poppins(fontSize: 11, color: FashionColors.textoPrincipal)),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                              ],

                                              if (a['ip'] != null && a['ip'].toString().isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'IP: ${a['ip']}',
                                                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: FashionColors.textoMuted),
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
