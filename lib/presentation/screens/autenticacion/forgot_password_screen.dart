// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    final email = _emailCtrl.text.trim();
    if (!validarCorreo(email)) {
      setState(() => _error = 'Ingresa un correo electrónico válido.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).solicitarRecuperacion(email);
      if (!mounted) return;
      context.go('/restablecer-contrasena?correo=${Uri.encodeComponent(email)}');
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FashionColors.grisBorde),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recuperar Contraseña',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: FashionColors.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa tu correo registrado y te enviaremos un código para restablecer tu contraseña.',
                    style: TextStyle(fontSize: 13, color: FashionColors.textoMuted),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.peligro.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.negroElegante,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _cargando ? null : _solicitar,
                      child: _cargando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Enviar código de recuperación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Volver a iniciar sesión', style: TextStyle(color: FashionColors.textoMuted)),
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
// 5. VISTA RESTABLECER CONTRASEÑA (VistaRestablecerContrasena.vue)
// ============================================================================
