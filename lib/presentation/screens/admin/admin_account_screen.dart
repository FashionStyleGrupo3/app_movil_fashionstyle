// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible cambiar la contraseña. Verifica tu contraseña actual.')),
          backgroundColor: FashionColors.peligro,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AdminShellLayout(
      currentPath: '/admin/cuenta',
      child: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: FashionColors.inkPrimary,
                  backgroundImage: (authState.fotoUsuario != null && authState.fotoUsuario!.isNotEmpty) ? NetworkImage(authState.fotoUsuario!) : null,
                  child: (authState.fotoUsuario == null || authState.fotoUsuario!.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: FashionColors.brandAccent,
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: FashionColors.borderSubtle)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Información del Colaborador', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15, color: FashionColors.inkPrimary)),
                const SizedBox(height: 12),
                TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _ciudadCtrl, decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _dirCtrl, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.brandAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _cargando ? null : _guardarPerfil,
                  child: Text('Guardar Datos', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contraseña
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: FashionColors.borderSubtle)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Seguridad de la Cuenta', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15, color: FashionColors.inkPrimary)),
                const SizedBox(height: 12),
                TextField(controller: _passActualCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña actual', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _passNuevaCtrl, obscureText: true, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Nueva contraseña', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                PasswordRequirementsWidget(password: _passNuevaCtrl.text),
                const SizedBox(height: 10),
                TextField(controller: _passConfirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.brandAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _actualizarPass,
                  child: Text('Actualizar Contraseña', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
