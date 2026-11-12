// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:image_picker/image_picker.dart';

class SeccionMisDatos extends ConsumerStatefulWidget {
  const SeccionMisDatos({super.key});

  @override
  ConsumerState<SeccionMisDatos> createState() => _SeccionMisDatosState();
}

class _SeccionMisDatosState extends ConsumerState<SeccionMisDatos> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();

  final TextEditingController _nuevoCorreoCtrl = TextEditingController();
  final TextEditingController _codigoCorreoCtrl = TextEditingController();
  bool _esperandoCodigoCorreo = false;

  final TextEditingController _passActualCtrl = TextEditingController();
  final TextEditingController _passNuevaCtrl = TextEditingController();
  final TextEditingController _passConfirmCtrl = TextEditingController();

  bool _cargandoPerfil = false;
  bool _cargandoCorreo = false;
  bool _cargandoPass = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).usuario;
    if (u != null) {
      _nombreCtrl.text = u['nombre']?.toString() ?? '';
      _telefonoCtrl.text = u['telefono']?.toString() ?? '';
      _ciudadCtrl.text = u['ciudad']?.toString() ?? '';
      _direccionCtrl.text = u['direccion']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _ciudadCtrl.dispose();
    _direccionCtrl.dispose();
    _nuevoCorreoCtrl.dispose();
    _codigoCorreoCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  bool _subiendoFoto = false;

  Future<ImageSource?> _seleccionarOrigenImagen() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: FashionColors.surfaceCard,
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
                'Seleccionar Foto de Perfil',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
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
                title: Text('Tomar foto con la cámara', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('Abre la cámara para una nueva captura', style: GoogleFonts.inter(fontSize: 11.5, color: FashionColors.inkSecondary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FashionColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: FashionColors.inkPrimary),
                ),
                title: Text('Elegir de la galería', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('Selecciona una imagen guardada en tu dispositivo', style: GoogleFonts.inter(fontSize: 11.5, color: FashionColors.inkSecondary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _subirNuevaFoto() async {
    final origen = await _seleccionarOrigenImagen();
    if (origen == null) return;
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: origen, maxWidth: 800, imageQuality: 85);
    if (foto == null) return;

    setState(() => _subiendoFoto = true);
    try {
      final res = await UserService.instance.subirFotoPerfil(foto.path, foto.name);
      final fotoUrl = res['foto_perfil'] ?? res['foto'] ?? res['url'] ?? res['foto_url'];
      if (fotoUrl != null) {
        await ref.read(authProvider.notifier).actualizarUsuario({
          'foto_perfil': fotoUrl,
          'foto': fotoUrl,
          ...res,
        });
      }
      await ref.read(authProvider.notifier).refrescarSesion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada correctamente'),
            backgroundColor: FashionColors.verdeExito,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo subir la imagen de perfil.')),
            backgroundColor: FashionColors.peligro,
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
      await UserService.instance.quitarFotoPerfil();
      await ref.read(authProvider.notifier).actualizarUsuario({
        'foto_perfil': null,
        'foto': null,
      });
      await ref.read(authProvider.notifier).refrescarSesion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil eliminada'),
            backgroundColor: FashionColors.verdeExito,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible quitar la foto de perfil.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _guardarPerfil() async {
    setState(() => _cargandoPerfil = true);
    final datos = {
      'nombre': filtrarCampo(_nombreCtrl.text, 'persona', 100).trim(),
      'telefono': filtrarCampo(_telefonoCtrl.text, 'telefono', 20).trim(),
      'ciudad': filtrarCampo(_ciudadCtrl.text, 'persona', 80).trim(),
      'direccion': filtrarCampo(_direccionCtrl.text, 'direccion', 180).trim(),
    };

    try {
      final actualizado = await UserService.instance.actualizarPerfil(datos);
      ref.read(authProvider.notifier).actualizarUsuario(actualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos personales guardados exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible actualizar tus datos personales.')),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoPerfil = false);
    }
  }

  Future<void> _solicitarCambioCorreo() async {
    final correo = _nuevoCorreoCtrl.text.trim();
    if (!validarCorreo(correo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo electrónico válido'), backgroundColor: FashionColors.statusDanger),
      );
      return;
    }

    setState(() => _cargandoCorreo = true);
    try {
      await UserService.instance.solicitarCambioCorreo(correo);
      setState(() => _esperandoCodigoCorreo = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Código de confirmación enviado a $correo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo solicitar el cambio de correo.')),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoCorreo = false);
    }
  }

  Future<void> _confirmarCambioCorreo() async {
    final codigo = _codigoCorreoCtrl.text.trim();
    if (codigo.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código numérico de 6 dígitos'), backgroundColor: FashionColors.statusDanger),
      );
      return;
    }

    setState(() => _cargandoCorreo = true);
    try {
      final res = await UserService.instance.confirmarCambioCorreo(codigo);
      await ref.read(authProvider.notifier).guardarSesion(res);
      setState(() {
        _esperandoCodigoCorreo = false;
        _nuevoCorreoCtrl.clear();
        _codigoCorreoCtrl.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo electrónico actualizado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'El código ingresado es incorrecto o ha expirado.')),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoCorreo = false);
    }
  }

  Future<void> _actualizarPassword() async {
    final actual = _passActualCtrl.text;
    final nueva = _passNuevaCtrl.text;
    final confirm = _passConfirmCtrl.text;

    if (!passwordEsSegura(nueva)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nueva contraseña no cumple con los requisitos de seguridad'), backgroundColor: FashionColors.statusDanger),
      );
      return;
    }

    if (nueva != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: FashionColors.statusDanger),
      );
      return;
    }

    setState(() => _cargandoPass = true);
    try {
      await UserService.instance.actualizarContrasena(
        passwordActual: actual,
        password: nueva,
        passwordConfirmation: confirm,
      );
      _passActualCtrl.clear();
      _passNuevaCtrl.clear();
      _passConfirmCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible actualizar la contraseña. Revisa la contraseña actual.')),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoPass = false);
    }
  }

  Widget _avatarFallback(AuthState authState) {
    final inicial = (authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0] : 'U').toUpperCase();
    return Center(
      child: Text(
        inicial,
        style: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: FashionColors.inkPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // Clearance para Floating Pill Dock
      children: [
        // GESTIÓN Y VISOR DE FOTO DE PERFIL
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FashionColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FashionColors.borderSubtle),
          ),
          child: Column(
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FashionColors.surfaceMuted,
                        border: Border.all(color: FashionColors.borderSubtle, width: 2),
                      ),
                      child: ClipOval(
                        child: _subiendoFoto
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: FashionColors.inkPrimary),
                                ),
                              )
                            : (authState.fotoUsuario != null && authState.fotoUsuario!.trim().isNotEmpty)
                                ? Image.network(
                                    ImageUrlResolver.resolve(authState.fotoUsuario!),
                                    key: ValueKey(authState.fotoUsuario),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _avatarFallback(authState),
                                  )
                                : _avatarFallback(authState),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: FashionColors.inkPrimary,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _subiendoFoto ? null : _subirNuevaFoto,
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario : 'Usuario FashionStyle',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                authState.correoUsuario,
                style: GoogleFonts.inter(fontSize: 12.5, color: FashionColors.inkSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: FashionColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FashionColors.borderSubtle),
                ),
                child: Text(
                  authState.esAdmin
                      ? 'Administrador General'
                      : (authState.esEmpleado ? 'Personal Operativo Staff' : 'Cliente Registrado'),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.inkPrimary),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FashionColors.inkPrimary,
                      side: const BorderSide(color: FashionColors.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: _subiendoFoto ? null : _subirNuevaFoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 16),
                    label: Text(
                      authState.fotoUsuario != null && authState.fotoUsuario!.isNotEmpty ? 'Cambiar foto' : 'Subir foto',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                  ),
                  if (authState.fotoUsuario != null && authState.fotoUsuario!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: FashionColors.statusDanger,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: _subiendoFoto ? null : _quitarFoto,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text('Quitar foto', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // DATOS PERSONALES
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FashionColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FashionColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información Personal',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nombreCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                  filled: true,
                  fillColor: FashionColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                  filled: true,
                  fillColor: FashionColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ciudadCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Ciudad',
                  labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                  filled: true,
                  fillColor: FashionColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _direccionCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Dirección habitual',
                  labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                  filled: true,
                  fillColor: FashionColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.brandAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _cargandoPerfil ? null : _guardarPerfil,
                  child: _cargandoPerfil
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Guardar cambios de perfil', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CAMBIO DE CORREO (2 PASOS)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FashionColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FashionColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cambio de Correo Electrónico',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
              ),
              const SizedBox(height: 14),
              if (!_esperandoCodigoCorreo) ...[
                TextField(
                  controller: _nuevoCorreoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nuevo correo electrónico',
                    labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                    filled: true,
                    fillColor: FashionColors.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.inkPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _cargandoCorreo ? null : _solicitarCambioCorreo,
                  child: _cargandoCorreo
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Solicitar código de cambio', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5)),
                ),
              ] else ...[
                TextField(
                  controller: _codigoCorreoCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 4),
                  decoration: InputDecoration(
                    labelText: 'Código de 6 dígitos recibido',
                    counterText: '',
                    filled: true,
                    fillColor: FashionColors.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.statusSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _cargandoCorreo ? null : _confirmarCambioCorreo,
                      child: const Text('Confirmar nuevo correo'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _esperandoCodigoCorreo = false),
                      child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CAMBIO DE CONTRASEÑA
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FashionColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FashionColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seguridad y Contraseña',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passActualCtrl,
                obscureText: true,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                  filled: true,
                  fillColor: FashionColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passNuevaCtrl,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                  filled: true,
                  fillColor: FashionColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passConfirmCtrl,
                obscureText: true,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                  filled: true,
                  fillColor: FashionColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.brandAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _cargandoPass ? null : _actualizarPassword,
                  child: _cargandoPass
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Actualizar contraseña', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
