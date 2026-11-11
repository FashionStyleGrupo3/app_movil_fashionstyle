// @source-mirror: src/views/publico/VistaCarrito.vue, src/views/publico/VistaTerminos.vue
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/data/models/cart/cart_item.dart';
import 'package:fashion_style_mobile/data/models/payment/wompi_checkout_data.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/price_info.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_filters.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/city_validation_service.dart';
import 'package:fashion_style_mobile/data/services/favorites_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/data/services/wompi_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/cart_checkout_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/product_card.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/size_guide_modal.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/cart_drawer.dart';
import 'package:fashion_style_mobile/presentation/widgets/payment/wompi_checkout_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _termino;

  @override
  void initState() {
    super.initState();
    _cargarTerminos();
  }

  Future<void> _cargarTerminos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.dio.get('/terminos-condiciones');
      final data = ApiResponseParser.extractData(response);
      if (mounted) {
        setState(() {
          _termino = data is Map<String, dynamic> ? data : {};
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No fue posible cargar los términos y condiciones desde el servidor.';
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicShellLayout(
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: FashionColors.peligro),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante),
                          onPressed: _cargarTerminos,
                          child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: FashionColors.grisBorde),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _termino?['titulo']?.toString() ?? 'Términos y Condiciones de Uso',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.textoOscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Versión ${_termino?['version'] ?? '1.0'}',
                          style: const TextStyle(fontSize: 12, color: FashionColors.textoMuted),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          _termino?['contenido']?.toString() ??
                              'Al acceder a nuestra plataforma y adquirir productos, aceptas nuestros términos de despacho, garantías y tratamiento seguro de datos.',
                          style: const TextStyle(fontSize: 14, height: 1.6, color: FashionColors.textoOscuro),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
