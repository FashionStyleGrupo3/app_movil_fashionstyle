// @source-mirror: src/views/admin/VistaPanelControl.vue, src/views/admin/VistaInventario.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/dashboard_service.dart';
import '../../layouts/admin_shell_layout.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin/admin_charts.dart';

// ============================================================================
// 1. PANEL DE CONTROL ADMINISTRATIVO (VistaPanelControl.vue)
// ============================================================================

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

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _cargando = true;
  String? _error;

  List<_VarianteInventario> _todasLasVariantes = [];

  // Pestaña Kardex
  List<Map<String, dynamic>> _movimientos = [];
  Map<String, dynamic> _resumenKardex = {
    'total_movimientos': 0,
    'entradas': 0,
    'salidas': 0,
    'ajustes': 0,
    'anulados': 0,
  };
  final String _filtroTipoKardex = '';
  String _busquedaKardex = '';

  // Filtros Existencias
  String _busquedaExistencias = '';
  String _filtroDisponibilidad = 'todos'; // 'todos' | 'en_stock' | 'bajo_stock' | 'agotados'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatosInventario();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosInventario() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final prods = await ProductService.instance.obtenerProductos();

      // Aplanar variantes para existencias
      final listaVariantes = <_VarianteInventario>[];
      for (final p in prods) {
        for (final v in p.variantes) {
          listaVariantes.add(_VarianteInventario(
            varianteId: v.idVariante,
            productoId: p.idProducto,
            nombrePrenda: p.nombre,
            talla: v.talla,
            sku: v.sku,
            precioVenta: v.precioVenta,
            stock: v.stock,
            imagenUrl: p.primeraImagenUrl,
            color: p.original['color']?.toString() ?? 'Estándar',
          ));
        }
      }

      // Cargar movimientos de Kardex
      Map<String, dynamic> resumen = {};
      List<Map<String, dynamic>> movs = [];
      try {
        final res = await ApiClient.instance.dio.get('/inventarios');
        final data = ApiResponseParser.extractData(res);
        if (data is Map<String, dynamic>) {
          resumen = data['resumen'] is Map<String, dynamic> ? data['resumen'] : {};
          final listaRaw = data['movimientos'] ?? data['data'];
          if (listaRaw is List) {
            movs = listaRaw.whereType<Map<String, dynamic>>().toList();
          }
        } else if (data is List) {
          movs = data.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _todasLasVariantes = listaVariantes;
          _movimientos = movs;
          _resumenKardex = {
            'total_movimientos': resumen['total_movimientos'] ?? movs.length,
            'entradas': resumen['entradas'] ?? movs.where((m) => m['tipo_movimiento'] == 'entrada').length,
            'salidas': resumen['salidas'] ?? movs.where((m) => m['tipo_movimiento'] == 'salida').length,
            'ajustes': resumen['ajustes'] ?? movs.where((m) => m['tipo_movimiento'] == 'ajuste').length,
            'anulados': resumen['anulados'] ?? movs.where((m) => m['estado'] == 'anulado').length,
          };
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar los datos del inventario: $e';
          _cargando = false;
        });
      }
    }
  }

  void _abrirModalRegistrarMovimiento([_VarianteInventario? varianteInicial]) {
    _VarianteInventario? seleccionada = varianteInicial ?? (_todasLasVariantes.isNotEmpty ? _todasLasVariantes.first : null);
    String tipo = 'entrada';
    final TextEditingController cantCtrl = TextEditingController(text: '1');
    final TextEditingController conceptoCtrl = TextEditingController();
    final TextEditingController obsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Registrar Movimiento de Kárdex',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),

                    // Selector de prenda y variante
                    DropdownButtonFormField<_VarianteInventario>(
                      initialValue: seleccionada,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Prenda y Talla', border: OutlineInputBorder()),
                      items: _todasLasVariantes.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            '${v.nombrePrenda} (${v.talla}) · Stock: ${v.stock}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => seleccionada = val),
                    ),
                    const SizedBox(height: 12),

                    // Tipo de movimiento
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: const InputDecoration(labelText: 'Tipo de movimiento', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'entrada', child: Text('Entrada (+) - Abastecimiento/Producción')),
                        DropdownMenuItem(value: 'salida', child: Text('Salida (-) - Venta externa/Avería')),
                        DropdownMenuItem(value: 'ajuste', child: Text('Ajuste (=) - Corrección por conteo')),
                      ],
                      onChanged: (val) => setModalState(() => tipo = val ?? 'entrada'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: cantCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad de unidades *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: conceptoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Concepto *',
                        hintText: 'Ej. Recepción taller, Conteo físico...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: obsCtrl,
                      decoration: const InputDecoration(labelText: 'Observaciones (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.negroElegante,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (seleccionada == null || cantCtrl.text.isEmpty || conceptoCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor completa los campos requeridos')),
                          );
                          return;
                        }

                        final cant = int.tryParse(cantCtrl.text) ?? 0;
                        if (cant <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        try {
                          await ApiClient.instance.dio.post('/inventarios', data: {
                            'variante_id': seleccionada!.varianteId,
                            'tipo_movimiento': tipo,
                            'concepto': conceptoCtrl.text.trim(),
                            'observaciones': obsCtrl.text.trim(),
                            'cantidad': cant,
                          });
                          _cargarDatosInventario();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Movimiento de inventario guardado con éxito')),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error al registrar movimiento: $e'), backgroundColor: FashionColors.peligro),
                          );
                        }
                      },
                      child: const Text('Guardar Movimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _exportarKardexCsv() {
    if (_movimientos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay movimientos de kárdex para exportar')),
      );
      return;
    }

    final buffer = StringBuffer('ID,Fecha,Tipo,Concepto,Prenda,Talla,Cantidad,Observaciones\n');
    for (final m in _movimientos) {
      final id = m['id_movimiento'] ?? m['id'] ?? '';
      final fecha = m['created_at'] ?? m['fecha'] ?? '';
      final tipo = m['tipo_movimiento'] ?? '';
      final concepto = (m['concepto'] ?? '').toString().replaceAll(',', ';');
      final prenda = (m['producto']?['nombre'] ?? m['prenda'] ?? '').toString().replaceAll(',', ';');
      final talla = m['variante']?['talla'] ?? m['talla'] ?? '';
      final cant = m['cantidad'] ?? 0;
      final obs = (m['observaciones'] ?? '').toString().replaceAll(',', ';');
      buffer.writeln('$id,$fecha,$tipo,$concepto,$prenda,$talla,$cant,$obs');
    }

    Share.share(buffer.toString(), subject: 'Kardex_Inventario_FashionStyle.csv');
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/inventario',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: FashionColors.negroElegante,
              unselectedLabelColor: FashionColors.textoMuted,
              indicatorColor: FashionColors.rosaCorporativo,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.shelves, size: 18), text: 'Existencias'),
                Tab(icon: Icon(Icons.history, size: 18), text: 'Kárdex'),
                Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'Alertas'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
                : _error != null
                    ? Center(child: Text(_error!))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _construirPestanaExistencias(),
                          _construirPestanaKardex(),
                          _construirPestanaAlertas(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // 1. EXISTENCIAS EN BODEGA
  Widget _construirPestanaExistencias() {
    List<_VarianteInventario> filtradas = List.from(_todasLasVariantes);

    if (_busquedaExistencias.trim().isNotEmpty) {
      final q = _busquedaExistencias.trim().toLowerCase();
      filtradas = filtradas.where((v) {
        return v.nombrePrenda.toLowerCase().contains(q) ||
            v.sku.toLowerCase().contains(q) ||
            v.talla.toLowerCase().contains(q) ||
            v.color.toLowerCase().contains(q);
      }).toList();
    }

    if (_filtroDisponibilidad == 'en_stock') {
      filtradas = filtradas.where((v) => v.stock > 5).toList();
    } else if (_filtroDisponibilidad == 'bajo_stock') {
      filtradas = filtradas.where((v) => v.stock >= 1 && v.stock <= 5).toList();
    } else if (_filtroDisponibilidad == 'agotados') {
      filtradas = filtradas.where((v) => v.stock <= 0).toList();
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar por prenda, SKU, talla o color...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _busquedaExistencias = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chipDisponibilidad('todos', 'Todos (${_todasLasVariantes.length})'),
                    _chipDisponibilidad('en_stock', 'En stock (>5)'),
                    _chipDisponibilidad('bajo_stock', 'Bajo stock (1-5)'),
                    _chipDisponibilidad('agotados', 'Agotados (0)'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtradas.isEmpty
              ? const Center(child: Text('No hay prendas que coincidan con los filtros'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final v = filtradas[index];
                    final colorStock = v.stock <= 0
                        ? FashionColors.peligro
                        : (v.stock <= 5 ? FashionColors.aviso : FashionColors.verdeExito);

                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: FashionColors.grisBorde),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 44,
                            height: 52,
                            child: v.imagenUrl.isNotEmpty
                                ? CachedNetworkImage(imageUrl: v.imagenUrl, fit: BoxFit.cover)
                                : Container(color: FashionColors.fondoClaro, child: const Icon(Icons.checkroom)),
                          ),
                        ),
                        title: Text(v.nombrePrenda, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Talla: ${v.talla} · SKU: ${v.sku} · Color: ${v.color}', style: const TextStyle(fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: colorStock.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '${v.stock} uds',
                                style: TextStyle(color: colorStock, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              tooltip: 'Ajustar stock',
                              onPressed: () => _abrirModalRegistrarMovimiento(v),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chipDisponibilidad(String val, String label) {
    final sel = _filtroDisponibilidad == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : FashionColors.textoOscuro)),
        selected: sel,
        selectedColor: FashionColors.negroElegante,
        onSelected: (_) => setState(() => _filtroDisponibilidad = val),
      ),
    );
  }

  // 2. KÁRDEX Y MOVIMIENTOS
  Widget _construirPestanaKardex() {
    List<Map<String, dynamic>> filtrados = List.from(_movimientos);

    if (_filtroTipoKardex.isNotEmpty) {
      filtrados = filtrados.where((m) => m['tipo_movimiento'] == _filtroTipoKardex).toList();
    }

    if (_busquedaKardex.trim().isNotEmpty) {
      final q = _busquedaKardex.trim().toLowerCase();
      filtrados = filtrados.where((m) {
        final conc = (m['concepto'] ?? '').toString().toLowerCase();
        final pren = (m['producto']?['nombre'] ?? m['prenda'] ?? '').toString().toLowerCase();
        return conc.contains(q) || pren.contains(q);
      }).toList();
    }

    return Column(
      children: [
        // TARJETAS DE RESUMEN
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  _tarjetaStat('Movimientos', '${_resumenKardex['total_movimientos']}', const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _tarjetaStat('Entradas (+)', '${_resumenKardex['entradas']}', FashionColors.verdeExito),
                  const SizedBox(width: 8),
                  _tarjetaStat('Salidas (-)', '${_resumenKardex['salidas']}', FashionColors.peligro),
                  const SizedBox(width: 8),
                  _tarjetaStat('Ajustes (=)', '${_resumenKardex['ajustes']}', const Color(0xFFD97706)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Filtrar por concepto o prenda...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _busquedaKardex = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Exportar CSV',
                    onPressed: _exportarKardexCsv,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: FashionColors.rosaCorporativo),
                    tooltip: 'Nuevo Movimiento',
                    onPressed: () => _abrirModalRegistrarMovimiento(),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(child: Text('No hay movimientos registrados en el kárdex'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final m = filtrados[index];
                    final tipo = m['tipo_movimiento']?.toString() ?? 'ajuste';
                    final esEntrada = tipo == 'entrada';
                    final colorTipo = esEntrada
                        ? FashionColors.verdeExito
                        : (tipo == 'salida' ? FashionColors.peligro : const Color(0xFFD97706));

                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: FashionColors.grisBorde),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorTipo.withValues(alpha: 0.12),
                          child: Icon(
                            esEntrada ? Icons.arrow_downward : (tipo == 'salida' ? Icons.arrow_upward : Icons.tune),
                            color: colorTipo,
                            size: 18,
                          ),
                        ),
                        title: Text(m['concepto']?.toString() ?? 'Movimiento', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          '${m['created_at'] ?? m['fecha'] ?? ''} · ${m['producto']?['nombre'] ?? m['prenda'] ?? 'Prenda'}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          '${esEntrada ? '+' : (tipo == 'salida' ? '-' : '')}${m['cantidad']} uds',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorTipo, fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _tarjetaStat(String label, String valor, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(color: col.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(valor, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: FashionColors.textoMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // 3. ALERTAS DE STOCK BAJO O AGOTADO
  Widget _construirPestanaAlertas() {
    final enAlerta = _todasLasVariantes.where((v) => v.stock <= 5).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    if (enAlerta.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, size: 48, color: FashionColors.verdeExito),
              SizedBox(height: 12),
              Text('¡Inventario en orden!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('No hay prendas con stock crítico o agotado actualmente.', style: TextStyle(color: FashionColors.textoMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: enAlerta.length,
      itemBuilder: (context, index) {
        final v = enAlerta[index];
        final agotado = v.stock <= 0;

        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: agotado ? FashionColors.peligro.withValues(alpha: 0.4) : FashionColors.aviso.withValues(alpha: 0.4)),
          ),
          child: ListTile(
            leading: Icon(
              agotado ? Icons.cancel_outlined : Icons.warning_amber_rounded,
              color: agotado ? FashionColors.peligro : FashionColors.aviso,
              size: 28,
            ),
            title: Text(v.nombrePrenda, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Talla: ${v.talla} · SKU: ${v.sku}', style: const TextStyle(fontSize: 11)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.negroElegante,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => _abrirModalRegistrarMovimiento(v),
              child: Text(agotado ? 'Agotado (Reabastecer)' : 'Quedan ${v.stock} (Reabastecer)', style: const TextStyle(fontSize: 11)),
            ),
          ),
        );
      },
    );
  }
}

class _VarianteInventario {
  final int varianteId;
  final int productoId;
  final String nombrePrenda;
  final String talla;
  final String sku;
  final double precioVenta;
  final int stock;
  final String imagenUrl;
  final String color;

  const _VarianteInventario({
    required this.varianteId,
    required this.productoId,
    required this.nombrePrenda,
    required this.talla,
    required this.sku,
    required this.precioVenta,
    required this.stock,
    required this.imagenUrl,
    required this.color,
  });
}
