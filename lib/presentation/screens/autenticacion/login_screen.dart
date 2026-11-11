// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          _error = e.toString().replaceFirst('Exception: ', '');
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FashionColors.grisBorde),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner visual de marca (espejo de DisenoAutenticacion.vue)
                  const AuthBrandBanner(height: 160),

                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar Sesión',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: FashionColors.textoOscuro,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Accede a tu cuenta para gestionar pedidos y favoritos.',
                          style: GoogleFonts.montserrat(fontSize: 13, color: FashionColors.textoMuted),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: FashionColors.peligro.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FashionColors.peligro.withValues(alpha: 0.3)),
                            ),
                            child: Text(_error!, style: const TextStyle(color: FashionColors.peligro, fontSize: 13)),
                          ),

                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _passCtrl,
                          obscureText: _ocultarPass,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_ocultarPass ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/recuperar-contrasena'),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: FashionColors.textoOscuro),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.negroElegante,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _cargando ? null : _iniciarSesion,
                            child: _cargando
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Ingresar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: '¿Aún no tienes cuenta? ',
                              style: GoogleFonts.montserrat(color: FashionColors.textoMuted, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Regístrate aquí',
                                  style: GoogleFonts.montserrat(color: FashionColors.textoOscuro, fontWeight: FontWeight.bold),
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

// ============================================================================
// 2. VISTA REGISTRO (VistaRegistro.vue)
// ============================================================================
