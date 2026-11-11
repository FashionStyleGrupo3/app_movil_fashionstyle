// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/favorites_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_data_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_orders_section.dart';
import 'package:google_fonts/google_fonts.dart';

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
          // CABECERA CON AVATAR Y DATOS BÁSICOS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: FashionColors.rosaSuave,
                      backgroundImage: (authState.fotoUsuario != null && authState.fotoUsuario!.isNotEmpty)
                          ? NetworkImage(authState.fotoUsuario!)
                          : null,
                      child: (authState.fotoUsuario == null || authState.fotoUsuario!.isEmpty)
                          ? Text(
                              authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: FashionColors.rosaOscuro),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario : 'Usuario Fashion Style',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: FashionColors.textoOscuro,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authState.correoUsuario,
                            style: const TextStyle(fontSize: 13, color: FashionColors.textoMuted),
                          ),
                          if (authState.tieneAccesoAdmin)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: FashionColors.rosaSuave,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ROL STAFF / ADMINISTRADOR',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FashionColors.rosaOscuro),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // PESTAÑAS INTERNAS
                TabBar(
                  controller: _tabController,
                  labelColor: FashionColors.negroElegante,
                  unselectedLabelColor: FashionColors.textoMuted,
                  indicatorColor: FashionColors.rosaCorporativo,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Mis Datos'),
                    Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Mis Pedidos'),
                    Tab(icon: Icon(Icons.favorite_border, size: 18), text: 'Favoritos'),
                  ],
                ),
              ],
            ),
          ),

          // CONTENIDO DE LAS PESTAÑAS
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
}

// ============================================================================
// 1. SECCIÓN MIS DATOS (Avatar, Perfil, Cambio de Correo y Contraseña)
// ============================================================================
