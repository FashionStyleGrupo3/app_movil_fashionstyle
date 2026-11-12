// @source-mirror: src/layouts/DisenoPublico.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/fashion_brand_emblem.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/cart_drawer.dart';

class PublicShellLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int? currentIndex;

  const PublicShellLayout({
    super.key,
    required this.child,
    this.currentIndex,
  });

  @override
  ConsumerState<PublicShellLayout> createState() => _PublicShellLayoutState();
}

class _PublicShellLayoutState extends ConsumerState<PublicShellLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _modalBolsaAbierto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.estaAutenticado) {
        ref.read(favoritesProvider.notifier).cargarDesdeServidor(estaAutenticado: true);
      }
    });
  }

  int _determinarIndiceActual(String location) {
    if (widget.currentIndex != null) return widget.currentIndex!;
    if (location == '/') return 0;
    if (location.startsWith('/catalogo')) {
      final soloFavs = ref.read(favoritesProvider).soloFavoritos;
      return soloFavs ? 2 : 1;
    }
    if (location.startsWith('/perfil') || location.startsWith('/login') || location.startsWith('/registro')) {
      return 3;
    }
    return 0;
  }

  void _navegarAIndice(int idx) {
    switch (idx) {
      case 0:
        ref.read(favoritesProvider.notifier).setSoloFavoritos(false);
        context.go('/');
        break;
      case 1:
        ref.read(favoritesProvider.notifier).setSoloFavoritos(false);
        context.go('/catalogo');
        break;
      case 2:
        ref.read(favoritesProvider.notifier).setSoloFavoritos(true);
        context.go('/catalogo');
        break;
      case 3:
        final auth = ref.read(authProvider);
        if (auth.estaAutenticado) {
          context.go('/perfil');
        } else {
          context.go('/login');
        }
        break;
    }
  }

  void _abrirBolsaComprasModal(BuildContext context) {
    if (_modalBolsaAbierto) return;
    _modalBolsaAbierto = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
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
              const Expanded(
                child: CartDrawerWidget(),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _modalBolsaAbierto = false;
      if (ref.read(cartProvider).cajonAbierto) {
        ref.read(cartProvider.notifier).cerrarCajon();
      }
    });
  }

  Widget _buildDockItem({
    required int idx,
    required IconData icono,
    required IconData iconoActivo,
    required String label,
    required bool activo,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () => _navegarAIndice(idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: activo
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? FashionColors.brandAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              backgroundColor: FashionColors.brandAccent,
              label: Text(
                '$badgeCount',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child: Icon(
                activo ? iconoActivo : icono,
                color: activo ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
            if (activo) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cartState = ref.watch(cartProvider);
    final favsState = ref.watch(favoritesProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final indiceNav = _determinarIndiceActual(location);

    ref.listen<CartState>(cartProvider, (prev, next) {
      if (next.cajonAbierto && !(prev?.cajonAbierto ?? false)) {
        _abrirBolsaComprasModal(context);
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: FashionColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: FashionColors.canvasBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: FashionColors.inkPrimary.withValues(alpha: 0.05),
        centerTitle: false,
        titleSpacing: 16,
        title: FashionBrandHeader(
          emblemSize: 32,
          compacto: false,
          onTap: () => context.go('/'),
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            icon: const Icon(Icons.search_rounded, size: 22, color: FashionColors.inkPrimary),
            tooltip: 'Buscar en catálogo',
            onPressed: () => context.go('/catalogo'),
          ),
          if (authState.tieneAccesoAdmin)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 22, color: FashionColors.atelierJade),
              tooltip: 'Panel Administrativo',
              onPressed: () => context.go('/admin'),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            tooltip: 'Favoritos',
            icon: Badge(
              isLabelVisible: favsState.total > 0,
              backgroundColor: FashionColors.brandAccent,
              label: Text('${favsState.total}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              child: Icon(
                favsState.soloFavoritos ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 22,
                color: favsState.soloFavoritos ? FashionColors.statusDanger : FashionColors.inkPrimary,
              ),
            ),
            onPressed: () {
              final nuevo = !favsState.soloFavoritos;
              ref.read(favoritesProvider.notifier).setSoloFavoritos(nuevo);
              context.go('/catalogo');
            },
          ),
          if (authState.estaAutenticado)
            PopupMenuButton<String>(
              tooltip: 'Mi cuenta',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: FashionColors.surfaceMuted,
                child: Text(
                  authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FashionColors.inkPrimary),
                ),
              ),
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (valor) {
                switch (valor) {
                  case 'perfil':
                    context.go('/perfil');
                    break;
                  case 'admin':
                    context.go('/admin');
                    break;
                  case 'logout':
                    ref.read(authProvider.notifier).cerrarSesion();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesión cerrada exitosamente')),
                    );
                    context.go('/');
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.nombreUsuario,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: FashionColors.inkPrimary),
                      ),
                      Text(
                        authState.correoUsuario,
                        style: const TextStyle(fontSize: 12, color: FashionColors.inkSecondary),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'perfil',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: FashionColors.inkPrimary),
                      SizedBox(width: 10),
                      Text('Mi perfil'),
                    ],
                  ),
                ),
                if (authState.tieneAccesoAdmin)
                  const PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.dashboard_outlined, size: 20, color: FashionColors.atelierJade),
                        SizedBox(width: 10),
                        Text('Panel de control'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: FashionColors.statusDanger),
                      SizedBox(width: 10),
                      Text('Cerrar sesión', style: TextStyle(color: FashionColors.statusDanger)),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              icon: const Icon(Icons.person_outline_rounded, size: 22, color: FashionColors.inkPrimary),
              tooltip: 'Iniciar sesión',
              onPressed: () => context.go('/login'),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            tooltip: 'Bolsa de compras',
            icon: Badge(
              isLabelVisible: cartState.totalPrendas > 0,
              backgroundColor: FashionColors.brandAccent,
              label: Text(
                '${cartState.totalPrendas}',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 22, color: FashionColors.inkPrimary),
            ),
            onPressed: () => _abrirBolsaComprasModal(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Soporte gestual táctil: deslizamiento horizontal rápido para alternar secciones principales
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final deltaX = details.velocity.pixelsPerSecond.dx;
          if (deltaX.abs() > 400) {
            if (deltaX < 0 && indiceNav < 3) {
              _navegarAIndice(indiceNav + 1);
            } else if (deltaX > 0 && indiceNav > 0) {
              _navegarAIndice(indiceNav - 1);
            }
          }
        },
        child: widget.child,
      ),
      // FLOATING PILL DOCK INFERIOR SARTORIAL
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: FashionColors.inkPrimary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: FashionColors.inkPrimary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDockItem(
                  idx: 0,
                  icono: Icons.home_outlined,
                  iconoActivo: Icons.home_rounded,
                  label: 'Inicio',
                  activo: indiceNav == 0,
                ),
                _buildDockItem(
                  idx: 1,
                  icono: Icons.grid_view_outlined,
                  iconoActivo: Icons.grid_view_rounded,
                  label: 'Catálogo',
                  activo: indiceNav == 1,
                ),
                _buildDockItem(
                  idx: 2,
                  icono: Icons.favorite_border_rounded,
                  iconoActivo: Icons.favorite_rounded,
                  label: 'Favoritos',
                  badgeCount: favsState.total,
                  activo: indiceNav == 2,
                ),
                _buildDockItem(
                  idx: 3,
                  icono: Icons.person_outline_rounded,
                  iconoActivo: Icons.person_rounded,
                  label: authState.estaAutenticado ? 'Perfil' : 'Ingresar',
                  activo: indiceNav == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
