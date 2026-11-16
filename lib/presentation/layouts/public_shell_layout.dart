// @source-mirror: src/layouts/DisenoPublico.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
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
  bool _modalCarritoAbierto = false;

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
    if (location.startsWith('/carrito')) {
      return 3;
    }
    if (location.startsWith('/perfil') ||
        location.startsWith('/login') ||
        location.startsWith('/registro') ||
        location.startsWith('/verificar-correo') ||
        location.startsWith('/recuperar-contrasena') ||
        location.startsWith('/restablecer-contrasena')) {
      return 4;
    }
    return 0;
  }

  void _navegarAIndice(int idx) {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
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
        context.go('/carrito');
        break;
      case 4:
        final auth = ref.read(authProvider);
        if (auth.estaAutenticado) {
          context.go('/perfil');
        } else {
          context.go('/login');
        }
        break;
    }
  }

  void _abrirCarritoComprasModal(BuildContext context) {
    if (_modalCarritoAbierto) return;
    _modalCarritoAbierto = true;
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();

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
      _modalCarritoAbierto = false;
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      if (ref.read(cartProvider).cajonAbierto) {
        ref.read(cartProvider.notifier).cerrarCajon();
      }
    });
  }

  Widget _buildNavItem({
    required int idx,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool active,
    int badgeCount = 0,
  }) {
    const activeBg = Color(0xFFF7F4EF);
    const activeFg = Color(0xFF111111);
    final inactiveFg = Colors.white.withValues(alpha: 0.70);

    return Expanded(
      child: Material(
        color: active ? activeBg : Colors.transparent,
        child: InkWell(
          onTap: () => _navegarAIndice(idx),
          child: Container(
            decoration: BoxDecoration(
              border: active
                  ? const Border(
                      top: BorderSide(color: Color(0xFF111111), width: 2),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: badgeCount > 0,
                  backgroundColor: FashionColors.brandAccent,
                  label: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    color: active ? activeFg : inactiveFg,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: active ? activeFg : inactiveFg,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
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
        _abrirCarritoComprasModal(context);
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
        title: GestureDetector(
          onTap: () => context.go('/'),
          behavior: HitTestBehavior.opaque,
          child: Text(
            'FASHIONSTYLE',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.4,
              color: FashionColors.inkPrimary,
              height: 1.1,
            ),
          ),
        ),
      ),
      // Soporte gestual táctil: deslizamiento horizontal rápido para alternar secciones principales
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final deltaX = details.velocity.pixelsPerSecond.dx;
          if (deltaX.abs() > 400) {
            if (deltaX < 0 && indiceNav < 4) {
              _navegarAIndice(indiceNav + 1);
            } else if (deltaX > 0 && indiceNav > 0) {
              _navegarAIndice(indiceNav - 1);
            }
          }
        },
        child: widget.child,
      ),
      // BARRA INFERIOR EDGE-TO-EDGE DE 5 PESTAÑAS (#111111)
      bottomNavigationBar: Container(
        color: const Color(0xFF111111),
        child: SafeArea(
          top: false,
          child: Container(
            height: 56,
            color: const Color(0xFF111111),
            child: Row(
              children: [
                _buildNavItem(
                  idx: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Inicio',
                  active: indiceNav == 0,
                ),
                _buildNavItem(
                  idx: 1,
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Catálogo',
                  active: indiceNav == 1,
                ),
                _buildNavItem(
                  idx: 2,
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: 'Favoritos',
                  badgeCount: favsState.total,
                  active: indiceNav == 2,
                ),
                _buildNavItem(
                  idx: 3,
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Carrito',
                  badgeCount: cartState.totalPrendas,
                  active: indiceNav == 3,
                ),
                _buildNavItem(
                  idx: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: authState.estaAutenticado ? 'Perfil' : 'Ingresar',
                  active: indiceNav == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
