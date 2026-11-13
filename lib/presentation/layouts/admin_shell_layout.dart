// @source-mirror: src/layouts/DisenoAdmin.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';

class AdminShellLayout extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AdminShellLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  String _obtenerTitulo(String path) {
    if (path == '/admin') return 'Panel de Control';
    if (path.contains('/inventario')) return 'Inventario / Kárdex';
    if (path.contains('/pedidos')) return 'Pedidos y Facturas';
    if (path.contains('/ventas')) return 'Ventas POS Mostrador';
    if (path.contains('/pagos')) return 'Pagos y Dispersión';
    if (path.contains('/produccion')) return 'Producción / Costos';
    if (path.contains('/prendas')) return 'Gestión de Prendas';
    if (path.contains('/seguridad/auditoria')) return 'Bitácora de Auditoría';
    if (path.contains('/seguridad')) return 'Clientes y Usuarios';
    if (path.contains('/cuenta')) return 'Configuración de Cuenta';
    if (path.contains('/ayuda')) return 'Centro de Ayuda';
    if (path.contains('/mensajes')) return 'Mensajes y PQRS';
    return 'Panel Administrativo';
  }

  int _determinarSeccionActiva(String path) {
    if (path.contains('/ventas') || path.contains('/pedidos') || path.contains('/pagos')) {
      return 0; // Comercial
    }
    if (path.contains('/prendas') || path.contains('/inventario') || path.contains('/produccion')) {
      return 1; // Taller
    }
    if (path == '/admin' || path.contains('/seguridad') || path.contains('/cuenta') || path.contains('/ayuda') || path.contains('/mensajes')) {
      return 2; // Sistema
    }
    return 3; // Todos / otros
  }

  void _abrirModalSeccion(
    BuildContext context,
    WidgetRef ref,
    AuthState authState, {
    required String titulo,
    required String subtitulo,
    required Color colorAcento,
    required List<_BentoItem> items,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F4EF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFFD8CFC2), width: 1),
              left: BorderSide(color: Color(0xFFD8CFC2), width: 1),
              right: BorderSide(color: Color(0xFFD8CFC2), width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8CFC2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111111),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A4A4A),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF111111)),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFD8CFC2), height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildBentoSection(
                  titulo: titulo,
                  colorAcento: colorAcento,
                  items: items,
                  onSelect: (ruta) {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
                    if (currentPath != ruta) context.go(ruta);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirSeccionComercial(BuildContext context, WidgetRef ref, AuthState authState) {
    _abrirModalSeccion(
      context,
      ref,
      authState,
      titulo: 'Módulos Comerciales',
      subtitulo: 'Ventas, facturación y dispersión',
      colorAcento: FashionColors.brandAccent,
      items: [
        _BentoItem(
          titulo: 'Ventas POS',
          subtitulo: 'Caja mostrador & PDF 80mm',
          ruta: '/admin/ventas',
          icono: Icons.receipt_long_outlined,
          activo: currentPath.contains('/ventas'),
        ),
        _BentoItem(
          titulo: 'Pedidos y Facturas',
          subtitulo: 'Despachos web y seguimiento',
          ruta: '/admin/pedidos',
          icono: Icons.local_shipping_outlined,
          activo: currentPath.contains('/pedidos'),
        ),
        _BentoItem(
          titulo: 'Pagos & Dispersión',
          subtitulo: 'Credenciales Wompi y bancos',
          ruta: '/admin/pagos',
          icono: Icons.account_balance_outlined,
          activo: currentPath.contains('/pagos'),
        ),
      ],
    );
  }

  void _abrirSeccionTaller(BuildContext context, WidgetRef ref, AuthState authState) {
    _abrirModalSeccion(
      context,
      ref,
      authState,
      titulo: 'Taller & Operaciones',
      subtitulo: 'Prendas, inventario y producción',
      colorAcento: FashionColors.slateAccent,
      items: [
        _BentoItem(
          titulo: 'Gestión de Prendas',
          subtitulo: 'Catálogo, variantes y fotos',
          ruta: '/admin/prendas',
          icono: Icons.checkroom_outlined,
          activo: currentPath.contains('/prendas'),
        ),
        _BentoItem(
          titulo: 'Inventario / Kárdex',
          subtitulo: 'Stock, alertas y bodega',
          ruta: '/admin/inventario',
          icono: Icons.inventory_2_outlined,
          activo: currentPath.contains('/inventario'),
        ),
        _BentoItem(
          titulo: 'Producción / Costos BOM',
          subtitulo: 'Fórmulas y órdenes activas',
          ruta: '/admin/produccion',
          icono: Icons.content_cut_outlined,
          activo: currentPath.contains('/produccion'),
        ),
      ],
    );
  }

  void _abrirSeccionSistema(BuildContext context, WidgetRef ref, AuthState authState) {
    _abrirModalSeccion(
      context,
      ref,
      authState,
      titulo: 'Control & Sistema',
      subtitulo: 'Dashboard, auditoría, staff y cuenta',
      colorAcento: FashionColors.editorialOchre,
      items: [
        _BentoItem(
          titulo: 'Panel de Control',
          subtitulo: 'KPIs en vivo y analítica',
          ruta: '/admin',
          icono: Icons.dashboard_outlined,
          activo: currentPath == '/admin',
        ),
        _BentoItem(
          titulo: 'Clientes & Usuarios',
          subtitulo: 'Roles en vivo y accesos',
          ruta: '/admin/seguridad',
          icono: Icons.people_outline,
          activo: currentPath == '/admin/seguridad',
        ),
        if (authState.esAdmin)
          _BentoItem(
            titulo: 'Bitácora de Auditoría',
            subtitulo: 'Trazabilidad de cambios',
            ruta: '/admin/seguridad/auditoria',
            icono: Icons.history_edu_outlined,
            activo: currentPath.contains('/auditoria'),
          ),
        _BentoItem(
          titulo: 'Mi Cuenta',
          subtitulo: 'Perfil del operador',
          ruta: '/admin/cuenta',
          icono: Icons.account_circle_outlined,
          activo: currentPath.contains('/cuenta'),
        ),
        _BentoItem(
          titulo: 'Mensajes PQRS',
          subtitulo: 'Bandeja de contacto y PQRS',
          ruta: '/admin/mensajes',
          icono: Icons.mail_outline,
          activo: currentPath.contains('/mensajes'),
        ),
        _BentoItem(
          titulo: 'Centro de Ayuda',
          subtitulo: 'Manuales de uso y guías',
          ruta: '/admin/ayuda',
          icono: Icons.help_outline,
          activo: currentPath.contains('/ayuda'),
        ),
      ],
    );
  }

  void _abrirBentoModulos(BuildContext context, WidgetRef ref, AuthState authState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F4EF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFFD8CFC2), width: 1),
              left: BorderSide(color: Color(0xFFD8CFC2), width: 1),
              right: BorderSide(color: Color(0xFFD8CFC2), width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8CFC2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Módulos Operativos',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111111),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Gestión Omnicanal FashionStyle',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A4A4A),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF111111)),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFD8CFC2), height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // SECCIÓN 1: COMERCIAL & POS
                    _buildBentoSection(
                      titulo: 'Comercial & Punto de Venta',
                      colorAcento: FashionColors.brandAccent,
                      items: [
                        _BentoItem(
                          titulo: 'Panel de Control',
                          subtitulo: 'KPIs en vivo y analítica',
                          ruta: '/admin',
                          icono: Icons.dashboard_outlined,
                          activo: currentPath == '/admin',
                        ),
                        _BentoItem(
                          titulo: 'Ventas POS',
                          subtitulo: 'Caja mostrador & PDF 80mm',
                          ruta: '/admin/ventas',
                          icono: Icons.receipt_long_outlined,
                          activo: currentPath.contains('/ventas'),
                        ),
                        _BentoItem(
                          titulo: 'Pedidos y Facturas',
                          subtitulo: 'Despachos web y seguimiento',
                          ruta: '/admin/pedidos',
                          icono: Icons.local_shipping_outlined,
                          activo: currentPath.contains('/pedidos'),
                        ),
                      ],
                      onSelect: (ruta) {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
                        if (currentPath != ruta) context.go(ruta);
                      },
                    ),

                    const SizedBox(height: 16),

                    // SECCIÓN 2: CATÁLOGO, BODEGA & PRODUCCIÓN
                    _buildBentoSection(
                      titulo: 'Catálogo, Bodega & Taller',
                      colorAcento: FashionColors.slateAccent,
                      items: [
                        _BentoItem(
                          titulo: 'Gestión de Prendas',
                          subtitulo: 'Catálogo, variantes y fotos',
                          ruta: '/admin/prendas',
                          icono: Icons.checkroom_outlined,
                          activo: currentPath.contains('/prendas'),
                        ),
                        _BentoItem(
                          titulo: 'Inventario / Kárdex',
                          subtitulo: 'Stock, alertas y bodega',
                          ruta: '/admin/inventario',
                          icono: Icons.inventory_2_outlined,
                          activo: currentPath.contains('/inventario'),
                        ),
                        _BentoItem(
                          titulo: 'Producción / Costos BOM',
                          subtitulo: 'Fórmulas y órdenes activas',
                          ruta: '/admin/produccion',
                          icono: Icons.content_cut_outlined,
                          activo: currentPath.contains('/produccion'),
                        ),
                      ],
                      onSelect: (ruta) {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
                        if (currentPath != ruta) context.go(ruta);
                      },
                    ),

                    const SizedBox(height: 16),

                    // SECCIÓN 3: PAGOS, SEGURIDAD & CUENTA
                    _buildBentoSection(
                      titulo: 'Configuración, Seguridad & Staff',
                      colorAcento: FashionColors.editorialOchre,
                      items: [
                        _BentoItem(
                          titulo: 'Pagos & Dispersión',
                          subtitulo: 'Credenciales Wompi y bancos',
                          ruta: '/admin/pagos',
                          icono: Icons.account_balance_outlined,
                          activo: currentPath.contains('/pagos'),
                        ),
                        _BentoItem(
                          titulo: 'Clientes & Usuarios',
                          subtitulo: 'Roles en vivo y accesos',
                          ruta: '/admin/seguridad',
                          icono: Icons.people_outline,
                          activo: currentPath == '/admin/seguridad',
                        ),
                        if (authState.esAdmin)
                          _BentoItem(
                            titulo: 'Bitácora de Auditoría',
                            subtitulo: 'Trazabilidad de cambios',
                            ruta: '/admin/seguridad/auditoria',
                            icono: Icons.history_edu_outlined,
                            activo: currentPath.contains('/auditoria'),
                          ),
                        _BentoItem(
                          titulo: 'Mi Cuenta',
                          subtitulo: 'Perfil del operador',
                          ruta: '/admin/cuenta',
                          icono: Icons.account_circle_outlined,
                          activo: currentPath.contains('/cuenta'),
                        ),
                        _BentoItem(
                          titulo: 'Mensajes PQRS',
                          subtitulo: 'Bandeja de contacto y PQRS',
                          ruta: '/admin/mensajes',
                          icono: Icons.mail_outline,
                          activo: currentPath.contains('/mensajes'),
                        ),
                        _BentoItem(
                          titulo: 'Centro de Ayuda',
                          subtitulo: 'Manuales de uso y guías',
                          ruta: '/admin/ayuda',
                          icono: Icons.help_outline,
                          activo: currentPath.contains('/ayuda'),
                        ),
                      ],
                      onSelect: (ruta) {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
                        if (currentPath != ruta) context.go(ruta);
                      },
                    ),

                    const SizedBox(height: 20),

                    // ACCIONES INFERIORES: TIENDA PÚBLICA & CERRAR SESIÓN
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFD8CFC2), width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF111111)),
                            label: Text(
                              'Tienda Pública',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF111111),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              context.go('/');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: FashionColors.statusDanger, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18, color: FashionColors.statusDanger),
                            label: Text(
                              'Cerrar Sesión',
                              style: GoogleFonts.plusJakartaSans(
                                color: FashionColors.statusDanger,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              ref.read(authProvider.notifier).cerrarSesion();
                              context.go('/login');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBentoSection({
    required String titulo,
    required Color colorAcento,
    required List<_BentoItem> items,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: colorAcento,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              titulo.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(color: Color(0xFFD8CFC2), height: 1, thickness: 1),
        const SizedBox(height: 10),
        ...items.map((item) {
          final isActivo = item.activo;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(item.ruta),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActivo ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActivo ? const Color(0xFF111111) : const Color(0xFFD8CFC2),
                      width: isActivo ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isActivo ? const Color(0xFF111111) : const Color(0xFFF3EEE6),
                          borderRadius: BorderRadius.circular(10),
                          border: isActivo
                              ? null
                              : Border.all(color: const Color(0xFFD8CFC2), width: 1),
                        ),
                        child: Icon(
                          item.icono,
                          size: 20,
                          color: isActivo ? Colors.white : const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.titulo,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: isActivo ? FontWeight.w800 : FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF111111),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              item.subtitulo,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF4A4A4A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActivo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ACTIVO',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Color(0xFF56657A),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomSlot({
    required IconData icono,
    required IconData iconoActivo,
    required String label,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: activo ? FashionColors.crema : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                activo ? iconoActivo : icono,
                color: activo ? FashionColors.negro : Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: activo ? FashionColors.crema : Colors.white60,
                fontSize: 10,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final antesTeniaSesion = previous?.estaAutenticado ?? true;
      final ahoraSinSesion = !next.estaAutenticado && !next.cargando;
      if (antesTeniaSesion && ahoraSinSesion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/');
          }
        });
      }
    });

    final titulo = _obtenerTitulo(currentPath);
    final seccionActiva = _determinarSeccionActiva(currentPath);

    return Scaffold(
      backgroundColor: FashionColors.canvasBackground,
      // NOCTURNAL COMMAND HEADER (#14161F)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: FashionColors.inkPrimary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Indicador Reverb/API en vivo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: FashionColors.slateAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'EN VIVO',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'ROL: ',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  authState.esAdmin ? 'ADMINISTRADOR' : 'STAFF OPERATIVO',
                  style: GoogleFonts.plusJakartaSans(
                    color: FashionColors.sandDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ir a la Tienda Pública',
            icon: const Icon(Icons.storefront_outlined, color: Colors.white, size: 22),
            onPressed: () {
              ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
              context.go('/');
            },
          ),
          IconButton(
            tooltip: 'Ver todos los módulos',
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
            onPressed: () {
              ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
              _abrirBentoModulos(context, ref, authState);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: child,
      // 4-SLOT OPERATIONAL BOTTOM BAR
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: const BoxDecoration(
            color: FashionColors.inkPrimary,
            border: Border(
              top: BorderSide(color: Color(0xFF232736), width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildBottomSlot(
                icono: Icons.point_of_sale_outlined,
                iconoActivo: Icons.point_of_sale_rounded,
                label: 'Comercial',
                activo: seccionActiva == 0,
                onTap: () => _abrirSeccionComercial(context, ref, authState),
              ),
              _buildBottomSlot(
                icono: Icons.precision_manufacturing_outlined,
                iconoActivo: Icons.precision_manufacturing_rounded,
                label: 'Taller',
                activo: seccionActiva == 1,
                onTap: () => _abrirSeccionTaller(context, ref, authState),
              ),
              _buildBottomSlot(
                icono: Icons.tune_outlined,
                iconoActivo: Icons.tune_rounded,
                label: 'Sistema',
                activo: seccionActiva == 2,
                onTap: () => _abrirSeccionSistema(context, ref, authState),
              ),
              _buildBottomSlot(
                icono: Icons.grid_view_outlined,
                iconoActivo: Icons.grid_view_rounded,
                label: 'Todos',
                activo: false,
                onTap: () => _abrirBentoModulos(context, ref, authState),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoItem {
  final String titulo;
  final String subtitulo;
  final String ruta;
  final IconData icono;
  final bool activo;

  const _BentoItem({
    required this.titulo,
    required this.subtitulo,
    required this.ruta,
    required this.icono,
    required this.activo,
  });
}
