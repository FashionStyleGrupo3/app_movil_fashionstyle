// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/validators/garment_and_field_validators.dart';
import '../../../core/validators/password_validator.dart';
import '../../../data/services/favorites_and_city_service.dart';
import '../../layouts/public_shell_layout.dart';
import '../../providers/auth_provider.dart';

// ============================================================================
// WIDGET DE REQUISITOS DE CONTRASEÑA EN TIEMPO REAL
// ============================================================================

class PasswordRequirementsWidget extends StatelessWidget {
  final String password;

  const PasswordRequirementsWidget({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FashionColors.fondoClaro,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FashionColors.grisBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requisitos de seguridad:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FashionColors.textoOscuro),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 4.8,
            children: requisitosPassword.map((req) {
              final ok = req.cumple(password);
              return Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 14,
                    color: ok ? FashionColors.verdeExito : FashionColors.textoMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      req.texto,
                      style: TextStyle(
                        fontSize: 11,
                        color: ok ? FashionColors.verdeExito : FashionColors.textoMuted,
                        fontWeight: ok ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. VISTA INICIO DE SESIÓN (VistaInicioSesion.vue)
// ============================================================================

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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FashionColors.grisBorde),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: FashionColors.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Accede a tu cuenta para gestionar pedidos y favoritos.',
                    style: TextStyle(fontSize: 13, color: FashionColors.textoMuted),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.peligro.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FashionColors.peligro.withOpacity(0.3)),
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
                      child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 12, color: FashionColors.rosaOscuro)),
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
                          : const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: '¿Aún no tienes cuenta? ',
                        style: const TextStyle(color: FashionColors.textoMuted, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Regístrate aquí',
                            style: const TextStyle(color: FashionColors.rosaOscuro, fontWeight: FontWeight.bold),
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
        ),
      ),
    );
  }
}

// ============================================================================
// 2. VISTA REGISTRO (VistaRegistro.vue)
// ============================================================================

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _passConfirmCtrl = TextEditingController();

  bool _ocultarPass = true;
  bool _aceptaTerminos = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _ciudadCtrl.dispose();
    _direccionCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final nombre = _nombreCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();
    final ciudad = _ciudadCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _passConfirmCtrl.text;

    if (nombre.isEmpty || correo.isEmpty || telefono.isEmpty || ciudad.isEmpty || direccion.isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos del formulario.');
      return;
    }

    if (!validarCorreo(correo)) {
      setState(() => _error = 'Ingresa un correo electrónico con formato válido.');
      return;
    }

    if (!RegExp(r'^3\d{9}$').hasMatch(telefono)) {
      setState(() => _error = 'El teléfono debe ser un celular colombiano válido de 10 dígitos (empieza por 3).');
      return;
    }

    if (direccion.length < 5) {
      setState(() => _error = 'La dirección debe tener al menos 5 caracteres.');
      return;
    }

    if (!passwordEsSegura(pass)) {
      setState(() => _error = 'La contraseña debe cumplir con todos los requisitos de seguridad.');
      return;
    }

    if (pass != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    if (!_aceptaTerminos) {
      setState(() => _error = 'Debes aceptar los términos y condiciones para crear tu cuenta.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).registrar({
        'nombre': nombre,
        'email': correo,
        'telefono': telefono,
        'ciudad': ciudad,
        'departamento': ciudad,
        'direccion': direccion,
        'password': pass,
        'password_confirmation': confirm,
        'acepta_terminos': true,
      });

      if (!mounted) return;
      context.go('/verificar-correo?correo=${Uri.encodeComponent(correo)}');
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FashionColors.grisBorde),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: FashionColors.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Únete a Fashion Style y disfruta de promociones exclusivas.',
                    style: TextStyle(fontSize: 13, color: FashionColors.textoMuted),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.peligro.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FashionColors.peligro.withOpacity(0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: FashionColors.peligro, fontSize: 13)),
                    ),

                  TextField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre completo *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Celular (10 dígitos) *',
                      hintText: 'Ej. 3001234567',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) async {
                      if (textEditingValue.text.length < 2) return const [];
                      return await CityValidationService.instance.buscarCiudades(textEditingValue.text);
                    },
                    onSelected: (seleccion) => _ciudadCtrl.text = seleccion,
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad de residencia *',
                          hintText: 'Ej. Medellín, Cali...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => _ciudadCtrl.text = val,
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _direccionCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección habitual *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passCtrl,
                    obscureText: _ocultarPass,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Contraseña *',
                      suffixIcon: IconButton(
                        icon: Icon(_ocultarPass ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Requisitos de contraseña
                  PasswordRequirementsWidget(password: _passCtrl.text),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passConfirmCtrl,
                    obscureText: _ocultarPass,
                    decoration: const InputDecoration(labelText: 'Confirmar contraseña *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Checkbox(
                        value: _aceptaTerminos,
                        activeColor: FashionColors.negroElegante,
                        onChanged: (val) => setState(() => _aceptaTerminos = val ?? false),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'He leído y acepto los ',
                            style: const TextStyle(fontSize: 12, color: FashionColors.textoOscuro),
                            children: [
                              TextSpan(
                                text: 'Términos y Condiciones',
                                style: const TextStyle(color: FashionColors.rosaOscuro, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()..onTap = () => context.go('/terminos'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.negroElegante,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _cargando ? null : _registrar,
                      child: _cargando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Crear mi cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: '¿Ya tienes una cuenta? ',
                        style: const TextStyle(color: FashionColors.textoMuted, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Inicia sesión',
                            style: const TextStyle(color: FashionColors.rosaOscuro, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = () => context.go('/login'),
                          ),
                        ],
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
// 3. VISTA VERIFICAR CORREO (VistaVerificarCorreo.vue)
// ============================================================================

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
          _error = e.toString().replaceFirst('Exception: ', '');
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
        setState(() => _error = 'No se pudo reenviar el código: $e');
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
                  const Text(
                    'Verifica tu Correo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
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
                        color: FashionColors.peligro.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: const TextStyle(color: FashionColors.peligro, fontSize: 13)),
                    ),

                  if (_exito != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.verdeExito.withOpacity(0.1),
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
                  const Text(
                    'Recuperar Contraseña',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
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
                        color: FashionColors.peligro.withOpacity(0.1),
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FashionColors.grisBorde),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nueva Contraseña',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: FashionColors.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ingresa el código que recibiste y define tu nueva clave.',
                    style: TextStyle(fontSize: 13, color: FashionColors.textoMuted),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.peligro.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: const TextStyle(color: FashionColors.peligro, fontSize: 13)),
                    ),

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _codigoCtrl,
                    decoration: const InputDecoration(labelText: 'Código de recuperación *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passCtrl,
                    obscureText: _ocultarPass,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña *',
                      suffixIcon: IconButton(
                        icon: Icon(_ocultarPass ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  PasswordRequirementsWidget(password: _passCtrl.text),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passConfirmCtrl,
                    obscureText: _ocultarPass,
                    decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña *', border: OutlineInputBorder()),
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
                      onPressed: _cargando ? null : _restablecer,
                      child: _cargando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Restablecer contraseña', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
