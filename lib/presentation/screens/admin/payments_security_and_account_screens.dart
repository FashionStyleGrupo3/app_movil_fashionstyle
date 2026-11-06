// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/validators/password_validator.dart';
import '../../../data/services/pos_and_payment_service.dart';
import '../../../data/services/user_and_security_service.dart';
import '../../layouts/admin_shell_layout.dart';
import '../../providers/auth_provider.dart';
import '../autenticacion/auth_screens.dart';

// ============================================================================
// 1. CONTROL DE PAGOS Y DISPERSIÓN (VistaConfiguracionPagos.vue)
// ============================================================================

class AdminPaymentsConfigScreen extends ConsumerStatefulWidget {
  const AdminPaymentsConfigScreen({super.key});

  @override
  ConsumerState<AdminPaymentsConfigScreen> createState() => _AdminPaymentsConfigScreenState();
}

class _AdminPaymentsConfigScreenState extends ConsumerState<AdminPaymentsConfigScreen> {
  bool _cargando = true;
  ParallelPaymentControl? _control;
  List<BankAccountConfig> _cuentas = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final ctrl = await PaymentConfigService.instance.obtenerControlParaleloPagos();
      final cuentas = await PaymentConfigService.instance.obtenerCuentasDispersion();
      if (mounted) {
        setState(() {
          _control = ctrl;
          _cuentas = cuentas;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _sumaPorcentajes {
    return _cuentas.where((c) => c.activa).fold(0.0, (sum, c) => sum + c.porcentaje);
  }

  void _abrirModalCuenta([BankAccountConfig? cuentaEditar]) {
    final bancoCtrl = TextEditingController(text: cuentaEditar?.banco ?? 'Bancolombia');
    final titularCtrl = TextEditingController(text: cuentaEditar?.titular ?? '');
    final numCtrl = TextEditingController(text: cuentaEditar?.numeroCuenta ?? '');
    final porcCtrl = TextEditingController(text: '${cuentaEditar?.porcentaje ?? 20}');
    String tipo = cuentaEditar?.tipo ?? 'ahorros';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(cuentaEditar != null ? 'Editar Cuenta de Dispersión' : 'Agregar Cuenta Bancaria', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: bancoCtrl, decoration: const InputDecoration(labelText: 'Entidad Bancaria *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: titularCtrl, decoration: const InputDecoration(labelText: 'Titular de la cuenta *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: numCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Número de cuenta *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: porcCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Porcentaje de dispersión (%) *', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
              onPressed: () {
                final porc = double.tryParse(porcCtrl.text) ?? 0;
                final nueva = BankAccountConfig(
                  id: cuentaEditar?.id ?? (_cuentas.isEmpty ? 1 : (_cuentas.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1)),
                  banco: bancoCtrl.text.trim(),
                  tipoCuenta: tipo,
                  numeroCuenta: numCtrl.text.trim(),
                  titular: titularCtrl.text.trim(),
                  concepto: 'Dispersión de fondos',
                  porcentaje: porc,
                  activa: cuentaEditar?.activa ?? true,
                );

                setState(() {
                  if (cuentaEditar != null) {
                    final idx = _cuentas.indexOf(cuentaEditar);
                    if (idx != -1) _cuentas[idx] = nueva;
                  } else {
                    _cuentas.add(nueva);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarConfiguracion() async {
    final validacion = PaymentConfigService.instance.validarPorcentajesDispersion(_cuentas);
    if (!validacion['valido']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validacion['mensaje']), backgroundColor: FashionColors.peligro),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await PaymentConfigService.instance.guardarConfiguracionPasarela(
        cuentasBancarias: _cuentas,
      );
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración de dispersión guardada exitosamente')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: FashionColors.peligro),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalConsolidado = _control?.recaudoTotalConsolidado ?? 0;
    final dispersion = PaymentConfigService.instance.calcularDispersionFondos(totalConsolidado, _cuentas);

    return AdminShellLayout(
      currentPath: '/admin/pagos',
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // CONTROL PARALELO DE INGRESOS
                Text('Control Paralelo de Recaudos', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _cardRecaudo('Wompi Online', CurrencyFormatter.formatearCOP(_control?.recaudoWompiOnline ?? 0), '${_control?.cantidadPedidosPagados ?? 0} pedidos', FashionColors.rosaCorporativo),
                    const SizedBox(width: 8),
                    _cardRecaudo('POS Mostrador', CurrencyFormatter.formatearCOP(_control?.recaudoPosMostrador ?? 0), '${_control?.cantidadVentasPos ?? 0} ventas', const Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    _cardRecaudo('Consolidado', CurrencyFormatter.formatearCOP(totalConsolidado), '${_control?.facturasEmitidas ?? 0} facturas', FashionColors.verdeExito),
                  ],
                ),

                const SizedBox(height: 24),

                // DISPERSIÓN DE FONDOS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dispersión en Cuentas Bancarias', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () => _abrirModalCuenta(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar Cuenta'),
                    ),
                  ],
                ),
                Text('Suma activa: ${_sumaPorcentajes.toStringAsFixed(1)}% (debe ser exactamente 100%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _sumaPorcentajes == 100 ? FashionColors.verdeExito : FashionColors.peligro)),
                const SizedBox(height: 10),

                ..._cuentas.map((c) {
                  final asignado = dispersion.where((d) => d.id == c.id).firstOrNull;
                  final montoDispersion = asignado?.montoAsignado ?? 0.0;
                  return Card(
                    elevation: 0.5,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: FashionColors.grisBorde)),
                    child: ListTile(
                      leading: const Icon(Icons.account_balance, color: FashionColors.pizarra),
                      title: Text('${c.banco} · ${c.titular}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Cuenta ${c.numeroCuenta} (${c.tipoCuenta}) · ${c.porcentaje}% activo\nAsignado: ${CurrencyFormatter.formatearCOP(montoDispersion)}', style: const TextStyle(fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _abrirModalCuenta(c)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: FashionColors.peligro),
                            onPressed: () => setState(() => _cuentas.remove(c)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _guardando ? null : _guardarConfiguracion,
                  child: _guardando ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Configuración de Dispersión', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }

  Widget _cardRecaudo(String titulo, String monto, String sub, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: col.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monto, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 13)),
            const SizedBox(height: 2),
            Text(titulo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(fontSize: 10, color: FashionColors.textoMuted)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. CLIENTES Y USUARIOS STAFF (VistaUsuariosYClientes.vue)
// ============================================================================

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Registrar Colaborador Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nombre completo *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo corporativo *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: telCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: rol,
                decoration: const InputDecoration(labelText: 'Rol asignado', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'empleado', child: Text('Empleado / Ventas POS')),
                  DropdownMenuItem(value: 'administrador', child: Text('Administrador General')),
                ],
                onChanged: (v) => setMState(() => rol = v ?? 'empleado'),
              ),
              const SizedBox(height: 10),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña temporal *', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                onPressed: () async {
                  if (nomCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                  try {
                    await SecurityService.instance.crearUsuario({
                      'nombre': nomCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'telefono': telCtrl.text.trim(),
                      'password': passCtrl.text,
                      'rol': rol,
                    });
                    _cargarTodo();
                    if (mounted) Navigator.pop(ctx);
                  } catch (_) {}
                },
                child: const Text('Crear Usuario'),
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
              labelColor: FashionColors.negroElegante,
              unselectedLabelColor: FashionColors.textoMuted,
              indicatorColor: FashionColors.rosaCorporativo,
              tabs: [
                const Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Clientes'),
                if (esAdmin) const Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Staff / Empleados'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Pestaña Clientes
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _clientes.length,
                        itemBuilder: (context, index) {
                          final c = _clientes[index];
                          return Card(
                            elevation: 0.5,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: FashionColors.rosaSuave, child: Icon(Icons.person, color: FashionColors.rosaOscuro)),
                              title: Text(c['nombre']?.toString() ?? 'Cliente', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${c['email'] ?? c['correo'] ?? ''} · Ciudad: ${c['ciudad'] ?? "N/A"}'),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Colaboradores (${_usuarios.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                                    onPressed: _abrirModalNuevoUsuario,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Nuevo Usuario'),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _usuarios.length,
                                itemBuilder: (context, index) {
                                  final u = _usuarios[index];
                                  final id = u['id_usuario'] ?? u['id'];
                                  final rol = (u['rol'] ?? u['roles']?[0]?['nombre'] ?? 'empleado').toString();
                                  final activo = u['activo'] == true || u['activo'] == 1;

                                  return Card(
                                    elevation: 0.5,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(u['nombre']?.toString() ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${u['email'] ?? ''} · Rol: ${rol.toUpperCase()}'),
                                      trailing: Switch(
                                        value: activo,
                                        activeColor: FashionColors.rosaCorporativo,
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

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  bool _cargando = true;
  List<Map<String, dynamic>> _auditorias = [];
  String _filtroModelo = '';

  @override
  void initState() {
    super.initState();
    _cargarAuditorias();
  }

  Future<void> _cargarAuditorias() async {
    setState(() => _cargando = true);
    try {
      final res = await SecurityService.instance.obtenerAuditorias(
        _filtroModelo.isNotEmpty ? {'modelo': _filtroModelo} : null,
      );
      if (mounted) {
        setState(() {
          _auditorias = res.lista;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelos = ['', 'Producto', 'Venta', 'Inventario', 'User'];

    return AdminShellLayout(
      currentPath: '/admin/seguridad/auditoria',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: modelos.map((m) {
                  final sel = _filtroModelo == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(m.isEmpty ? 'Todo el historial' : m, style: TextStyle(fontSize: 11, color: sel ? Colors.white : FashionColors.textoOscuro)),
                      selected: sel,
                      selectedColor: FashionColors.negroElegante,
                      onSelected: (_) {
                        setState(() => _filtroModelo = m);
                        _cargarAuditorias();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
                : _auditorias.isEmpty
                    ? const Center(child: Text('No hay registros de auditoría'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _auditorias.length,
                        itemBuilder: (context, index) {
                          final a = _auditorias[index];
                          final fecha = a['created_at']?.toString() ?? '';
                          final desc = AuditTextFormatter.describirAuditoria(a);
                          final dia = AuditTextFormatter.etiquetaDia(fecha);
                          final relativo = AuditTextFormatter.tiempoRelativo(fecha);

                          return Card(
                            elevation: 0.5,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.history, color: FashionColors.pizarra),
                              title: Text(desc.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('$dia · $relativo · Usuario: ${a['user']?['nombre'] ?? a['usuario'] ?? "Sistema"}', style: const TextStyle(fontSize: 11, color: FashionColors.textoMuted)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. CONFIGURACIÓN DE CUENTA STAFF (VistaEditarCuenta.vue)
// ============================================================================

class AdminAccountScreen extends ConsumerStatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  ConsumerState<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends ConsumerState<AdminAccountScreen> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _telCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();
  final TextEditingController _dirCtrl = TextEditingController();

  final TextEditingController _passActualCtrl = TextEditingController();
  final TextEditingController _passNuevaCtrl = TextEditingController();
  final TextEditingController _passConfirmCtrl = TextEditingController();

  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).usuario;
    if (u != null) {
      _nombreCtrl.text = u['nombre']?.toString() ?? '';
      _telCtrl.text = u['telefono']?.toString() ?? '';
      _ciudadCtrl.text = u['ciudad']?.toString() ?? '';
      _dirCtrl.text = u['direccion']?.toString() ?? '';
    }
  }

  Future<void> _subirFoto() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (f == null) return;

    try {
      final res = await UserService.instance.subirFotoPerfil(f.path, f.name);
      final foto = res['foto'] ?? res['url'];
      if (foto != null) {
        ref.read(authProvider.notifier).actualizarUsuario({'foto': foto});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
      }
    } catch (_) {}
  }

  Future<void> _guardarPerfil() async {
    setState(() => _cargando = true);
    try {
      final res = await UserService.instance.actualizarPerfil({
        'nombre': _nombreCtrl.text.trim(),
        'telefono': _telCtrl.text.trim(),
        'ciudad': _ciudadCtrl.text.trim(),
        'direccion': _dirCtrl.text.trim(),
      });
      ref.read(authProvider.notifier).actualizarUsuario(res);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos guardados exitosamente')));
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _actualizarPass() async {
    if (!passwordEsSegura(_passNuevaCtrl.text) || _passNuevaCtrl.text != _passConfirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña no cumple los requisitos o no coincide')));
      return;
    }

    try {
      await UserService.instance.actualizarContrasena(
        passwordActual: _passActualCtrl.text,
        password: _passNuevaCtrl.text,
        passwordConfirmation: _passConfirmCtrl.text,
      );
      _passActualCtrl.clear();
      _passNuevaCtrl.clear();
      _passConfirmCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña cambiada con éxito')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar contraseña: $e'), backgroundColor: FashionColors.peligro));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AdminShellLayout(
      currentPath: '/admin/cuenta',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: FashionColors.pizarra,
                  backgroundImage: (authState.fotoUsuario != null && authState.fotoUsuario!.isNotEmpty) ? NetworkImage(authState.fotoUsuario!) : null,
                  child: (authState.fotoUsuario == null || authState.fotoUsuario!.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: FashionColors.rosaCorporativo,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      onPressed: _subirFoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Datos personales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: FashionColors.grisBorde)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Información del Colaborador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _ciudadCtrl, decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _dirCtrl, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                  onPressed: _cargando ? null : _guardarPerfil,
                  child: const Text('Guardar Datos'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contraseña
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: FashionColors.grisBorde)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Seguridad de la Cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                TextField(controller: _passActualCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña actual', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _passNuevaCtrl, obscureText: true, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Nueva contraseña', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                PasswordRequirementsWidget(password: _passNuevaCtrl.text),
                const SizedBox(height: 10),
                TextField(controller: _passConfirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                  onPressed: _actualizarPass,
                  child: const Text('Actualizar Contraseña'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
