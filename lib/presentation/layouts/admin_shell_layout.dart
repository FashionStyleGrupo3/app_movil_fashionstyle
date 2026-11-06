// @source-mirror: src/layouts/DisenoAdmin.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fashion_theme.dart';
import '../providers/auth_provider.dart';

class AdminShellLayout extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AdminShellLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  String _obtenerTitulo(String path) {
    if (path == '/admin') return 'Panel de Control';
    if (path.contains('/inventario')) return 'Inventario / Kárdex';
    if (path.contains('/pedidos')) return 'Pedidos Online y Facturación';
    if (path.contains('/ventas')) return 'Historial de Ventas POS';
    if (path.contains('/pagos')) return 'Control de Pagos y Dispersión';
    if (path.contains('/produccion')) return 'Producción / Costos';
    if (path.contains('/prendas')) return 'Gestión de Prendas';
    if (path.contains('/seguridad/auditoria')) return 'Bitácora de Auditoría';
    if (path.contains('/seguridad')) return 'Clientes y Usuarios';
    if (path.contains('/cuenta')) return 'Configuración de Cuenta';
    return 'Panel Administrativo';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Si pierde privilegios de personal (p. ej. degradado a cliente en vivo), sale del admin inmediatamente
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.esPersonal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/');
          }
        });
      }
    });

    final titulo = _obtenerTitulo(currentPath);

    final List<_AdminMenuItem> itemsMenu = [
      const _AdminMenuItem(titulo: 'Panel de Control', ruta: '/admin', icono: Icons.dashboard_outlined),
      const _AdminMenuItem(titulo: 'Inventario / Kárdex', ruta: '/admin/inventario', icono: Icons.inventory_2_outlined),
      const _AdminMenuItem(titulo: 'Pedidos y Facturas', ruta: '/admin/pedidos', icono: Icons.local_shipping_outlined),
      const _AdminMenuItem(titulo: 'Ventas POS', ruta: '/admin/ventas', icono: Icons.receipt_long_outlined),
      const _AdminMenuItem(titulo: 'Pagos y Dispersión', ruta: '/admin/pagos', icono: Icons.account_balance_outlined),
      const _AdminMenuItem(titulo: 'Producción / Costos', ruta: '/admin/produccion', icono: Icons.content_cut_outlined),
      const _AdminMenuItem(titulo: 'Gestión de Prendas', ruta: '/admin/prendas', icono: Icons.checkroom_outlined),
      const _AdminMenuItem(titulo: 'Clientes y Usuarios', ruta: '/admin/seguridad', icono: Icons.people_outline),
      if (authState.esAdmin)
        const _AdminMenuItem(titulo: 'Bitácora de Auditoría', ruta: '/admin/seguridad/auditoria', icono: Icons.history_edu_outlined),
      const _AdminMenuItem(titulo: 'Mi Cuenta', ruta: '/admin/cuenta', icono: Icons.account_circle_outlined),
    ];

    return Scaffold(
      backgroundColor: FashionColors.fondoClaro,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Text(
          titulo,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: FashionColors.textoOscuro,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Ir a la Tienda Pública',
            icon: const Icon(Icons.storefront_outlined, color: FashionColors.textoOscuro),
            onPressed: () => context.go('/'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: FashionColors.pizarra,
              child: Text(
                authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: FashionColors.pizarra,
        child: Column(
          children: [
            // CABECERA DEL MENÚ LATERAL
            Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              color: Colors.black.withOpacity(0.18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: FashionColors.rosaSuave,
                    child: Text(
                      authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0].toUpperCase() : 'A',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FashionColors.rosaOscuro),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario : 'Administrador',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.correoUsuario,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FashionColors.rosaCorporativo,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            authState.esAdmin ? 'ADMINISTRADOR' : 'STAFF',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // LISTA DE MÓDULOS OPERATIVOS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ...itemsMenu.map((item) {
                    final seleccionado = currentPath == item.ruta || (item.ruta != '/admin' && currentPath.startsWith(item.ruta));
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        item.icono,
                        color: seleccionado ? FashionColors.rosaCorporativo : Colors.white70,
                        size: 20,
                      ),
                      title: Text(
                        item.titulo,
                        style: TextStyle(
                          color: seleccionado ? Colors.white : Colors.white.withOpacity(0.85),
                          fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      tileColor: seleccionado ? Colors.white.withOpacity(0.12) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      onTap: () {
                        Navigator.pop(context); // cerrar drawer
                        if (currentPath != item.ruta) {
                          context.go(item.ruta);
                        }
                      },
                    );
                  }),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Divider(color: Colors.white24),
                  ),

                  // ENLACE A TIENDA PÚBLICA
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.storefront_outlined, color: Colors.white70, size: 20),
                    title: const Text('Ir a la Tienda Pública', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),

                  // CERRAR SESIÓN
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout, color: Color(0xFFFCA5A5), size: 20),
                    title: const Text('Cerrar Sesión', style: TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 13)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).cerrarSesion();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

class _AdminMenuItem {
  final String titulo;
  final String ruta;
  final IconData icono;

  const _AdminMenuItem({
    required this.titulo,
    required this.ruta,
    required this.icono,
  });
}
