// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String? correo;

  const VerifyEmailScreen({super.key, this.correo});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final TextEditingController _codigoCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;
  String? _exito;

  int _segundosRestantes = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarCuentaRegresiva();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarCuentaRegresiva() {
    _timer?.cancel();
    setState(() => _segundosRestantes = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _verificar() async {
    final codigo = _codigoCtrl.text.trim();
    final correo = widget.correo ?? ref.read(authProvider).correoUsuario;

    if (codigo.length != 6) {
      setState(() => _error = 'Ingresa el código numérico de 6 dígitos.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).verificarCorreo(
        correo: correo,
        codigo: codigo,
      );

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.obtenerMensajeError(
            e,
            'El código ingresado es incorrecto o ya ha expirado.',
          );
          _cargando = false;
        });
      }
    }
  }

  Future<void> _reenviar() async {
    final correo = widget.correo ?? ref.read(authProvider).correoUsuario;
    if (correo.isEmpty) return;

    try {
      await ref.read(authProvider.notifier).reenviarCodigo(correo);
      _iniciarCuentaRegresiva();
      if (mounted) {
        setState(() => _exito = 'Nuevo código enviado exitosamente a $correo');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = ApiClient.obtenerMensajeError(
          e,
          'No se pudo reenviar el código. Intenta de nuevo en unos momentos.',
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final correo = widget.correo ?? ref.read(authProvider).correoUsuario;

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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: FashionColors.rosaSuave, shape: BoxShape.circle),
                    child: const Icon(Icons.mark_email_read_outlined, size: 40, color: FashionColors.rosaOscuro),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verifica tu Correo',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: FashionColors.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hemos enviado un código de 6 dígitos a $correo. Ingrésalo para activar tu cuenta.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: FashionColors.textoMuted),
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

                  if (_exito != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.verdeExito.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_exito!, style: const TextStyle(color: FashionColors.verdeExito, fontSize: 13)),
                    ),

                  TextField(
                    controller: _codigoCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '000000',
                      counterText: '',
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
                      onPressed: _cargando ? null : _verificar,
                      child: _cargando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verificar código', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _segundosRestantes > 0 ? null : _reenviar,
                    child: Text(
                      _segundosRestantes > 0
                          ? 'Reenviar código en ${_segundosRestantes}s'
                          : '¿No recibiste el código? Reenviar',
                      style: TextStyle(
                        fontSize: 13,
                        color: _segundosRestantes > 0 ? FashionColors.textoMuted : FashionColors.rosaOscuro,
                      ),
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
// 4. VISTA RECUPERAR CONTRASEÑA (VistaRecuperarContrasena.vue)
// ============================================================================
