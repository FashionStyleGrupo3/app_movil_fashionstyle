// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/services/security_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSecurityAndUsersScreen extends ConsumerStatefulWidget {
  const AdminSecurityAndUsersScreen({super.key});

  @override
  ConsumerState<AdminSecurityAndUsersScreen> createState() => _AdminSecurityAndUsersScreenState();
}

class _AdminSecurityAndUsersScreenState extends ConsumerState<AdminSecurityAndUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _cargando = true;
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _usuarios = [];

  @override
  void initState() {
    super.initState();
    final esAdmin = ref.read(authProvider).esAdmin;
    _tabController = TabController(length: esAdmin ? 2 : 1, vsync: this);
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    final esAdmin = ref.read(authProvider).esAdmin;
    try {
      final clientes = await SecurityService.instance.obtenerClientes();
      List<Map<String, dynamic>> usuarios = [];
      if (esAdmin) {
        usuarios = await SecurityService.instance.obtenerUsuarios();
      }
      if (mounted) {
        setState(() {
          _clientes = clientes;
          _usuarios = usuarios;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirModalNuevoUsuario() {
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String rol = 'empleado';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: FashionColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FashionColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Registrar Colaborador Staff',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: FashionColors.inkSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: FashionColors.borderSubtle),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: nomCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo *',
                          filled: true,
                          fillColor: FashionColors.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo corporativo *',
                          filled: true,
                          fillColor: FashionColors.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: telCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          filled: true,
                          fillColor: FashionColors.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: rol,
                        decoration: InputDecoration(
                          labelText: 'Rol asignado',
                          filled: true,
                          fillColor: FashionColors.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'empleado', child: Text('Empleado / Ventas POS')),
                          DropdownMenuItem(value: 'administrador', child: Text('Administrador General')),
                        ],
                        onChanged: (v) => setMState(() => rol = v ?? 'empleado'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña temporal *',
                          filled: true,
                          fillColor: FashionColors.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FashionColors.inkPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nomCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor completa los campos requeridos (*)')),
                            );
                            return;
                          }
                          try {
                            await SecurityService.instance.crearUsuario({
                              'nombre': nomCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'telefono': telCtrl.text.trim(),
                              'password': passCtrl.text,
                              'rol': rol,
                            });
                            _cargarTodo();
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Usuario registrado con éxito'),
                                  backgroundColor: FashionColors.statusSuccess,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible registrar al usuario.')),
                                  backgroundColor: FashionColors.statusDanger,
                                ),
                              );
                            }
                          }
                        },
                        child: Text('Crear Usuario', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(authProvider).esAdmin;

    return AdminShellLayout(
      currentPath: '/admin/seguridad',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: FashionColors.inkPrimary,
              unselectedLabelColor: FashionColors.inkSecondary,
              indicatorColor: FashionColors.brandAccent,
              labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                const Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Clientes'),
                if (esAdmin) const Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Staff / Empleados'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.brandAccent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Pestaña Clientes
                      ListView.builder(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                        itemCount: _clientes.length,
                        itemBuilder: (context, index) {
                          final c = _clientes[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: FashionColors.surfaceMuted, child: Icon(Icons.person, color: FashionColors.brandAccent)),
                              title: Text(c['nombre']?.toString() ?? 'Cliente', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5, color: FashionColors.inkPrimary)),
                              subtitle: Text('${c['email'] ?? c['correo'] ?? ''} · Ciudad: ${c['ciudad'] ?? "N/A"}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary)),
                            ),
                          );
                        },
                      ),
                      // Pestaña Usuarios Staff
                      if (esAdmin)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Colaboradores (${_usuarios.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15, color: FashionColors.inkPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FashionColors.brandAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    onPressed: _abrirModalNuevoUsuario,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text('Nuevo Usuario', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 96),
                                itemCount: _usuarios.length,
                                itemBuilder: (context, index) {
                                  final u = _usuarios[index];
                                  final id = u['id_usuario'] ?? u['id'];
                                  final rol = (u['rol'] ?? u['roles']?[0]?['nombre'] ?? 'empleado').toString().toLowerCase();
                                  final activo = u['activo'] == true || u['activo'] == 1;

                                  final colorRol = rol.contains('admin')
                                      ? FashionColors.brandAccent
                                      : (rol.contains('empleado') || rol.contains('staff') ? FashionColors.atelierJade : FashionColors.editorialOchre);

                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
                                    child: ListTile(
                                      title: Text(u['nombre']?.toString() ?? 'Usuario', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5, color: FashionColors.inkPrimary)),
                                      subtitle: Row(
                                        children: [
                                          Text('${u['email'] ?? ''} · ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: colorRol.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              rol.toUpperCase(),
                                              style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: colorRol),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Switch(
                                        value: activo,
                                        activeThumbColor: FashionColors.statusSuccess,
                                        onChanged: (val) async {
                                          try {
                                            await SecurityService.instance.actualizarUsuario(id, {'activo': val});
                                            _cargarTodo();
                                          } catch (_) {}
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
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

// ============================================================================
// 3. BITÁCORA DE AUDITORÍA (VistaAuditoria.vue)
// ============================================================================
