// @source-mirror: src/router/index.js
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/router/app_router.dart';
import 'package:fashion_style_mobile/core/router/route_screens.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_inventory_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_garments_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/promotions_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/garment_form_sheet.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_pos_sales_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/pos/new_pos_sale_sheet.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_orders_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/dispatch_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/create_invoice_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/bulk_invoice_upload_sheet.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_production_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_payments_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_security_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_audit_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_account_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/password_requirements_widget.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/auth_brand_banner.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/login_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/register_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/verify_email_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/forgot_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/reset_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/common/placeholder_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/cart_checkout_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/terms_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/catalog_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/home_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/product_detail_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/profile_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_data_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_orders_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/favorites_section.dart';
import 'package:go_router/go_router.dart';

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
