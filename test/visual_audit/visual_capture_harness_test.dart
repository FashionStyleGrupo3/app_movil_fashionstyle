import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_account_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_audit_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_garments_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_inventory_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_orders_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_payments_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_pos_sales_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_production_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_security_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/forgot_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/login_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/register_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/reset_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/verify_email_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/cart_checkout_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/catalog_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/home_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/product_detail_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/profile_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/terms_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/garment_form_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/garments/promotions_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/bulk_invoice_upload_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/create_invoice_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/dispatch_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/pos/new_pos_sale_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/cart_drawer.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/size_guide_modal.dart';

import 'font_loader_helper.dart';
import 'mock_data.dart';
import 'mock_http_adapter.dart';

// Comparator que guarda simultáneamente en goldens locales y en qa-captures
class DirectCaptureComparator extends LocalFileComparator {
  final String qaOutputPath;
  final String? qaSecondaryOutputPath;

  DirectCaptureComparator(
    super.testFile, {
    required this.qaOutputPath,
    this.qaSecondaryOutputPath,
  });

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final goldenFile = File.fromUri(basedir.resolveUri(golden));
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);

    final filename = golden.pathSegments.last;
    final targetFile = File('$qaOutputPath/$filename');
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(imageBytes, flush: true);

    if (qaSecondaryOutputPath != null) {
      final secFile = File('$qaSecondaryOutputPath/$filename');
      await secFile.parent.create(recursive: true);
      await secFile.writeAsBytes(imageBytes, flush: true);
    }
  }
}

// Modelos Fake de Notifier para inyección
class FakeAuthNotifier extends AuthNotifier {
  final AuthState initial;
  FakeAuthNotifier(this.initial) : super() {
    state = initial;
  }
}

class FakeCartNotifier extends CartNotifier {
  final CartState initial;
  FakeCartNotifier(this.initial) : super() {
    state = initial;
  }
}

class FakeFavoritesNotifier extends FavoritesNotifier {
  final FavoritesState initial;
  FakeFavoritesNotifier(this.initial) : super() {
    state = initial;
  }
}

// Representación de Viewport de QA
class QaViewport {
  final String id;
  final double width;
  final double height;
  final double textScale;

  const QaViewport({
    required this.id,
    required this.width,
    required this.height,
    required this.textScale,
  });
}

const viewports = [
  QaViewport(
    id: 'compact_360x780_scale115',
    width: 360,
    height: 780,
    textScale: 1.15,
  ),
  QaViewport(
    id: 'standard_390x844_scale100',
    width: 390,
    height: 844,
    textScale: 1.0,
  ),
];

