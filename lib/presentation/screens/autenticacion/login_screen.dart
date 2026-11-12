// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla Editorial de Inicio de Sesión "Neo-Atelier Editorial Login".
///
/// Implementa un layout full-page de extremo a extremo:
/// - Hero superior (~38-40% viewport height) con fotografía de atelier, gradiente
///   obsidiana/terracotta multi-stop, botón glassmorphic "Volver a tienda",
///   badge "ATELIER ARCHIVE · 2026" y titular tipográfico en Space Grotesk.
/// - Hoja esculpida inferior con radio de 32px que solapa el hero, barra pill
///   de acento terracotta, campos de entrada con foco estilizado, botón primario
///   de alto contraste, divisor "O CONTINÚA CON", botón Google OAuth y enlaces de navegación.
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

  void _iniciarConGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Conectando de forma segura con Google Identity...',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: FashionColors.inkPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroHeight = (size.height * 0.38).clamp(240.0, 340.0);

    return Scaffold(
      backgroundColor: FashionColors.inkPrimary,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // 1. HERO SUPERIOR EDITORIAL (Fondo + Gradiente + Titulares)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight + 40, // Extiende para el solapamiento de 32px
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen o arte de respaldo
                  CachedNetworkImage(
                    imageUrl: ImageUrlResolver.resolve('img/login-modelo.jpg'),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildHeroFallback(),
                    errorWidget: (_, __, ___) => _buildHeroFallback(),
                  ),

                  // Gradiente obsidiana/terracotta multi-stop
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.50, 0.85, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.55),
                          FashionColors.inkPrimary.withValues(alpha: 0.90),
                          FashionColors.inkPrimary,
                        ],
                      ),
                    ),
                  ),

                  // Contenido de marca del Hero
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 52, // Espacio antes del solapamiento
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Titular principal Space Grotesk
                        Text(
                          'FashionStyle',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Moda que se ajusta a ti · Calidad y estilo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. HOJA ESCULPIDA INFERIOR (Formulario Solapado y Desplazable)
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: heroHeight),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: (size.height - heroHeight).clamp(0.0, double.infinity),
                      ),
                      decoration: const BoxDecoration(
                        color: FashionColors.surfaceCard,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 24,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pill Bar de acento Terracotta
                            Center(
                              child: Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: FashionColors.brandAccent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Título de la hoja
                            Text(
                              'Iniciar Sesión',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: FashionColors.inkPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ingresa con tus credenciales para continuar.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: FashionColors.inkSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Banner de error
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: FashionColors.statusDanger.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: FashionColors.statusDanger.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: FashionColors.statusDanger,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: FashionColors.statusDanger,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Campo: Correo Electrónico
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: FashionColors.inkPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: FashionColors.inkSecondary,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  size: 19,
                                  color: FashionColors.inkSecondary,
                                ),
                                filled: true,
                                fillColor: FashionColors.surfaceMuted,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: FashionColors.borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: FashionColors.borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: FashionColors.brandAccent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Campo: Contraseña
                            TextField(
                              controller: _passCtrl,
                              obscureText: _ocultarPass,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: FashionColors.inkPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: FashionColors.inkSecondary,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 19,
                                  color: FashionColors.inkSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _ocultarPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 19,
                                    color: FashionColors.inkSecondary,
                                  ),
                                  onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                                ),
                                filled: true,
                                fillColor: FashionColors.surfaceMuted,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: FashionColors.borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: FashionColors.borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: FashionColors.brandAccent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            // Olvidé mi contraseña
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => context.go('/recuperar-contrasena'),
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: FashionColors.brandAccent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Botón Primario: Ingresar (Alto contraste)
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FashionColors.inkPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _cargando ? null : _iniciarSesion,
                                child: _cargando
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Ingresar a mi Cuenta',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divisor "O CONTINÚA CON"
                            Row(
                              children: [
                                const Expanded(child: Divider(color: FashionColors.borderSubtle, height: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'O CONTINÚA CON',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: FashionColors.inkSecondary,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: FashionColors.borderSubtle, height: 1)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Botón Google OAuth Full-Width
                            SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: FashionColors.borderSubtle),
                                  backgroundColor: FashionColors.surfaceCard,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _iniciarConGoogle,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: FashionColors.borderSubtle),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'G',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: const Color(0xFF4285F4),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Continuar con Google',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                        color: FashionColors.inkPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Enlace al Registro
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: '¿Aún no tienes cuenta? ',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: FashionColors.inkSecondary,
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Regístrate aquí',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: FashionColors.brandAccent,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()..onTap = () => context.go('/registro'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. BOTÓN GLASSMORFICO "VOLVER A TIENDA" (Anclado en SafeArea)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Volver a tienda',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroFallback() {
    return Container(
      color: FashionColors.inkPrimary,
      child: const AtelierPatternBackground(
        colorFondo: FashionColors.inkPrimary,
        opacidadReticula: 0.12,
        child: SizedBox.expand(),
      ),
    );
  }
}
