// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';

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

  InputDecoration _decoracionInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
      filled: true,
      fillColor: FashionColors.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FashionColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FashionColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: FashionColors.inkPrimary, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96), // Clearance para dock inferior
      children: [
        // 1. INFORMACIÓN PERSONAL (INTEGRADA DIRECTAMENTE EN EL LIENZO)
        Text(
          'Información Personal',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nombreCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
          decoration: _decoracionInput('Nombre completo'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _telefonoCtrl,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
          decoration: _decoracionInput('Teléfono'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ciudadCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
          decoration: _decoracionInput('Ciudad'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _direccionCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
          decoration: _decoracionInput('Dirección habitual'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FashionColors.inkPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _cargandoPerfil ? null : _guardarPerfil,
            child: _cargandoPerfil
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Guardar cambios de perfil', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(color: FashionColors.borderSubtle, height: 1),
        ),

        // 2. CAMBIO DE CORREO ELECTRÓNICO (INTEGRADO EN EL LIENZO)
        Text(
          'Cambio de Correo Electrónico',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
        ),
        const SizedBox(height: 12),
        if (!_esperandoCodigoCorreo) ...[
          TextField(
            controller: _nuevoCorreoCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
            decoration: _decoracionInput('Nuevo correo electrónico'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: FashionColors.inkPrimary,
                side: const BorderSide(color: FashionColors.borderSubtle),
                backgroundColor: FashionColors.surfaceMuted,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _cargandoCorreo ? null : _solicitarCambioCorreo,
              child: _cargandoCorreo
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: FashionColors.inkPrimary))
                  : Text('Solicitar código de confirmación', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ] else ...[
          TextField(
            controller: _codigoCorreoCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 4),
            decoration: _decoracionInput('Código de 6 dígitos recibido').copyWith(counterText: ''),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.statusSuccess,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _cargandoCorreo ? null : _confirmarCambioCorreo,
                  child: const Text('Confirmar nuevo correo'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _esperandoCodigoCorreo = false),
                child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary)),
              ),
            ],
          ),
        ],

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(color: FashionColors.borderSubtle, height: 1),
        ),

        // 3. SEGURIDAD Y CONTRASEÑA (INTEGRADO EN EL LIENZO)
        Text(
          'Seguridad y Contraseña',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passActualCtrl,
          obscureText: true,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
          decoration: _decoracionInput('Contraseña actual'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passNuevaCtrl,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
          decoration: _decoracionInput('Nueva contraseña'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passConfirmCtrl,
          obscureText: true,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
          decoration: _decoracionInput('Confirmar nueva contraseña'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FashionColors.inkPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _cargandoPass ? null : _actualizarPassword,
            child: _cargandoPass
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Actualizar contraseña', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(color: FashionColors.borderSubtle, height: 1),
        ),

        // 4. CERRAR SESIÓN
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: FashionColors.inkPrimary,
              side: const BorderSide(color: FashionColors.borderSubtle, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: FashionColors.surfaceMuted,
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'Cerrar Sesión',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: FashionColors.canvasBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    'Cerrar Sesión',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    '¿Deseas cerrar tu sesión actual de FashionStyle?',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.inkPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );

              if (confirmar == true && mounted) {
                ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
                await ref.read(authProvider.notifier).cerrarSesion();
                if (mounted) context.go('/login');
              }
            },
          ),
        ),

        const SizedBox(height: 14),

        // 5. ZONA DE PELIGRO: ELIMINAR MI CUENTA
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FashionColors.statusDanger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FashionColors.statusDanger.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: FashionColors.statusDanger, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Zona de Peligro',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: FashionColors.statusDanger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Al solicitar la eliminación de tu cuenta, se cerrará tu sesión y se procesará la baja según los Términos y Condiciones.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: FashionColors.inkSecondary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: FashionColors.statusDanger,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: FashionColors.statusDanger.withValues(alpha: 0.25)),
                    ),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: Text(
                    'Eliminar mi cuenta',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final esAdmin = ref.read(authProvider).esAdmin;
                    if (esAdmin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No puedes eliminar tu propia cuenta de administrador'),
                          backgroundColor: FashionColors.statusDanger,
                        ),
                      );
                      return;
                    }

                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: FashionColors.canvasBackground,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            const Icon(Icons.warning_rounded, color: FashionColors.statusDanger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '¿Eliminar tu cuenta?',
                                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Esta acción desactivará tu cuenta de FashionStyle y cerrará inmediatamente tu sesión en este dispositivo.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.statusDanger,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sí, eliminar cuenta'),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true && mounted) {
                      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
                      await ref.read(authProvider.notifier).cerrarSesion();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tu sesión se ha cerrado y tu solicitud fue enviada.'),
                            duration: Duration(milliseconds: 2000),
                          ),
                        );
                        context.go('/');
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
