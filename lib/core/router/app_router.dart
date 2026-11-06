// @source-mirror: src/router/index.js
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/fashion_theme.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/publico/home_screen.dart';
import '../../presentation/screens/publico/catalog_screen.dart';
import '../../presentation/screens/publico/product_detail_screen.dart';
import '../../presentation/screens/publico/cart_and_terms_screens.dart';
import '../../presentation/screens/publico/profile_screen.dart';
import '../../presentation/screens/autenticacion/auth_screens.dart';
import '../../presentation/screens/admin/dashboard_and_inventory_screens.dart';
import '../../presentation/screens/admin/garments_and_pos_screens.dart';
import '../../presentation/screens/admin/orders_and_production_screens.dart';
import '../../presentation/screens/admin/payments_security_and_account_screens.dart';

class FashionPlaceholderScreen extends StatelessWidget {
  final String title;
  final String path;

  const FashionPlaceholderScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 48,
                color: FashionColors.pizarra,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ruta: $path\nPantalla lista para conectarse en los siguientes pasos.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FashionRouteScreens {
  static Widget Function(BuildContext, GoRouterState) screenBuilder(String title, String path) {
    return (context, state) => FashionPlaceholderScreen(title: title, path: path);
  }

  // Rutas públicas
  static WidgetBuilder home = (context) => const HomeScreen();
  static Widget Function(BuildContext, GoRouterState) productDetail =
      (context, state) => ProductDetailScreen(
            productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          );
  static WidgetBuilder cart = (context) => const CartCheckoutScreen();
  static Widget Function(BuildContext, GoRouterState) catalogWithState =
      (context, state) {
    final catId = int.tryParse(state.uri.queryParameters['categoria'] ?? '');
    final colId = int.tryParse(state.uri.queryParameters['catalogo'] ?? '');
    final search = state.uri.queryParameters['buscar'];
    final soloFavs = state.uri.queryParameters['favoritos'] == 'true';
    return CatalogScreen(
      categoriaId: catId,
      catalogoId: colId,
      searchQuery: search,
      soloFavoritos: soloFavs ? true : null,
    );
  };
  static WidgetBuilder catalog = (context) => const CatalogScreen();
  static WidgetBuilder terms = (context) => const TermsScreen();
  static Widget Function(BuildContext, GoRouterState) profile =
      (context, state) => ProfileScreen(
            initialSection: state.uri.queryParameters['seccion'] ?? state.uri.queryParameters['tab'],
          );

  // Rutas autenticación
  static Widget Function(BuildContext, GoRouterState) login =
      (context, state) => LoginScreen(
            redir: state.uri.queryParameters['redir'],
          );
  static WidgetBuilder register = (context) => const RegisterScreen();
  static Widget Function(BuildContext, GoRouterState) verifyEmail =
      (context, state) => VerifyEmailScreen(
            correo: state.uri.queryParameters['correo'] ?? state.uri.queryParameters['email'],
          );
  static WidgetBuilder forgotPassword = (context) => const ForgotPasswordScreen();
  static Widget Function(BuildContext, GoRouterState) resetPassword =
      (context, state) => ResetPasswordScreen(
            correo: state.uri.queryParameters['correo'] ?? state.uri.queryParameters['email'],
            token: state.uri.queryParameters['token'] ?? state.uri.queryParameters['codigo'],
          );

  // Rutas administrativas
  static WidgetBuilder adminDashboard = (context) => const AdminDashboardScreen();
  static WidgetBuilder adminInventory = (context) => const AdminInventoryScreen();
  static WidgetBuilder adminSales = (context) => const AdminPosSalesScreen();
  static WidgetBuilder adminOrders = (context) => const AdminOrdersAndInvoicesScreen();
  static WidgetBuilder adminProduction = (context) => const AdminProductionScreen();
  static WidgetBuilder adminGarments = (context) => const AdminGarmentsScreen();
  static WidgetBuilder adminAccount = (context) => const AdminAccountScreen();
  static WidgetBuilder adminPayments = (context) => const AdminPaymentsConfigScreen();
  static WidgetBuilder adminSecurity = (context) => const AdminSecurityAndUsersScreen();
  static WidgetBuilder adminAudit = (context) => const AdminAuditScreen();
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        final antesAuth = previous?.estaAutenticado;
        final ahoraAuth = next.estaAutenticado;
        final antesPersonal = previous?.esPersonal;
        final ahoraPersonal = next.esPersonal;

        // Solo notificar al router si realmente cambió el acceso o autenticación
        if (antesAuth != ahoraAuth || antesPersonal != ahoraPersonal) {
          notifyListeners();
        }
      },
    );
  }
}