// Mock de Chrome Wompi sin native webview channel
class WompiChromeMockWidget extends StatelessWidget {
  const WompiChromeMockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: FashionColors.inkPrimary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: FashionColors.atelierJade,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Pago Seguro',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wompi · Bancolombia',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: Colors.white70),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const LinearProgressIndicator(
            color: FashionColors.brandAccent,
            backgroundColor: FashionColors.inkPrimary,
            minHeight: 3,
          ),
          Expanded(
            child: Container(
              color: FashionColors.canvasBackground,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: FashionColors.surfaceCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: FashionColors.borderSubtle),
                      ),
                      child: const Center(
                        child: Icon(Icons.verified_user_outlined, color: FashionColors.brandAccent, size: 28),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Conectando de forma segura con Bancolombia / Wompi...',
                      style: GoogleFonts.plusJakartaSans(
                        color: FashionColors.inkPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Referencia: FS-2026-1084 · Total: \$430.000 COP',
                      style: GoogleFonts.jetBrainsMono(
                        color: FashionColors.inkSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mock Modal Guía de Tallas (Elástico)
class SizeGuideModalContainer extends StatelessWidget {
  const SizeGuideModalContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const AtelierMonogram(size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guía de Tallas Atelier',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: FashionColors.inkPrimary,
                        ),
                      ),
                      Text(
                        'Medidas corporales en centímetros (cm)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: FashionColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: FashionColors.inkSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: FashionColors.borderSubtle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Table(
                  border: TableBorder.all(color: FashionColors.borderSubtle, borderRadius: BorderRadius.circular(8)),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: FashionColors.surfaceMuted),
                      children: ['Talla', 'Busto', 'Cintura', 'Cadera', 'Largo'].map((h) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(h, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 11)),
                      )).toList(),
                    ),
                    ...SizeGuideModal.medidas.map((m) => TableRow(
                      children: [m['talla']!, m['busto']!, m['cintura']!, m['cadera']!, m['largo']!].map((v) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(v, style: GoogleFonts.jetBrainsMono(fontSize: 11)),
                      )).toList(),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Bento Modulos Container
class BentoModulosContainer extends StatelessWidget {
  const BentoModulosContainer({super.key});

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Módulos Operativos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: FashionColors.inkPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Gestión Omnicanal FashionStyle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: FashionColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: FashionColors.inkSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(color: FashionColors.borderSubtle, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildBentoTile('Panel de Control', 'KPIs en vivo y analítica', Icons.dashboard_outlined, true),
                _buildBentoTile('Ventas POS', 'Caja mostrador & PDF 80mm', Icons.receipt_long_outlined, false),
                _buildBentoTile('Pedidos y Facturas', 'Despachos web y seguimiento', Icons.local_shipping_outlined, false),
                _buildBentoTile('Inventario / Kárdex', 'Stock en tiempo real y alertas', Icons.inventory_2_outlined, false),
                _buildBentoTile('Gestión de Prendas', 'Catálogo atelier, tallas y fotos', Icons.checkroom_outlined, false),
                _buildBentoTile('Producción / Costos', 'Cálculo de materia prima y OP', Icons.precision_manufacturing_outlined, false),
                _buildBentoTile('Pagos & Dispersión', 'Pasarelas Wompi y comisiones', Icons.payments_outlined, false),
                _buildBentoTile('Clientes & Usuarios', 'Roles en vivo y accesos', Icons.people_outline, false),
                _buildBentoTile('Bitácora de Auditoría', 'Trazabilidad de cambios', Icons.history_edu_outlined, false),
                _buildBentoTile('Mi Cuenta', 'Perfil del operador', Icons.account_circle_outlined, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoTile(String title, String subtitle, IconData icon, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? FashionColors.surfaceMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? FashionColors.inkPrimary : FashionColors.borderSubtle,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: active ? FashionColors.brandAccent : FashionColors.inkSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary)),
              ],
            ),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: FashionColors.brandAccent, borderRadius: BorderRadius.circular(4)),
              child: Text('ACTIVO', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

const guestAuth = AuthState(
  token: null,
  sesionHidratada: true,
  roles: [],
  usuario: null,
);

void main() {
  final List<Map<String, dynamic>> overflowRecords = [];

  setUpAll(() async {
    // 1. Inicializar fuentes Zero-Ahem
    await loadAppFontsZeroAhem();

    // 2. Mock Adapter para Dio de ApiClient
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => Directory.systemTemp.path,
    );

    ApiClient.instance.dio.httpClientAdapter = MockAuditHttpAdapter();

    // 3. SharedPreferences con token y usuario admin
    SharedPreferences.setMockInitialValues({
      'fs_token': 'mock_jwt_token_admin',
      'fs_user': jsonEncode({
        'id': 1,
        'name': 'Administrador General',
        'email': 'admin@fashionstyle.com',
        'telefono': '3001234567',
        'direccion': 'Calle 10 # 40-20',
        'ciudad': 'Bogotá',
        'roles': ['administrador'],
      }),
      'fs_roles': jsonEncode(['administrador']),
    });

    // 4. Configurar DirectCaptureComparator hacia qa-captures
    final testUri = Uri.file('${Directory.current.path}/test/visual_audit/visual_capture_harness_test.dart');
    goldenFileComparator = DirectCaptureComparator(
      testUri,
      qaOutputPath: 'F:/FashionStyle/qa-captures/baseline-v1.3.0',
      qaSecondaryOutputPath: 'F:/FashionStyle/qa-captures/v1.4.0',
    );
  });

  tearDownAll(() {
    // Guardar inventario de desbordamientos / RenderFlex overflow
    final reportBaseline = File('F:/FashionStyle/qa-captures/baseline-v1.3.0/overflow_inventory.json');
    reportBaseline.parent.createSync(recursive: true);
    reportBaseline.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(overflowRecords));

    final reportV140 = File('F:/FashionStyle/qa-captures/v1.4.0/overflow_inventory.json');
    reportV140.parent.createSync(recursive: true);
    reportV140.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(overflowRecords));
  });

  // Helper para captura de pantalla con SQA Gates
  Future<void> captureScreen({
    required WidgetTester tester,
    required String stateId,
    required QaViewport vp,
    required Widget child,
    AuthState? auth,
    CartState? cart,
    FavoritesState? favorites,
    bool isModalSheet = false,
    Finder? modalExpectation,
  }) async {
    final logicalSize = Size(vp.width, vp.height);
    await tester.binding.setSurfaceSize(logicalSize);
    tester.view.physicalSize = Size(vp.width * 2.0, vp.height * 2.0);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = vp.textScale;

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains('RenderFlex overflowed') || msg.contains('A RenderFlex overflowed')) {
        overflowRecords.add({
          'state_id': stateId,
          'viewport': vp.id,
          'width': vp.width,
          'height': vp.height,
          'text_scale': vp.textScale,
          'summary': details.summary.toString(),
          'exception': msg,
        });

      }
    };

    final effectiveAuth = auth ??
        const AuthState(
          token: 'mock_jwt_token_admin',
          sesionHidratada: true,
          roles: ['administrador'],
          usuario: {
            'id': 1,
            'name': 'Administrador General',
            'email': 'admin@fashionstyle.com',
            'telefono': '3001234567',
            'direccion': 'Calle 10 # 40-20',
            'ciudad': 'Bogotá',
            'roles': ['administrador'],
          },
        );

    final effectiveCart = cart ??
        const CartState(
          items: mockCartItems,
          cajonAbierto: false,
        );

    final effectiveFavs = favorites ?? const FavoritesState(ids: [1, 2]);

    final GlobalKey captureKey = GlobalKey();

    Widget rootWidget = RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FashionTheme.lightTheme,
        home: isModalSheet
            ? Scaffold(
                backgroundColor: const Color(0x8A000000),
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              )
            : child,
      ),
    );

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier(effectiveAuth)),
            cartProvider.overrideWith((ref) => FakeCartNotifier(effectiveCart)),
            favoritesProvider.overrideWith((ref) => FakeFavoritesNotifier(effectiveFavs)),
          ],
          child: rootWidget,
        ),
      );

      // Deterministic multi-frame settling loop (25 frames x 100ms)
      for (int i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // SQA Gate 1: No CircularProgressIndicator on screen
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'Screen $stateId on ${vp.id} still shows a CircularProgressIndicator',
      );

      // SQA Gate 2: Modal expectation assertion
      if (modalExpectation != null) {
        expect(
          modalExpectation,
          findsAtLeastNWidgets(1),
          reason: 'Expected modal content not found in $stateId on ${vp.id}',
        );
      }

      // SQA Gate 3: Zero RenderFlex overflow errors
      expect(
        overflowRecords.where((r) => r['state_id'] == stateId && r['viewport'] == vp.id),
        isEmpty,
        reason: 'RenderFlex overflow in $stateId on ${vp.id}',
      );
    } finally {
      FlutterError.onError = originalOnError;
    }

    final goldenName = '${stateId}__${vp.id}.png';
    await expectLater(
      find.byKey(captureKey),
      matchesGoldenFile(Uri.parse(goldenName)),
    );

    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  }

  // ==========================================
  // GRUPO 1: TIENDA PÚBLICA & ESCAPARATE (1-10)
  // ==========================================
  group('Grupo 1: Tienda Pública & Escaparate', () {
    testWidgets('01_home_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '01_home_screen',
          vp: vp,
          child: const HomeScreen(),
          auth: guestAuth,
        );
      }
    });

    testWidgets('02_catalog_screen_populated', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '02_catalog_screen_populated',
          vp: vp,
          child: const CatalogScreen(),
          auth: guestAuth,
        );
      }
    });

    testWidgets('03_catalog_screen_empty', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '03_catalog_screen_empty',
          vp: vp,
          child: const CatalogScreen(searchQuery: '___NON_EXISTING_PRENDA___'),
          auth: guestAuth,
        );
      }
    });

    testWidgets('04_product_detail_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '04_product_detail_screen',
          vp: vp,
          child: const ProductDetailScreen(productId: 1),
          auth: guestAuth,
        );
      }
    });

    testWidgets('05_modal_size_guide', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '05_modal_size_guide',
          vp: vp,
          child: const SizeGuideModalContainer(),
          isModalSheet: true,
          auth: guestAuth,
          modalExpectation: find.text('Guía de Tallas Atelier'),
        );
      }
    });

    testWidgets('06_cart_drawer_populated', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '06_cart_drawer_populated',
          vp: vp,
          child: const CartDrawerWidget(),
          cart: const CartState(items: mockCartItems, cajonAbierto: true),
          auth: guestAuth,
          modalExpectation: find.text('Bolsa Atelier'),
        );
      }
    });

    testWidgets('07_cart_drawer_empty', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '07_cart_drawer_empty',
          vp: vp,
          child: const CartDrawerWidget(),
          cart: const CartState(items: [], cajonAbierto: true),
          auth: guestAuth,
          modalExpectation: find.text('Tu bolsa está vacía'),
        );
      }
    });

    testWidgets('08_cart_checkout_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '08_cart_checkout_screen',
          vp: vp,
          child: const CartCheckoutScreen(),
          cart: const CartState(items: mockCartItems),
          auth: guestAuth,
        );
      }
    });

    testWidgets('09_terms_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '09_terms_screen',
          vp: vp,
          child: const TermsScreen(),
          auth: guestAuth,
        );
      }
    });

    testWidgets('10_wompi_checkout_chrome', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '10_wompi_checkout_chrome',
          vp: vp,
          child: const WompiChromeMockWidget(),
          isModalSheet: true,
          auth: guestAuth,
          modalExpectation: find.text('Wompi · Bancolombia'),
        );
      }
    });
  });

  // ==========================================
  // GRUPO 2: AUTENTICACIÓN (11-15)
  // ==========================================
  group('Grupo 2: Autenticación', () {
    testWidgets('11_auth_login_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '11_auth_login_screen',
          vp: vp,
          child: const LoginScreen(),
          auth: guestAuth,
        );
      }
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('12_auth_register_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '12_auth_register_screen',
          vp: vp,
          child: const RegisterScreen(),
          auth: guestAuth,
        );
      }
    });

    testWidgets('13_auth_forgot_password', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '13_auth_forgot_password',
          vp: vp,
          child: const ForgotPasswordScreen(),
          auth: guestAuth,
        );
      }
    });

    testWidgets('14_auth_reset_password', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '14_auth_reset_password',
          vp: vp,
          child: const ResetPasswordScreen(
            correo: 'admin@fashionstyle.com',
            token: 'TOK-12345',
          ),
          auth: guestAuth,
        );
      }
    });

    testWidgets('15_auth_verify_email', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '15_auth_verify_email',
          vp: vp,
          child: const VerifyEmailScreen(
            correo: 'cliente@fashionstyle.com',
          ),
          auth: guestAuth,
        );
      }
    });
  });

  // ==========================================
  // GRUPO 3: MI PERFIL CLIENTE (16-18)
  // ==========================================
  group('Grupo 3: Mi Perfil Cliente', () {
    const clientAuth = AuthState(
      token: 'mock_jwt_token_client',
      sesionHidratada: true,
      roles: ['cliente'],
      usuario: {
        'id': 3,
        'name': 'Valentina Morales',
        'email': 'valentina.morales@correo.co',
        'telefono': '3157894512',
        'direccion': 'Carrera 7 # 120-40',
        'ciudad': 'Bogotá',
        'roles': ['cliente'],
      },
    );

    testWidgets('16_profile_mis_datos', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '16_profile_mis_datos',
          vp: vp,
          child: const ProfileScreen(initialSection: 'datos'),
          auth: clientAuth,
        );
      }
    });

    testWidgets('17_profile_mis_pedidos', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '17_profile_mis_pedidos',
          vp: vp,
          child: const ProfileScreen(initialSection: 'pedidos'),
          auth: clientAuth,
        );
      }
    });

    testWidgets('18_profile_favoritos', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '18_profile_favoritos',
          vp: vp,
          child: const ProfileScreen(initialSection: 'favoritos'),
          auth: clientAuth,
          favorites: const FavoritesState(ids: [1, 2]),
        );
      }
    });
  });

  // ==========================================
  // GRUPO 4: ADMIN SHELL & MÓDULOS (19-35)
  // ==========================================
  group('Grupo 4: Panel Administrativo & Módulos Operativos', () {
    testWidgets('19_admin_shell_bento', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '19_admin_shell_bento',
          vp: vp,
          child: const BentoModulosContainer(),
          isModalSheet: true,
          modalExpectation: find.text('Módulos Operativos'),
        );
      }
    });

    testWidgets('20_admin_dashboard_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '20_admin_dashboard_screen',
          vp: vp,
          child: const AdminDashboardScreen(),
        );
      }
    });

    testWidgets('21_admin_inventory_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '21_admin_inventory_screen',
          vp: vp,
          child: const AdminInventoryScreen(),
        );
      }
    });

    testWidgets('22_admin_garments_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '22_admin_garments_screen',
          vp: vp,
          child: const AdminGarmentsScreen(),
        );
      }
    });

    testWidgets('23_modal_formulario_prenda', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '23_modal_formulario_prenda',
          vp: vp,
          child: ModalFormularioPrenda(
            prenda: mockProducts.first,
            categorias: mockCategories,
            catalogos: mockCatalogs,
            onGuardado: () {},
          ),
          isModalSheet: true,
          modalExpectation: find.text('Editar Prenda'),
        );
      }
    });

    testWidgets('24_modal_promociones_sheet', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '24_modal_promociones_sheet',
          vp: vp,
          child: ModalPromocionesSheet(
            productos: mockProducts,
          ),
          isModalSheet: true,
          modalExpectation: find.text('Campañas y Promociones'),
        );
      }
    });

    testWidgets('25_admin_pos_sales_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '25_admin_pos_sales_screen',
          vp: vp,
          child: const AdminPosSalesScreen(),
        );
      }
    });

    testWidgets('26_modal_nueva_venta_pos', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '26_modal_nueva_venta_pos',
          vp: vp,
          child: ModalNuevaVentaPos(
            onCobrada: () {},
          ),
          isModalSheet: true,
          modalExpectation: find.text('Caja Mostrador (POS)'),
        );
      }
    });

    testWidgets('27_admin_orders_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '27_admin_orders_screen',
          vp: vp,
          child: const AdminOrdersAndInvoicesScreen(),
        );
      }
    });

    testWidgets('28_modal_crear_factura_sheet', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '28_modal_crear_factura_sheet',
          vp: vp,
          child: ModalCrearFacturaSheet(
            onCreada: () {},
          ),
          isModalSheet: true,
          modalExpectation: find.text('Emitir Factura Manual'),
        );
      }
    });

    testWidgets('29_modal_carga_masiva_facturas', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '29_modal_carga_masiva_facturas',
          vp: vp,
          child: ModalCargaMasivaFacturasSheet(
            onCompletada: () {},
          ),
          isModalSheet: true,
          modalExpectation: find.text('Carga Masiva de Facturas'),
        );
      }
    });

    testWidgets('30_modal_gestion_despacho', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '30_modal_gestion_despacho',
          vp: vp,
          child: ModalGestionDespachoSheet(
            pedido: mockOrders.first,
            onActualizado: () {},
          ),
          isModalSheet: true,
          modalExpectation: find.textContaining('Gestionar Despacho'),
        );
      }
    });

    testWidgets('31_admin_production_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '31_admin_production_screen',
          vp: vp,
          child: const AdminProductionScreen(),
        );
      }
    });

    testWidgets('32_admin_payments_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '32_admin_payments_screen',
          vp: vp,
          child: const AdminPaymentsConfigScreen(),
        );
      }
    });

    testWidgets('33_admin_security_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '33_admin_security_screen',
          vp: vp,
          child: const AdminSecurityAndUsersScreen(),
        );
      }
    });

    testWidgets('34_admin_audit_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '34_admin_audit_screen',
          vp: vp,
          child: const AdminAuditScreen(),
        );
      }
    });

    testWidgets('35_admin_account_screen', (tester) async {
      for (final vp in viewports) {
        await captureScreen(
          tester: tester,
          stateId: '35_admin_account_screen',
          vp: vp,
          child: const AdminAccountScreen(),
        );
      }
    });
  });
}
