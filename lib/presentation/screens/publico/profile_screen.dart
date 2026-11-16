// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/image_crop_editor_dialog.dart';
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
    final pick = await picker.pickImage(source: origen, imageQuality: 90, maxWidth: 1600, maxHeight: 1600);
    if (pick == null) return;

    final bytes = await pick.readAsBytes();
    if (!mounted) return;

    final File? cropped = await ImageCropEditorDialog.show(
      context,
      imageBytes: bytes,
      aspectRatio: 1.0,
      title: 'Ajustar foto de perfil',
    );
    if (cropped == null) return;

    setState(() => _subiendoFoto = true);
    try {
      final res = await UserService.instance.subirFotoPerfil(
        cropped.path,
        'avatar_${DateTime.now().millisecondsSinceEpoch}.png',
      );
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
      currentIndex: 4,
      child: Column(
        children: [
          // 1. FRANJA DE IDENTIDAD COMPACTA (56x56 avatar cuadrado #111111 + badge terracota #B85338)
          _construirCabeceraIntegrada(authState),

          // 2. BARRA DE PESTAÑAS EDGE-TO-EDGE DE 3 COLUMNAS (#111111 ACTIVA / #EFECE6 INACTIVA)
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar cuadrado 56x56 #111111 con badge terracota #B85338
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: _subiendoFoto
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
              Positioned(
                bottom: -3,
                right: -3,
                child: Material(
                  color: const Color(0xFFB85338),
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _subiendoFoto ? null : () => _abrirOpcionesFoto(context, authState),
                    child: const Padding(
                      padding: EdgeInsets.all(4.5),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario : 'Usuario Fashion Style',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  authState.correoUsuario,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF6F6F6F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String inicial) {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      child: Text(
        inicial,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _construirBarraPestanas() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFEFECE6),
        border: Border(
          top: BorderSide(color: Color(0xFFD8CFC2), width: 1),
          bottom: BorderSide(color: Color(0xFFD8CFC2), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(
          color: Color(0xFF111111),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6F6F6F),
        labelStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        tabs: const [
          Tab(text: 'Mis datos'),
          Tab(text: 'Mis pedidos'),
          Tab(text: 'Favoritos'),
        ],
      ),
    );
  }
}
