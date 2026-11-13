// @source-mirror: src/router/index.js
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/router/auth_router_listenable.dart';
import 'package:fashion_style_mobile/core/router/route_screens.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

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
        path: '/contacto',
        name: 'contacto',
        builder: (context, state) => FashionRouteScreens.contact(context),
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
            path: 'ayuda',
            name: 'admin-ayuda',
            builder: (context, state) => FashionRouteScreens.adminHelp(context),
          ),
          GoRoute(
            path: 'mensajes',
            name: 'admin-mensajes',
            builder: (context, state) => FashionRouteScreens.adminMessages(context),
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
