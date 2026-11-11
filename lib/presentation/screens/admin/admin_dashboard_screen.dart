// @source-mirror: src/views/admin/VistaPanelControl.vue, src/views/admin/VistaInventario.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/dashboard/dashboard_models.dart';
import 'package:fashion_style_mobile/data/models/product/product_filters.dart';
import 'package:fashion_style_mobile/data/services/dashboard_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_inventory_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/chart_helpers.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/stacked_bar_chart.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/payment_method_doughnut_chart.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/production_line_chart.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/stock_alerts_doughnut_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _mesesFiltro = 6;
  bool _cargando = true;
  String? _error;
  DashboardData? _datos;

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  Future<void> _cargarDashboard({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final res = await DashboardService.instance.obtenerDatosDashboard(meses: _mesesFiltro);
      if (mounted) {
        setState(() {
          _datos = res;
          _cargando = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudieron cargar los indicadores del panel.';
        });
      }
    }
  }

  String _obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _obtenerFechaFormateada() {
    final now = DateTime.now();
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final diaSemana = dias[now.weekday - 1];
    final mes = meses[now.month - 1];
    return '$diaSemana, ${now.day} de $mes de ${now.year}';
  }

  Widget _construirKpiCard({
    required String titulo,
    required String valor,
    String? detalle,
    required IconData icono,
    bool esAlerta = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esAlerta ? AdminPalette.rojo.withValues(alpha: 0.5) : FashionColors.borde,
          width: esAlerta ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icono,
                size: 22,
                color: esAlerta ? AdminPalette.rojo : AdminPalette.pizarra,
              ),
              if (esAlerta)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminPalette.rojo,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FashionColors.gris,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.negro,
                ),
              ),
              if (detalle != null && detalle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  detalle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: FashionColors.gris,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaGrafico({
    required String titulo,
    required String subtitulo,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FashionColors.borde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.negro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: FashionColors.gris,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final saludo = _obtenerSaludo();
    final fecha = _obtenerFechaFormateada();
    final primerNombre = authState.nombreUsuario.isNotEmpty
        ? authState.nombreUsuario.split(' ').first
        : 'Administrador';

    final modulos = [
      _ModuloItem(
        titulo: 'Inventario / Kárdex',
        descripcion: 'Control de entradas, salidas, alertas de bajo stock y existencias físicas.',
        ruta: '/admin/inventario',
        icono: Icons.inventory_2_outlined,
        color: const Color(0xFF2563EB),
        fondo: const Color(0xFFEFF6FF),
      ),
      _ModuloItem(
        titulo: 'Punto de Venta (POS)',
        descripcion: 'Caja de mostrador rápida, cobro multimedio y emisión de comprobantes PDF.',
        ruta: '/admin/ventas',
        icono: Icons.receipt_long_outlined,
        color: FashionColors.rosaCorporativo,
        fondo: FashionColors.rosaSuave,
      ),
      _ModuloItem(
        titulo: 'Pedidos y Facturas',
        descripcion: 'Despacho de pedidos online, asignación de guías y facturación DIAN.',
        ruta: '/admin/pedidos',
        icono: Icons.local_shipping_outlined,
        color: const Color(0xFF0D9488),
        fondo: const Color(0xFFF0FDFA),
      ),
      _ModuloItem(
        titulo: 'Gestión de Prendas',
        descripcion: 'Creación de prendas, variantes por talla, precios y campañas de promoción.',
        ruta: '/admin/prendas',
        icono: Icons.checkroom_outlined,
        color: const Color(0xFFD97706),
        fondo: const Color(0xFFFFFBEB),
      ),
      _ModuloItem(
        titulo: 'Producción y Costos',
        descripcion: 'Fórmulas textiles, insumos, órdenes de confección y calculadora de costos.',
        ruta: '/admin/produccion',
        icono: Icons.content_cut_outlined,
        color: const Color(0xFF7C3AED),
        fondo: const Color(0xFFF5F3FF),
      ),
      _ModuloItem(
        titulo: 'Control de Pagos',
        descripcion: 'Pasarela Wompi, concilación bancaria y dispersión a cuentas de ahorro.',
        ruta: '/admin/pagos',
        icono: Icons.account_balance_outlined,
        color: const Color(0xFF059669),
        fondo: const Color(0xFFECFDF5),
      ),
      _ModuloItem(
        titulo: 'Clientes y Usuarios',
        descripcion: 'Administración de usuarios staff, directores y directorio de clientes.',
        ruta: '/admin/seguridad',
        icono: Icons.people_outline,
        color: const Color(0xFF475569),
        fondo: const Color(0xFFF8FAFC),
      ),
      _ModuloItem(
        titulo: 'Tienda Pública',
        descripcion: 'Navega como cliente en el escaparate y verifica los productos publicados.',
        ruta: '/',
        icono: Icons.storefront_outlined,
        color: FashionColors.negroElegante,
        fondo: const Color(0xFFF3F4F6),
      ),
    ];

    final kpis = _datos?.kpis;

    return AdminShellLayout(
      currentPath: '/admin',
      child: RefreshIndicator(
        onRefresh: () => _cargarDashboard(silencioso: true),
        color: AdminPalette.negro,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // BANNER DE BIENVENIDA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AdminPalette.negro,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          authState.esAdmin ? 'ADMINISTRADOR GENERAL' : 'COLABORADOR STAFF',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        fecha,
                        style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$saludo, $primerNombre',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ventas, producción e inventario de FashionStyle en un solo lugar.',
                    style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // BARRA DE FILTRO POR PERIODO Y RECARGA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FashionColors.borde),
              ),
              child: Row(
                children: [
                  Text(
                    'Periodo:',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FashionColors.gris,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final m in [3, 6, 12]) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (_mesesFiltro != m) {
                            setState(() => _mesesFiltro = m);
                            _cargarDashboard();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _mesesFiltro == m ? AdminPalette.negro : AdminPalette.crema,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _mesesFiltro == m ? AdminPalette.negro : AdminPalette.arenaSuave,
                            ),
                          ),
                          child: Text(
                            '$m meses',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _mesesFiltro == m ? Colors.white : AdminPalette.negro,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: _cargando ? null : () => _cargarDashboard(),
                    icon: _cargando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AdminPalette.negro),
                          )
                        : const Icon(Icons.refresh, size: 20, color: AdminPalette.negro),
                    tooltip: 'Actualizar indicadores',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_cargando && _datos == null) ...[
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FashionColors.borde),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AdminPalette.negro),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cargando indicadores del panel...',
                      style: GoogleFonts.montserrat(fontSize: 12, color: FashionColors.gris),
                    ),
                  ],
                ),
              ),
            ] else if (_error != null && _datos == null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminPalette.rojo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminPalette.rojo.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AdminPalette.rojo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.montserrat(fontSize: 12, color: AdminPalette.rojo),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _cargarDashboard(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ] else if (_datos != null) ...[
              // 6 RESUMEN KPIS
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  _construirKpiCard(
                    titulo: 'Ventas de hoy',
                    valor: CurrencyFormatter.formatearCOP(kpis?.ventasHoy ?? 0),
                    icono: Icons.account_balance_wallet_outlined,
                  ),
                  _construirKpiCard(
                    titulo: 'Ventas del mes',
                    valor: CurrencyFormatter.formatearCOP(kpis?.ventasMes ?? 0),
                    detalle: '${kpis?.transaccionesMes ?? 0} transacciones',
                    icono: Icons.receipt_long_outlined,
                  ),
                  _construirKpiCard(
                    titulo: 'Pedidos pendientes',
                    valor: '${kpis?.pedidosPendientes ?? 0}',
                    icono: Icons.local_shipping_outlined,
                  ),
                  _construirKpiCard(
                    titulo: 'Órdenes activas',
                    valor: '${kpis?.ordenesActivas ?? 0}',
                    icono: Icons.content_cut_outlined,
                  ),
                  _construirKpiCard(
                    titulo: 'Stock en bodega',
                    valor: '${kpis?.stockTotal ?? 0}',
                    icono: Icons.inventory_2_outlined,
                  ),
                  _construirKpiCard(
                    titulo: 'Alertas stock',
                    valor: '${kpis?.alertasPendientes ?? 0}',
                    icono: Icons.warning_amber_rounded,
                    esAlerta: (kpis?.alertasPendientes ?? 0) > 0,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // GRÁFICO 1: VENTAS POR MES
              _construirTarjetaGrafico(
                titulo: 'Ventas por mes',
                subtitulo: 'Tienda física (POS) y pedidos pagados en línea.',
                child: StackedBarChartWidget(
                  items: _datos!.ventasPorMes,
                ),
              ),

              const SizedBox(height: 14),

              // GRÁFICO 2: VENTAS POR MEDIO DE PAGO
              _construirTarjetaGrafico(
                titulo: 'Ventas por medio de pago',
                subtitulo: 'Periodo de los últimos $_mesesFiltro meses.',
                child: PaymentMethodDoughnutChartWidget(
                  items: _datos!.ventasPorMedio,
                ),
              ),

              const SizedBox(height: 14),

              // GRÁFICO 3: PRODUCCIÓN (PLANIFICADAS VS COMPLETADAS)
              _construirTarjetaGrafico(
                titulo: 'Producción',
                subtitulo: 'Unidades planificadas frente a completadas e ingresadas al kárdex.',
                child: ProductionLineChartWidget(
                  items: _datos!.produccionPorMes,
                  ordenesPorEstado: _datos!.ordenesPorEstado,
                ),
              ),

              const SizedBox(height: 14),

              // GRÁFICO 4: ALERTAS DE STOCK E INVENTARIO
              _construirTarjetaGrafico(
                titulo: 'Inventario',
                subtitulo: 'Alertas automáticas y existencias críticas.',
                trailing: TextButton(
                  onPressed: () => context.go('/admin/inventario'),
                  child: Text(
                    'Ver kárdex',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminPalette.pizarra,
                    ),
                  ),
                ),
                child: StockAlertsDoughnutWidget(
                  alertasPorNivel: _datos!.inventario.alertasPorNivel,
                  menorStock: _datos!.inventario.menorStock,
                  materiasBajoMinimo: _datos!.inventario.materiasBajoMinimo,
                  onVerKardex: () => context.go('/admin/inventario'),
                ),
              ),
            ],

            const SizedBox(height: 24),

            Text(
              'Módulos del Sistema',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FashionColors.textoOscuro,
              ),
            ),
            const SizedBox(height: 12),

            // GRID DE TARJETAS DE MÓDULOS
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modulos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final m = modulos[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.go(m.ruta),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FashionColors.grisBorde),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: m.fondo, borderRadius: BorderRadius.circular(10)),
                          child: Icon(m.icono, color: m.color, size: 24),
                        ),
                        const Spacer(),
                        Text(
                          m.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FashionColors.textoOscuro),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: FashionColors.textoMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ModuloItem {
  final String titulo;
  final String descripcion;
  final String ruta;
  final IconData icono;
  final Color color;
  final Color fondo;

  const _ModuloItem({
    required this.titulo,
    required this.descripcion,
    required this.ruta,
    required this.icono,
    required this.color,
    required this.fondo,
  });
}

// ============================================================================
// 2. INVENTARIO Y KÁRDEX (VistaInventario.vue)
// ============================================================================
