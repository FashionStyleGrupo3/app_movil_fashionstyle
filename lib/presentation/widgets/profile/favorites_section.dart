// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/product_card.dart';
import 'package:go_router/go_router.dart';

class SeccionFavoritos extends ConsumerStatefulWidget {
  const SeccionFavoritos({super.key});

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
      return const Center(child: CircularProgressIndicator(color: FashionColors.inkPrimary));
    }

    if (prendasFavoritas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AtelierEmptyStateIllustration(
                type: AtelierEmptyStateType.emptyBag,
                size: 130,
              ),
              const SizedBox(height: 20),
              Text(
                'No tienes prendas en tus favoritos',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: FashionColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Guarda las piezas de sastrería que más te gusten para revisarlas o comprarlas luego.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionColors.inkPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: () => context.go('/catalogo'),
                child: const Text('Descubrir catálogo'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), // Clearance para Floating Pill Dock
      itemCount: prendasFavoritas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.63,
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
