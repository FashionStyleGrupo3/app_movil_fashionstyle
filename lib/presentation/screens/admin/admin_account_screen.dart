// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/constants/payment_constants.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/audit_text_formatter.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/models/audit/audit_models.dart';
import 'package:fashion_style_mobile/data/models/payment/bank_account_config.dart';
import 'package:fashion_style_mobile/data/models/payment/parallel_payment_control.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_detail.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_model.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sales_summary.dart';
import 'package:fashion_style_mobile/data/services/payment_config_service.dart';
import 'package:fashion_style_mobile/data/services/pos_sale_service.dart';
import 'package:fashion_style_mobile/data/services/security_service.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_audit_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_payments_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_security_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/forgot_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/login_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/register_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/reset_password_screen.dart';
import 'package:fashion_style_mobile/presentation/screens/autenticacion/verify_email_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/auth_brand_banner.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/password_requirements_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
