// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/constants/invoice_constants.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/audit_text_formatter.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/models/audit/audit_models.dart';
import 'package:fashion_style_mobile/data/models/cart/cart_item.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_item_detail.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_item_detail.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_status.dart';
import 'package:fashion_style_mobile/data/models/payment/wompi_checkout_data.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/price_info.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_filters.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/invoice_service.dart';
import 'package:fashion_style_mobile/data/services/order_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/data/services/security_service.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/data/services/wompi_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/profile_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_data_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_orders_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/product_card.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/size_guide_modal.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/cart_drawer.dart';
import 'package:fashion_style_mobile/presentation/widgets/payment/wompi_checkout_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class SeccionFavoritos extends ConsumerStatefulWidget {
  const SeccionFavoritos();

  @override
  ConsumerState<SeccionFavoritos> createState() => _SeccionFavoritosState();
}

class _SeccionFavoritosState extends ConsumerState<SeccionFavoritos> {
  bool _cargando = true;
  List<Product> _productos = [];
  List<Promotion> _promociones = [];

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    try {
      final resultados = await Future.wait([
        ProductService.instance.obtenerProductos(),
        PromotionService.instance.obtenerPromocionesVigentes(),
      ]);

      if (mounted) {
        setState(() {
          _productos = resultados[0] as List<Product>;
          _promociones = resultados[1] as List<Promotion>;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favsState = ref.watch(favoritesProvider);
    final prendasFavoritas = _productos.where((p) => favsState.esFavorito(p.idProducto)).toList();

    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo));
    }

    if (prendasFavoritas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border, size: 48, color: FashionColors.textoMuted),
              const SizedBox(height: 12),
              const Text(
                'No tienes prendas guardadas en favoritos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                onPressed: () => context.go('/catalogo'),
                child: const Text('Descubrir catálogo'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prendasFavoritas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        return ProductCardWidget(
          producto: prendasFavoritas[index],
          promocionesVigentes: _promociones,
        );
      },
    );
  }
}
