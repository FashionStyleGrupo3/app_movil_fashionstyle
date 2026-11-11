// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/auth_brand_banner.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redir;

  const LoginScreen({super.key, this.redir});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _ocultarPass = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Por favor ingresa tu correo y contraseña.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final res = await ref.read(authProvider.notifier).iniciarSesion({
        'email': email,
        'password': pass,
      });

      if (!mounted) return;

      if (res['codigo'] == 'email_no_verificado') {
        context.go('/verificar-correo?correo=${Uri.encodeComponent(email)}');
        return;
      }

      final destino = widget.redir != null && widget.redir!.isNotEmpty ? widget.redir! : '/';
      context.go(destino);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.obtenerMensajeError(
            e,
            'No se pudo iniciar sesión. Verifica tu correo y contraseña.',
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
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: FashionColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: FashionColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner visual de marca Nocturnal Atelier Header
                  const AuthBrandBanner(height: 160),

                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar Sesión',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Accede a tu cuenta para gestionar pedidos y favoritos.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: FashionColors.inkSecondary,
                          ),
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
                              style: GoogleFonts.plusJakartaSans(
                                color: FashionColors.statusDanger,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: FashionColors.inkSecondary),
                            filled: true,
                            fillColor: FashionColors.surfaceMuted,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FashionColors.brandAccent, width: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _passCtrl,
                          obscureText: _ocultarPass,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: FashionColors.inkSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(_ocultarPass ? Icons.visibility_off : Icons.visibility, size: 20, color: FashionColors.inkSecondary),
                              onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                            ),
                            filled: true,
                            fillColor: FashionColors.surfaceMuted,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FashionColors.brandAccent, width: 1.2),
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/recuperar-contrasena'),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: FashionColors.brandAccent,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.brandAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: _cargando ? null : _iniciarSesion,
                            child: _cargando
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Ingresar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(color: FashionColors.borderSubtle),
                        const SizedBox(height: 16),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: '¿Aún no tienes cuenta? ',
                              style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Regístrate aquí',
                                  style: GoogleFonts.plusJakartaSans(color: FashionColors.brandAccent, fontWeight: FontWeight.w700),
                                  recognizer: TapGestureRecognizer()..onTap = () => context.go('/registro'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
