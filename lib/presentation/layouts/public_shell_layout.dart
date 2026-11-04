// @source-mirror: src/layouts/DisenoPublico.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/fashion_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/storefront_widgets.dart';

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
        elevation: 0.5,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleSpacing: 16,
        title: GestureDetector(
          onTap: () => context.go('/'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: FashionColors.negroElegante,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.style, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'FashionStyle',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.5,
                  color: FashionColors.textoOscuro,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: FashionColors.textoOscuro),
            tooltip: 'Buscar en catálogo',
            onPressed: () => context.go('/catalogo'),
          ),
          if (authState.tieneAccesoAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, color: FashionColors.rosaCorporativo),
              tooltip: 'Panel Administrativo',
              onPressed: () => context.go('/admin'),
            ),
          IconButton(
            tooltip: 'Favoritos',
            icon: Badge(
              isLabelVisible: favsState.total > 0,
              backgroundColor: FashionColors.rosaCorporativo,
              label: Text('${favsState.total}', style: const TextStyle(fontSize: 10, color: Colors.white)),
              child: Icon(
                favsState.soloFavoritos ? Icons.favorite : Icons.favorite_border,
                color: favsState.soloFavoritos ? FashionColors.rosaCorporativo : FashionColors.textoOscuro,
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
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: FashionColors.rosaSuave,
                child: Text(
                  authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FashionColors.rosaOscuro),
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
                        Icon(Icons.dashboard_outlined, size: 20, color: FashionColors.rosaCorporativo),
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
              icon: const Icon(Icons.person_outline, color: FashionColors.textoOscuro),
              tooltip: 'Iniciar sesión',
              onPressed: () => context.go('/login'),
            ),
          IconButton(
            tooltip: 'Bolsa de compras',
            icon: Badge(
              isLabelVisible: cartState.totalPrendas > 0,
              backgroundColor: FashionColors.rosaCorporativo,
              label: Text(
                '${cartState.totalPrendas}',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: FashionColors.textoOscuro),
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width > 420 ? 400 : MediaQuery.of(context).size.width * 0.88,
        child: const SafeArea(
          child: CartDrawerWidget(),
        ),
      ),
      onEndDrawerChanged: (abierto) {
        if (!abierto && cartState.cajonAbierto) {
          ref.read(cartProvider.notifier).cerrarCajon();
        }
      },
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceNav,
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: FashionColors.rosaSuave,
        onDestinationSelected: (idx) {
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
              if (authState.estaAutenticado) {
                context.go('/perfil');
              } else {
                context.go('/login');
              }
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: FashionColors.rosaOscuro),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: FashionColors.rosaOscuro),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: favsState.total > 0,
              backgroundColor: FashionColors.rosaCorporativo,
              label: Text('${favsState.total}', style: const TextStyle(fontSize: 10, color: Colors.white)),
              child: const Icon(Icons.favorite_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: favsState.total > 0,
              backgroundColor: FashionColors.rosaCorporativo,
              label: Text('${favsState.total}', style: const TextStyle(fontSize: 10, color: Colors.white)),
              child: const Icon(Icons.favorite, color: FashionColors.rosaOscuro),
            ),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: FashionColors.rosaOscuro),
            label: authState.estaAutenticado ? 'Perfil' : 'Ingresar',
          ),
        ],
      ),
    );
  }
}