final authRouterListenableProvider = Provider<AuthRouterListenable>((ref) {
  return AuthRouterListenable(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(authRouterListenableProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: listenable,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final auth = ref.read(authProvider);

      // 1. Redirecciones de conveniencia
      if (loc == '/acceso' || loc == '/iniciar-sesion' || loc == '/admin/login') {
        return '/login';
      }
      if (loc == '/clasificacion') {
        return '/catalogo';
      }
      if (loc == '/administrador-prendas') {
        return '/admin/prendas';
      }
      if (loc == '/cuenta') {
        return '/admin/cuenta';
      }

      // 2. Pantallas de autenticación
      const pantallasAuth = [
        '/login',
        '/registro',
        '/verificar-correo',
        '/recuperar-contrasena',
        '/restablecer-contrasena',
      ];
      final esPantallaAuth = pantallasAuth.contains(loc);

      if (esPantallaAuth && auth.estaAutenticado) {
        return auth.rutaInicial;
      }

      // 3. Verificación de rutas protegidas
      final requiereAuth = loc == '/perfil' || loc.startsWith('/admin');

      if (requiereAuth && !auth.estaAutenticado) {
        final redir = Uri.encodeComponent(loc);
        return '/login?redir=$redir';
      }

      // 4. Verificación de roles administrativos
      if (loc.startsWith('/admin')) {
        const rolesAdminYStaff = ['admin', 'administrador', 'super-admin', 'empleado', 'staff'];
        const rolesSoloAdmin = ['admin', 'administrador', 'super-admin'];

        final esRutaAuditoria = loc == '/admin/seguridad/auditoria';
        final rolesRequeridos = esRutaAuditoria ? rolesSoloAdmin : rolesAdminYStaff;

        final tieneAcceso = auth.rolesNormalizados.any((r) => rolesRequeridos.contains(r));
        if (!tieneAcceso) {
          if (auth.cargando) return null;
          return auth.estaAutenticado ? '/' : '/login';
        }
      }

      return null;
    },
    routes: [
      // Públicas
      GoRoute(
        path: '/',
        name: 'inicio',
        builder: (context, state) => FashionRouteScreens.home(context),
      ),
      GoRoute(
        path: '/producto/:id',
        name: 'detalle-producto',
        builder: (context, state) => FashionRouteScreens.productDetail(context, state),
      ),
      GoRoute(
        path: '/carrito',
        name: 'carrito',
        builder: (context, state) => FashionRouteScreens.cart(context),
      ),
      GoRoute(
        path: '/catalogo',
        name: 'catalogo',
        builder: (context, state) => FashionRouteScreens.catalogWithState(context, state),
      ),
      GoRoute(
        path: '/terminos',
        name: 'terminos',
        builder: (context, state) => FashionRouteScreens.terms(context),
      ),
      GoRoute(
        path: '/perfil',
        name: 'perfil',
        builder: (context, state) => FashionRouteScreens.profile(context, state),
      ),

      // Autenticación
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => FashionRouteScreens.login(context, state),
      ),
      GoRoute(
        path: '/registro',
        name: 'registro',
        builder: (context, state) => FashionRouteScreens.register(context),
      ),
      GoRoute(
        path: '/verificar-correo',
        name: 'verificar-correo',
        builder: (context, state) => FashionRouteScreens.verifyEmail(context, state),
      ),
      GoRoute(
        path: '/recuperar-contrasena',
        name: 'recuperar-contrasena',
        builder: (context, state) => FashionRouteScreens.forgotPassword(context),
      ),
      GoRoute(
        path: '/restablecer-contrasena',
        name: 'restablecer-contrasena',
        builder: (context, state) => FashionRouteScreens.resetPassword(context, state),
      ),

      // Administrativas
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        builder: (context, state) => FashionRouteScreens.adminDashboard(context),
        routes: [
          GoRoute(
            path: 'inventario',
            name: 'admin-inventario',
            builder: (context, state) => FashionRouteScreens.adminInventory(context),
          ),
          GoRoute(
            path: 'ventas',
            name: 'admin-ventas',
            builder: (context, state) => FashionRouteScreens.adminSales(context),
          ),
          GoRoute(
            path: 'pedidos',
            name: 'admin-pedidos',
            builder: (context, state) => FashionRouteScreens.adminOrders(context),
          ),
          GoRoute(
            path: 'produccion',
            name: 'admin-produccion',
            builder: (context, state) => FashionRouteScreens.adminProduction(context),
          ),
          GoRoute(
            path: 'prendas',
            name: 'gestion-prendas',
            builder: (context, state) => FashionRouteScreens.adminGarments(context),
          ),
          GoRoute(
            path: 'cuenta',
            name: 'admin-cuenta',
            builder: (context, state) => FashionRouteScreens.adminAccount(context),
          ),
          GoRoute(
            path: 'pagos',
            name: 'admin-pagos',
            builder: (context, state) => FashionRouteScreens.adminPayments(context),
          ),
          GoRoute(
            path: 'seguridad',
            name: 'admin-seguridad',
            builder: (context, state) => FashionRouteScreens.adminSecurity(context),
            routes: [
              GoRoute(
                path: 'auditoria',
                name: 'admin-auditoria',
                builder: (context, state) => FashionRouteScreens.adminAudit(context),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
