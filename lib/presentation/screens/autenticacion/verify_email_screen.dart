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
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FashionColors.atelierJade.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined, size: 32, color: FashionColors.atelierJade),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Verifica tu Correo',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FashionColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hemos enviado un código de 6 dígitos a $correo. Ingrésalo para activar tu cuenta atelier.',
                    textAlign: TextAlign.center,
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

                  if (_exito != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.statusSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FashionColors.statusSuccess.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _exito!,
                        style: GoogleFonts.plusJakartaSans(color: FashionColors.statusSuccess, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),

                  TextField(
                    controller: _codigoCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: FashionColors.inkPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        letterSpacing: 8,
                        color: FashionColors.inkSecondary.withValues(alpha: 0.4),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: FashionColors.surfaceMuted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FashionColors.brandAccent, width: 1.5),
                      ),
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
                      onPressed: _cargando ? null : _verificar,
                      child: _cargando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Activar cuenta', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: _segundosRestantes == 0 ? _reenviar : null,
                      child: Text(
                        _segundosRestantes > 0
                            ? 'Reenviar código en ${_segundosRestantes}s'
                            : 'Reenviar nuevo código',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: _segundosRestantes > 0 ? FashionColors.inkSecondary : FashionColors.brandAccent,
                        ),
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
