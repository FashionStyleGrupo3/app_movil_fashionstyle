// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';

class SeccionMisDatos extends ConsumerStatefulWidget {
  const SeccionMisDatos({super.key});

  @override
  ConsumerState<SeccionMisDatos> createState() => _SeccionMisDatosState();
}

class _SeccionMisDatosState extends ConsumerState<SeccionMisDatos> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();

  final TextEditingController _nuevoCorreoCtrl = TextEditingController();
  final TextEditingController _codigoCorreoCtrl = TextEditingController();
  bool _esperandoCodigoCorreo = false;

  final TextEditingController _passActualCtrl = TextEditingController();
  final TextEditingController _passNuevaCtrl = TextEditingController();
  final TextEditingController _passConfirmCtrl = TextEditingController();

  bool _cargandoPerfil = false;
  bool _cargandoCorreo = false;
  bool _cargandoPass = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).usuario;
    if (u != null) {
      _nombreCtrl.text = u['nombre']?.toString() ?? '';
      _telefonoCtrl.text = u['telefono']?.toString() ?? '';
      _ciudadCtrl.text = u['ciudad']?.toString() ?? '';
      _direccionCtrl.text = u['direccion']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _ciudadCtrl.dispose();
    _direccionCtrl.dispose();
    _nuevoCorreoCtrl.dispose();
    _codigoCorreoCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _subirNuevaFoto() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (foto == null) return;

    try {
      final res = await UserService.instance.subirFotoPerfil(foto.path, foto.name);
      final fotoUrl = res['foto'] ?? res['url'] ?? res['foto_url'];
      if (fotoUrl != null) {
        ref.read(authProvider.notifier).actualizarUsuario({'foto': fotoUrl});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada correctamente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo subir la imagen de perfil.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    }
  }

  Future<void> _quitarFoto() async {
    try {
      await UserService.instance.quitarFotoPerfil();
      ref.read(authProvider.notifier).actualizarUsuario({'foto': null});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible quitar la foto de perfil.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    }
  }

  Future<void> _guardarPerfil() async {
    setState(() => _cargandoPerfil = true);
    final datos = {
      'nombre': filtrarCampo(_nombreCtrl.text, 'persona', 100).trim(),
      'telefono': filtrarCampo(_telefonoCtrl.text, 'telefono', 20).trim(),
      'ciudad': filtrarCampo(_ciudadCtrl.text, 'persona', 80).trim(),
      'direccion': filtrarCampo(_direccionCtrl.text, 'direccion', 180).trim(),
    };

    try {
      final actualizado = await UserService.instance.actualizarPerfil(datos);
      ref.read(authProvider.notifier).actualizarUsuario(actualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos personales guardados exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible actualizar tus datos personales.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoPerfil = false);
    }
  }

  Future<void> _solicitarCambioCorreo() async {
    final correo = _nuevoCorreoCtrl.text.trim();
    if (!validarCorreo(correo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo electrónico válido'), backgroundColor: FashionColors.peligro),
      );
      return;
    }

    setState(() => _cargandoCorreo = true);
    try {
      await UserService.instance.solicitarCambioCorreo(correo);
      setState(() => _esperandoCodigoCorreo = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Código de confirmación enviado a $correo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo solicitar el cambio de correo.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoCorreo = false);
    }
  }

  Future<void> _confirmarCambioCorreo() async {
    final codigo = _codigoCorreoCtrl.text.trim();
    if (codigo.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código numérico de 6 dígitos'), backgroundColor: FashionColors.peligro),
      );
      return;
    }

    setState(() => _cargandoCorreo = true);
    try {
      final res = await UserService.instance.confirmarCambioCorreo(codigo);
      await ref.read(authProvider.notifier).guardarSesion(res);
      setState(() {
        _esperandoCodigoCorreo = false;
        _nuevoCorreoCtrl.clear();
        _codigoCorreoCtrl.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo electrónico actualizado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'El código ingresado es incorrecto o ha expirado.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoCorreo = false);
    }
  }

  Future<void> _actualizarPassword() async {
    final actual = _passActualCtrl.text;
    final nueva = _passNuevaCtrl.text;
    final confirm = _passConfirmCtrl.text;

    if (!passwordEsSegura(nueva)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nueva contraseña no cumple con los requisitos de seguridad'), backgroundColor: FashionColors.peligro),
      );
      return;
    }

    if (nueva != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: FashionColors.peligro),
      );
      return;
    }

    setState(() => _cargandoPass = true);
    try {
      await UserService.instance.actualizarContrasena(
        passwordActual: actual,
        password: nueva,
        passwordConfirmation: confirm,
      );
      _passActualCtrl.clear();
      _passNuevaCtrl.clear();
      _passConfirmCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible actualizar la contraseña. Revisa la contraseña actual.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // GESTIÓN DE FOTO
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FashionColors.grisBorde),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _subirNuevaFoto,
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Cambiar foto'),
              ),
              const SizedBox(width: 12),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
                onPressed: _quitarFoto,
                child: const Text('Quitar foto'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // DATOS PERSONALES
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FashionColors.grisBorde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información Personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ciudadCtrl,
                decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección habitual', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                onPressed: _cargandoPerfil ? null : _guardarPerfil,
                child: _cargandoPerfil
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar cambios de perfil'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CAMBIO DE CORREO (2 PASOS)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FashionColors.grisBorde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cambio de Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              if (!_esperandoCodigoCorreo) ...[
                TextField(
                  controller: _nuevoCorreoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Nuevo correo electrónico', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                  onPressed: _cargandoCorreo ? null : _solicitarCambioCorreo,
                  child: _cargandoCorreo
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Solicitar código de cambio'),
                ),
              ] else ...[
                TextField(
                  controller: _codigoCorreoCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Código de 6 dígitos recibido', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: FashionColors.verdeExito, foregroundColor: Colors.white),
                      onPressed: _cargandoCorreo ? null : _confirmarCambioCorreo,
                      child: const Text('Confirmar nuevo correo'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _esperandoCodigoCorreo = false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CAMBIO DE CONTRASEÑA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FashionColors.grisBorde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seguridad y Contraseña', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: _passActualCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passNuevaCtrl,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Nueva contraseña', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passConfirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                onPressed: _cargandoPass ? null : _actualizarPassword,
                child: _cargandoPass
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 2. SECCIÓN MIS PEDIDOS (SeccionMisPedidos.vue)
// ============================================================================
