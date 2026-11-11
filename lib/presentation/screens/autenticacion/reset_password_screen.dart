// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/password_requirements_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? correo;
  final String? token;

  const ResetPasswordScreen({
    super.key,
    this.correo,
    this.token,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _passConfirmCtrl = TextEditingController();

  bool _ocultarPass = true;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.correo != null) _emailCtrl.text = widget.correo!;
    if (widget.token != null) _codigoCtrl.text = widget.token!;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codigoCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    final email = _emailCtrl.text.trim();
    final codigo = _codigoCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _passConfirmCtrl.text;

    if (!validarCorreo(email) || codigo.isEmpty) {
      setState(() => _error = 'Por favor verifica el correo y el código de recuperación.');
      return;
    }

    if (!passwordEsSegura(pass)) {
      setState(() => _error = 'La nueva contraseña debe cumplir con los requisitos de seguridad.');
      return;
    }

    if (pass != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).restablecerContrasena({
        'email': email,
        'token': codigo,
        'password': pass,
        'password_confirmation': confirm,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña restablecida exitosamente. Ya puedes iniciar sesión.')),
      );
      context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.obtenerMensajeError(
            e,
            'No fue posible restablecer la contraseña. Verifica el código e intenta de nuevo.',
          );
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicShellLayout(
      currentIndex: 3,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96), // Clearance para Floating Pill Dock
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: FashionColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: FashionColors.borderSubtle),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nueva Contraseña',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FashionColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ingresa el código que recibiste y define tu nueva clave.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkSecondary),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.statusDanger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FashionColors.statusDanger.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: GoogleFonts.plusJakartaSans(color: FashionColors.statusDanger, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                      filled: true,
                      fillColor: FashionColors.surfaceMuted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _codigoCtrl,
                    style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2, color: FashionColors.inkPrimary),
                    decoration: InputDecoration(
                      labelText: 'Código de 6 dígitos',
                      hintText: '123456',
                      labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                      filled: true,
                      fillColor: FashionColors.surfaceMuted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passCtrl,
                    obscureText: _ocultarPass,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                      suffixIcon: IconButton(
                        icon: Icon(_ocultarPass ? Icons.visibility_off : Icons.visibility, size: 20, color: FashionColors.inkSecondary),
                        onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                      ),
                      filled: true,
                      fillColor: FashionColors.surfaceMuted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  PasswordRequirementsWidget(password: _passCtrl.text),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passConfirmCtrl,
                    obscureText: _ocultarPass,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                    decoration: InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                      filled: true,
                      fillColor: FashionColors.surfaceMuted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.brandAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _cargando ? null : _restablecer,
                      child: _cargando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Restablecer Contraseña', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Cancelar y volver',
                      style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
