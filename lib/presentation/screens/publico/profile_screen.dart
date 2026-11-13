// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
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
  bool _subiendoFoto = false;

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

  Future<void> _abrirOpcionesFoto(BuildContext context, AuthState authState) async {
    final ImageSource? origen = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: FashionColors.canvasBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: FashionColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Foto de Perfil',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: FashionColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FashionColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: FashionColors.inkPrimary),
                ),
                title: Text('Tomar foto con la cámara', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FashionColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: FashionColors.inkPrimary),
                ),
                title: Text('Elegir de la galería', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (authState.fotoUsuario != null && authState.fotoUsuario!.trim().isNotEmpty) ...[
                const Divider(color: FashionColors.borderSubtle, height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FashionColors.statusDanger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: FashionColors.statusDanger),
                  ),
                  title: Text(
                    'Quitar foto actual',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: FashionColors.statusDanger),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _quitarFoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (origen != null) {
      _subirFoto(origen);
    }
  }

  Future<void> _subirFoto(ImageSource origen) async {
    final picker = ImagePicker();
    final pick = await picker.pickImage(source: origen, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
    if (pick == null) return;

    setState(() => _subiendoFoto = true);
    try {
      final res = await UserService.instance.subirFotoPerfil(pick.path, pick.name);
      ref.read(authProvider.notifier).actualizarUsuario(res);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible subir tu foto.')),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _quitarFoto() async {
    setState(() => _subiendoFoto = true);
    try {
      final res = await UserService.instance.quitarFotoPerfil();
      ref.read(authProvider.notifier).actualizarUsuario(res);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible quitar la foto.')),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return PublicShellLayout(
      currentIndex: 3,
      child: Column(
        children: [
          // 1. CABECERA INTEGRADA EDITORIAL SOBRE #F7F4EF (SIN DUAL CARD NI FONDOS OSCUROS PESADOS)
          _construirCabeceraIntegrada(authState),

          // 2. PESTAÑAS SUBRAYADAS EDITORIALES (2px #111111 sobre 1px #E4DDD2)
          _construirBarraPestanas(),

          // 3. CONTENIDO DE LAS PESTAÑAS DIRECTAMENTE EN EL LIENZO
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

  Widget _construirCabeceraIntegrada(AuthState authState) {
    final inicial = (authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0] : 'U').toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar interactivo con anillo sutil y botón de cámara
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FashionColors.surfaceMuted,
                      border: Border.all(color: FashionColors.borderSubtle, width: 1.5),
                    ),
                    child: ClipOval(
                      child: _subiendoFoto
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: FashionColors.inkPrimary),
                              ),
                            )
                          : (authState.fotoUsuario != null && authState.fotoUsuario!.trim().isNotEmpty)
                              ? Image.network(
                                  ImageUrlResolver.resolve(authState.fotoUsuario!),
                                  key: ValueKey(authState.fotoUsuario),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _avatarFallback(inicial),
                                )
                              : _avatarFallback(inicial),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Material(
                      color: FashionColors.inkPrimary,
                      shape: const CircleBorder(),
                      elevation: 1,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _subiendoFoto ? null : () => _abrirOpcionesFoto(context, authState),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ),
                ],
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
                        color: FashionColors.inkPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authState.correoUsuario,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: FashionColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: authState.tieneAccesoAdmin
                            ? FashionColors.editorialGoldDark.withValues(alpha: 0.14)
                            : FashionColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: authState.tieneAccesoAdmin
                              ? FashionColors.editorialGoldDark.withValues(alpha: 0.45)
                              : FashionColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        authState.tieneAccesoAdmin ? 'STAFF / ADMIN' : 'CLIENTE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: authState.tieneAccesoAdmin
                              ? FashionColors.editorialGoldDark
                              : FashionColors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Botón Panel de Administración con alto contraste y fondo suave
          if (authState.tieneAccesoAdmin) ...[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.go('/admin'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: FashionColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FashionColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, size: 18, color: FashionColors.inkPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Panel de Administración',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: FashionColors.inkPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: FashionColors.inkPrimary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarFallback(String inicial) {
    return Container(
      color: FashionColors.surfaceMuted,
      alignment: Alignment.center,
      child: Text(
        inicial,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: FashionColors.inkPrimary,
        ),
      ),
    );
  }

  Widget _construirBarraPestanas() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FashionColors.borderSubtle, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 2.0,
        indicatorColor: FashionColors.inkPrimary,
        labelColor: FashionColors.inkPrimary,
        unselectedLabelColor: FashionColors.inkSecondary,
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Mis Datos'),
          Tab(text: 'Mis Pedidos'),
          Tab(text: 'Favoritos'),
        ],
      ),
    );
  }
}
