// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/services/city_validation_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/password_requirements_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crear Cuenta',
                    style: GoogleFonts.poppins(
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
                        color: FashionColors.peligro.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FashionColors.peligro.withValues(alpha: 0.3)),
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
