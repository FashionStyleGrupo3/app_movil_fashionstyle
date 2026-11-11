// @source-mirror: src/layouts/DisenoAdmin.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';

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
    return 'Panel Administrativo';
  }

  int _determinarSlotActivo(String path) {
    if (path == '/admin') return 0;
    if (path.contains('/ventas')) return 1;
    if (path.contains('/pedidos') || path.contains('/produccion')) return 2;
    return 3; // Módulos
  }

  void _abrirBentoModulos(BuildContext context, WidgetRef ref, AuthState authState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: FashionColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: FashionColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const AtelierMonogram(size: 28),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Módulos Operativos',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.inkPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Gestión Omnicanal FashionStyle',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: FashionColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: FashionColors.inkSecondary),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
              const Divider(color: FashionColors.borderSubtle, height: 1),
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
                        if (currentPath != ruta) context.go(ruta);
                      },
                    ),

                    const SizedBox(height: 16),

                    // SECCIÓN 2: CATÁLOGO, BODEGA & PRODUCCIÓN
                    _buildBentoSection(
                      titulo: 'Catálogo, Bodega & Taller',
                      colorAcento: FashionColors.atelierJade,
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
                      ],
                      onSelect: (ruta) {
                        Navigator.pop(sheetCtx);
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: FashionColors.borderSubtle),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.storefront_outlined, size: 18, color: FashionColors.inkPrimary),
                            label: Text(
                              'Tienda Pública',
                              style: GoogleFonts.plusJakartaSans(
                                color: FashionColors.inkPrimary,
                                fontWeight: FontWeight.w600,
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: FashionColors.statusDanger),
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
    return Container(
      decoration: BoxDecoration(
        color: FashionColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FashionColors.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.inkSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            return InkWell(
              onTap: () => onSelect(item.ruta),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: item.activo ? FashionColors.surfaceCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: item.activo
                      ? Border.all(color: colorAcento.withValues(alpha: 0.4), width: 1.2)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icono,
                      size: 20,
                      color: item.activo ? colorAcento : FashionColors.inkSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titulo,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: item.activo ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 13,
                              color: item.activo ? FashionColors.inkPrimary : FashionColors.inkPrimary,
                            ),
                          ),
                          Text(
                            item.subtitulo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: FashionColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.activo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorAcento,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVO',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: FashionColors.inkSecondary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
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
            Icon(
              activo ? iconoActivo : icono,
              color: activo ? FashionColors.brandAccent : Colors.white70,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: activo ? Colors.white : Colors.white60,
                fontSize: 11,
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
      final antesTeniaAcceso = previous?.esPersonal ?? true;
      final ahoraSinAcceso = (!next.esPersonal || !next.estaAutenticado) && !next.cargando;
      if (antesTeniaAcceso && ahoraSinAcceso) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/');
          }
        });
      }
    });

    final titulo = _obtenerTitulo(currentPath);
    final slotActivo = _determinarSlotActivo(currentPath);

    return Scaffold(
      backgroundColor: FashionColors.canvasBackground,
      // NOCTURNAL COMMAND HEADER (#14161F)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: FashionColors.inkPrimary,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        leadingWidth: 46,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: GestureDetector(
              onTap: () => context.go('/admin'),
              child: const AtelierMonogram(
                size: 30,
                primaryColor: Colors.white,
                accentColor: FashionColors.brandAccent,
                surfaceColor: Colors.transparent,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                // Indicador Reverb/API en vivo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: FashionColors.atelierJade,
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
                      const SizedBox(width: 4),
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
                  'ROLES: ',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  authState.esAdmin ? 'ADMINISTRADOR' : 'STAFF OPERATIVO',
                  style: GoogleFonts.plusJakartaSans(
                    color: FashionColors.brandAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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
            onPressed: () => context.go('/'),
          ),
          IconButton(
            tooltip: 'Ver todos los módulos',
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
            onPressed: () => _abrirBentoModulos(context, ref, authState),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: child,
      // 4-SLOT OPERATIONAL BOTTOM BAR
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: FashionColors.inkPrimary,
            border: Border(
              top: BorderSide(color: Color(0xFF232736), width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildBottomSlot(
                icono: Icons.dashboard_outlined,
                iconoActivo: Icons.dashboard_rounded,
                label: 'Dashboard',
                activo: slotActivo == 0,
                onTap: () {
                  if (currentPath != '/admin') context.go('/admin');
                },
              ),
              _buildBottomSlot(
                icono: Icons.receipt_long_outlined,
                iconoActivo: Icons.receipt_long_rounded,
                label: 'Ventas POS',
                activo: slotActivo == 1,
                onTap: () {
                  if (currentPath != '/admin/ventas') context.go('/admin/ventas');
                },
              ),
              _buildBottomSlot(
                icono: Icons.local_shipping_outlined,
                iconoActivo: Icons.local_shipping_rounded,
                label: 'Pedidos',
                activo: slotActivo == 2,
                onTap: () {
                  if (currentPath != '/admin/pedidos') context.go('/admin/pedidos');
                },
              ),
              _buildBottomSlot(
                icono: Icons.grid_view_outlined,
                iconoActivo: Icons.grid_view_rounded,
                label: 'Módulos',
                activo: slotActivo == 3,
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
