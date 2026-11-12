// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/favorites_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_data_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_orders_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? initialSection;

  const ProfileScreen({
    super.key,
    this.initialSection,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialSection == 'pedidos') {
      initialIndex = 1;
    } else if (widget.initialSection == 'favoritos') {
      initialIndex = 2;
    }

    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return PublicShellLayout(
      currentIndex: 3,
      child: Column(
        children: [
          // 1. TARJETA CREDENCIAL MIEMBRO NOCTURNA (#14161F)
          _construirTarjetaCredencial(authState),

          // 2. BARRA SEGMENTADA DE PESTAÑAS (PILL BAR)
          _construirBarraPestanas(),

          // 3. CONTENIDO DE LAS PESTAÑAS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SeccionMisDatos(),
                SeccionMisPedidos(),
                SeccionFavoritos(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaCredencial(AuthState authState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: FashionColors.inkPrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FashionColors.borderSubtle.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Retícula sutil de sastrería
          const Positioned.fill(
            child: AtelierPatternBackground(
              colorFondo: FashionColors.inkPrimary,
              opacidadReticula: 0.08,
              child: SizedBox.expand(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar con anillo Terracotta (#B83A24)
                    Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: FashionColors.brandAccent, width: 2),
                        color: FashionColors.surfaceCard,
                      ),
                      child: ClipOval(
                        child: (authState.fotoUsuario != null && authState.fotoUsuario!.isNotEmpty)
                            ? Image.network(
                                ImageUrlResolver.resolve(authState.fotoUsuario!),
                                key: ValueKey(authState.fotoUsuario),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarFallback(authState),
                              )
                            : _avatarFallback(authState),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario : 'Usuario Fashion Style',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            authState.correoUsuario,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: FashionColors.surfaceMuted.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Badges semánticos de rol
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: authState.tieneAccesoAdmin
                                      ? FashionColors.editorialGoldDark.withValues(alpha: 0.18)
                                      : FashionColors.slateAccent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: authState.tieneAccesoAdmin
                                        ? FashionColors.editorialGoldDark.withValues(alpha: 0.4)
                                        : FashionColors.slateAccent.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  authState.tieneAccesoAdmin ? 'STAFF / ADMIN' : 'CLIENTE',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: authState.tieneAccesoAdmin
                                        ? FashionColors.editorialGoldDark
                                        : FashionColors.slateAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Botón de acceso a Cockpit Admin si tiene permisos
                if (authState.tieneAccesoAdmin) ...[
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go('/admin'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, size: 16, color: FashionColors.brandAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Ir a Panel de Administración',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(AuthState authState) {
    return Container(
      color: FashionColors.inkPrimary,
      alignment: Alignment.center,
      child: Text(
        authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0].toUpperCase() : 'U',
        style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: FashionColors.brandAccent),
      ),
    );
  }

  Widget _construirBarraPestanas() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FashionColors.surfaceMuted,
        borderRadius: BorderRadius.circular(100),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: FashionColors.inkPrimary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: FashionColors.inkSecondary,
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(text: 'Mis Datos'),
          Tab(text: 'Mis Pedidos'),
          Tab(text: 'Favoritos'),
        ],
      ),
    );
  }
}
