// @source-mirror: src/views/autenticacion/VistaInicioSesion.vue, VistaRegistro.vue, VistaVerificarCorreo.vue, VistaRecuperarContrasena.vue, VistaRestablecerContrasena.vue, src/components/autenticacion/RequisitosPassword.vue
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/services/city_validation_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/auth/auth_brand_banner.dart';
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
          _error = ApiClient.obtenerMensajeError(
            e,
            'No se pudo completar el registro. Verifica los datos ingresados.',
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              clipBehavior: Clip.antiAlias,
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
                  const AuthBrandBanner(height: 140),

                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Crear Cuenta',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Únete a Fashion Style y disfruta de confección atelier y lanzamientos exclusivos.',
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
                              style: GoogleFonts.plusJakartaSans(color: FashionColors.statusDanger, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),

                        TextField(
                          controller: _nombreCtrl,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                          decoration: InputDecoration(
                            labelText: 'Nombre completo *',
                            labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                            filled: true,
                            fillColor: FashionColors.surfaceMuted,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _correoCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico *',
                            labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                            filled: true,
                            fillColor: FashionColors.surfaceMuted,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _telefonoCtrl,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                          decoration: InputDecoration(
                            labelText: 'Celular (10 dígitos) *',
                            hintText: 'Ej. 3001234567',
                            labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                            filled: true,
                            fillColor: FashionColors.surfaceMuted,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                              decoration: InputDecoration(
                                labelText: 'Ciudad de residencia *',
                                hintText: 'Ej. Medellín, Cali...',
                                labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                                filled: true,
                                fillColor: FashionColors.surfaceMuted,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              onChanged: (val) => _ciudadCtrl.text = val,
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _direccionCtrl,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                          decoration: InputDecoration(
                            labelText: 'Dirección habitual *',
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
                            labelText: 'Contraseña *',
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

                        // Requisitos de contraseña atelier
                        PasswordRequirementsWidget(password: _passCtrl.text),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _passConfirmCtrl,
                          obscureText: _ocultarPass,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FashionColors.inkPrimary),
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña *',
                            labelStyle: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13.5),
                            filled: true,
                            fillColor: FashionColors.surfaceMuted,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Checkbox(
                              value: _aceptaTerminos,
                              activeColor: FashionColors.brandAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _aceptaTerminos = val ?? false),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'He leído y acepto los ',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkPrimary),
                                  children: [
                                    TextSpan(
                                      text: 'Términos y Condiciones',
                                      style: GoogleFonts.plusJakartaSans(color: FashionColors.brandAccent, fontWeight: FontWeight.w700),
                                      recognizer: TapGestureRecognizer()..onTap = () => context.go('/terminos'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.brandAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: _cargando ? null : _registrar,
                            child: _cargando
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Crear mi cuenta', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: '¿Ya tienes una cuenta? ',
                              style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Inicia sesión',
                                  style: GoogleFonts.plusJakartaSans(color: FashionColors.brandAccent, fontWeight: FontWeight.w700),
                                  recognizer: TapGestureRecognizer()..onTap = () => context.go('/login'),
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
