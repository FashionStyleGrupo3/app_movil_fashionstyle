// @source-mirror: src/router/index.js
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_inventory_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_garments_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_pos_sales_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_orders_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_production_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_payments_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_security_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_audit_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_account_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/login_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/register_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/verify_email_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/forgot_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/reset_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/common/placeholder_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_help_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_messages_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/cart_checkout_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/contact_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/terms_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/catalog_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/home_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/product_detail_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/profile_screen.dart';
import 'package:go_router/go_router.dart';

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
  static WidgetBuilder contact = (context) => const ContactScreen();
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
  static WidgetBuilder adminHelp = (context) => const AdminHelpScreen();
  static WidgetBuilder adminMessages = (context) => const AdminMessagesScreen();
}
