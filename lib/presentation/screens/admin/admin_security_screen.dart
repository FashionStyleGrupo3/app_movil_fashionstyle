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

  Future<void> _cambiarRol(int idUsuario, String nombre, String nuevoRol) async {
    try {
      await SecurityService.instance.asignarRolUsuario(idUsuario, nuevoRol);
      await _cargarTodo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol de "$nombre" cambiado a ${nuevoRol.toUpperCase()} correctamente.'),
            backgroundColor: FashionColors.verdeExito,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible cambiar el rol.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    }
  }

  void _abrirModalNuevoEmpleado() {
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String rol = 'empleado';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: FashionColors.backgroundCanvas,
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
                    color: FashionColors.bordeClaro,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Registrar Nuevo Empleado',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.textoPrincipal),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: FashionColors.textoMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: FashionColors.bordeClaro),
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
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Nombre completo *',
                          filled: true,
                          fillColor: FashionColors.surfaceSecondary,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.bordeClaro)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Correo corporativo *',
                          filled: true,
                          fillColor: FashionColors.surfaceSecondary,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.bordeClaro)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: telCtrl,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          filled: true,
                          fillColor: FashionColors.surfaceSecondary,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.bordeClaro)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: rol,
                        style: GoogleFonts.poppins(fontSize: 14, color: FashionColors.textoPrincipal),
                        decoration: InputDecoration(
                          labelText: 'Rol asignado',
                          filled: true,
                          fillColor: FashionColors.surfaceSecondary,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.bordeClaro)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'empleado', child: Text('Empleado / Colaborador')),
                          DropdownMenuItem(value: 'admin', child: Text('Administrador General')),
                        ],
                        onChanged: (v) => setMState(() => rol = v ?? 'empleado'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Contraseña temporal *',
                          filled: true,
                          fillColor: FashionColors.surfaceSecondary,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.bordeClaro)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FashionColors.primaryCorporate,
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
                                  content: Text('Empleado registrado con éxito'),
                                  backgroundColor: FashionColors.verdeExito,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible registrar al empleado.')),
                                  backgroundColor: FashionColors.peligro,
                                ),
                              );
                            }
                          }
                        },
                        child: Text('Registrar Empleado', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
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
            color: FashionColors.backgroundCanvas,
            child: TabBar(
              controller: _tabController,
              labelColor: FashionColors.textoPrincipal,
              unselectedLabelColor: FashionColors.textoMuted,
              indicatorColor: FashionColors.primaryCorporate,
              labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                const Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Clientes'),
                if (esAdmin) const Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Colaboradores'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.primaryCorporate))
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
                            color: FashionColors.surfaceSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.bordeClaro)),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: FashionColors.arenaSuave, child: Icon(Icons.person, color: FashionColors.primaryCorporate)),
                              title: Text(c['nombre']?.toString() ?? 'Cliente', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13.5, color: FashionColors.textoPrincipal)),
                              subtitle: Text('${c['email'] ?? c['correo'] ?? ''} · Ciudad: ${c['ciudad'] ?? "N/A"}', style: GoogleFonts.poppins(fontSize: 11, color: FashionColors.textoMuted)),
                            ),
                          );
                        },
                      ),
                      // Pestaña Usuarios Staff / Colaboradores
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
                                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: FashionColors.textoPrincipal),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FashionColors.primaryCorporate,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    onPressed: _abrirModalNuevoEmpleado,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text('+ Nuevo Empleado', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
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
                                  final id = u['id_usuario'] ?? u['id'] ?? 0;
                                  final rawRol = (u['rol'] ?? u['roles']?[0]?['nombre'] ?? u['roles']?[0] ?? 'empleado').toString().toLowerCase();
                                  final rolCanonico = rawRol.contains('admin') ? 'admin' : (rawRol.contains('cliente') ? 'cliente' : 'empleado');
                                  final activo = u['activo'] == true || u['activo'] == 1;

                                  final colorRol = rolCanonico == 'admin'
                                      ? FashionColors.primaryCorporate
                                      : (rolCanonico == 'empleado' ? FashionColors.slateAccent : FashionColors.arenaSuave);

                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: FashionColors.surfaceSecondary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.bordeClaro)),
                                    child: ListTile(
                                      title: Text(u['nombre']?.toString() ?? 'Usuario', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13.5, color: FashionColors.textoPrincipal)),
                                      subtitle: Text('${u['email'] ?? ''}', style: GoogleFonts.poppins(fontSize: 11, color: FashionColors.textoMuted)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          PopupMenuButton<String>(
                                            tooltip: 'Cambiar Rol',
                                            initialValue: rolCanonico,
                                            onSelected: (nuevoRol) {
                                              if (nuevoRol != rolCanonico) {
                                                _cambiarRol(id is int ? id : int.tryParse(id.toString()) ?? 0, u['nombre']?.toString() ?? 'Usuario', nuevoRol);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              PopupMenuItem(
                                                value: 'admin',
                                                child: Text('Administrador', style: GoogleFonts.poppins(fontWeight: rolCanonico == 'admin' ? FontWeight.w700 : FontWeight.normal)),
                                              ),
                                              PopupMenuItem(
                                                value: 'empleado',
                                                child: Text('Empleado', style: GoogleFonts.poppins(fontWeight: rolCanonico == 'empleado' ? FontWeight.w700 : FontWeight.normal)),
                                              ),
                                              PopupMenuItem(
                                                value: 'cliente',
                                                child: Text('Cliente', style: GoogleFonts.poppins(fontWeight: rolCanonico == 'cliente' ? FontWeight.w700 : FontWeight.normal)),
                                              ),
                                            ],
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: colorRol.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: colorRol.withValues(alpha: 0.4)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    rolCanonico.toUpperCase(),
                                                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: FashionColors.textoPrincipal),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  const Icon(Icons.arrow_drop_down, size: 14, color: FashionColors.textoPrincipal),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Switch(
                                            value: activo,
                                            activeColor: FashionColors.verdeExito,
                                            onChanged: (val) async {
                                              try {
                                                await SecurityService.instance.actualizarUsuario(id is int ? id : int.tryParse(id.toString()) ?? 0, {'activo': val});
                                                _cargarTodo();
                                              } catch (_) {}
                                            },
                                          ),
                                        ],
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
