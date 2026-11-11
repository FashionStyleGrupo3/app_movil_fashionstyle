// @source-mirror: src/layouts/DisenoPublico.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cartState = ref.watch(cartProvider);
    final favsState = ref.watch(favoritesProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final indiceNav = _determinarIndiceActual(location);

    ref.listen<CartState>(cartProvider, (prev, next) {
      if (next.cajonAbierto && !(prev?.cajonAbierto ?? false)) {
        _scaffoldKey.currentState?.openEndDrawer();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: FashionColors.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
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
            icon: const Icon(Icons.search_rounded, size: 22, color: FashionColors.negro),
            tooltip: 'Buscar en catálogo',
            onPressed: () => context.go('/catalogo'),
          ),
          if (authState.tieneAccesoAdmin)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 22, color: FashionColors.pizarra),
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
              backgroundColor: FashionColors.negro,
              label: Text('${favsState.total}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              child: Icon(
                favsState.soloFavoritos ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 22,
                color: favsState.soloFavoritos ? FashionColors.rojo : FashionColors.negro,
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
                backgroundColor: FashionColors.arenaSuave,
                child: Text(
                  authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FashionColors.negro),
                ),
              ),
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, color: FashionColors.textoOscuro),
                      ),
                      Text(
                        authState.correoUsuario,
                        style: const TextStyle(fontSize: 12, color: FashionColors.textoMuted),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'perfil',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: FashionColors.textoOscuro),
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
                        Icon(Icons.dashboard_outlined, size: 20, color: FashionColors.pizarra),
                        SizedBox(width: 10),
                        Text('Panel de control'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: FashionColors.peligro),
                      SizedBox(width: 10),
                      Text('Cerrar sesión', style: TextStyle(color: FashionColors.peligro)),
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
              icon: const Icon(Icons.person_outline_rounded, size: 22, color: FashionColors.negro),
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
              backgroundColor: FashionColors.negro,
              label: Text(
                '${cartState.totalPrendas}',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 22, color: FashionColors.negro),
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width > 420 ? 400 : MediaQuery.of(context).size.width * 0.88,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: const SafeArea(
          child: CartDrawerWidget(),
        ),
      ),
      onEndDrawerChanged: (abierto) {
        if (!abierto && cartState.cajonAbierto) {
          ref.read(cartProvider.notifier).cerrarCajon();
        }
      },
      // Soporte gestual táctil: deslizamiento horizontal rápido para alternar secciones principales
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final deltaX = details.velocity.pixelsPerSecond.dx;
          // Si el gesto fue predominantemente horizontal con suficiente velocidad
          if (deltaX.abs() > 400) {
            if (deltaX < 0 && indiceNav < 3) {
              // Deslizar izquierda -> ir a la siguiente pestaña
              _navegarAIndice(indiceNav + 1);
            } else if (deltaX > 0 && indiceNav > 0) {
              // Deslizar derecha -> ir a la pestaña anterior
              _navegarAIndice(indiceNav - 1);
            }
          }
        },
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: FashionColors.borde, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: indiceNav,
          elevation: 0,
          height: 64,
          backgroundColor: Colors.white,
          indicatorColor: FashionColors.arenaSuave,
          onDestinationSelected: _navegarAIndice,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: FashionColors.negro),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_sharp, color: FashionColors.negro),
              label: 'Catálogo',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: favsState.total > 0,
                backgroundColor: FashionColors.negro,
                label: Text('${favsState.total}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                child: const Icon(Icons.favorite_outline_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: favsState.total > 0,
                backgroundColor: FashionColors.negro,
                label: Text('${favsState.total}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                child: const Icon(Icons.favorite_rounded, color: FashionColors.rojo),
              ),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded, color: FashionColors.negro),
              label: authState.estaAutenticado ? 'Perfil' : 'Ingresar',
            ),
          ],
        ),
      ),
    );
  }
}
