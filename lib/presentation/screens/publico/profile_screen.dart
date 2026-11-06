// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/validators/garment_and_field_validators.dart';
import '../../../core/validators/password_validator.dart';
import '../../../data/models/product_models.dart';
import '../../../data/services/favorites_and_city_service.dart';
import '../../../data/services/order_and_invoice_service.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/promotion_service.dart';
import '../../../data/services/user_and_security_service.dart';
import '../../../data/services/wompi_service.dart';
import '../../layouts/public_shell_layout.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/storefront_widgets.dart';
import '../../widgets/wompi_checkout_modal.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? initialSection;

  const ProfileScreen({
    super.key,
    this.initialSection,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialSection == 'pedidos') {
      initialIndex = 1;
    } else if (widget.initialSection == 'favoritos') {
      initialIndex = 2;
    }

    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return PublicShellLayout(
      currentIndex: 3,
      child: Column(
        children: [
          // CABECERA CON AVATAR Y DATOS BÁSICOS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: FashionColors.rosaSuave,
                      backgroundImage: (authState.fotoUsuario != null && authState.fotoUsuario!.isNotEmpty)
                          ? NetworkImage(authState.fotoUsuario!)
                          : null,
                      child: (authState.fotoUsuario == null || authState.fotoUsuario!.isEmpty)
                          ? Text(
                              authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: FashionColors.rosaOscuro),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.nombreUsuario.isNotEmpty ? authState.nombreUsuario : 'Usuario Fashion Style',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: FashionColors.textoOscuro,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authState.correoUsuario,
                            style: const TextStyle(fontSize: 13, color: FashionColors.textoMuted),
                          ),
                          if (authState.tieneAccesoAdmin)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: FashionColors.rosaSuave,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ROL STAFF / ADMINISTRADOR',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FashionColors.rosaOscuro),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // PESTAÑAS INTERNAS
                TabBar(
                  controller: _tabController,
                  labelColor: FashionColors.negroElegante,
                  unselectedLabelColor: FashionColors.textoMuted,
                  indicatorColor: FashionColors.rosaCorporativo,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Mis Datos'),
                    Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Mis Pedidos'),
                    Tab(icon: Icon(Icons.favorite_border, size: 18), text: 'Favoritos'),
                  ],
                ),
              ],
            ),
          ),

          // CONTENIDO DE LAS PESTAÑAS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _SeccionMisDatos(),
                _SeccionMisPedidos(),
                _SeccionFavoritos(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. SECCIÓN MIS DATOS (Avatar, Perfil, Cambio de Correo y Contraseña)
// ============================================================================

class _SeccionMisDatos extends ConsumerStatefulWidget {
  const _SeccionMisDatos();

  @override
  ConsumerState<_SeccionMisDatos> createState() => _SeccionMisDatosState();
}

class _SeccionMisDatosState extends ConsumerState<_SeccionMisDatos> {
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
          SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: FashionColors.peligro),
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
          SnackBar(content: Text('No se pudo quitar la foto: $e'), backgroundColor: FashionColors.peligro),
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
          SnackBar(content: Text('Error al actualizar perfil: $e'), backgroundColor: FashionColors.peligro),
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
          SnackBar(content: Text('Error al solicitar cambio: $e'), backgroundColor: FashionColors.peligro),
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
          SnackBar(content: Text('Código inválido o expirado: $e'), backgroundColor: FashionColors.peligro),
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
          SnackBar(content: Text('No fue posible actualizar la contraseña: $e'), backgroundColor: FashionColors.peligro),
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

class _SeccionMisPedidos extends ConsumerStatefulWidget {
  const _SeccionMisPedidos();

  @override
  ConsumerState<_SeccionMisPedidos> createState() => _SeccionMisPedidosState();
}

class _SeccionMisPedidosState extends ConsumerState<_SeccionMisPedidos> {
  bool _cargando = true;
  bool _cargandoMas = false;
  String? _error;
  String _filtroEstado = '';
  int _pagina = 1;
  int _totalPaginas = 1;
  List<OrderModel> _pedidos = [];
  int? _pedidoExpandido;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos({bool reiniciar = true}) async {
    if (reiniciar) {
      setState(() {
        _cargando = true;
        _pagina = 1;
        _error = null;
      });
    } else {
      setState(() => _cargandoMas = true);
    }

    try {
      final res = await OrderService.instance.listarPedidos(
        pagina: _pagina,
        estado: _filtroEstado,
      );

      if (mounted) {
        setState(() {
          _pedidos = reiniciar ? res.lista : [..._pedidos, ...res.lista];
          _totalPaginas = res.totalPaginas;
          _cargando = false;
          _cargandoMas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los pedidos.';
          _cargando = false;
          _cargandoMas = false;
        });
      }
    }
  }

  Future<void> _pagarAhora(OrderModel pedido) async {
    try {
      final checkout = await WompiService.instance.reanudarCheckout(pedido.referencia);
      final cliente = {
        'nombre': pedido.clienteNombre,
        'correo': pedido.clienteCorreo,
        'telefono': pedido.telefono,
        'ciudad': pedido.ciudad,
        'direccion': pedido.direccion,
      };

      if (!mounted) return;
      final outcome = await WompiCheckoutModal.iniciarPagoWompiModal(
        context,
        pedido: checkout,
        cliente: cliente,
        cancelarAlCerrar: false,
      );

      if (outcome.status == 'aprobado') {
        _cargarPedidos(reiniciar: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Pago completado con éxito!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reanudar el pago: $e'), backgroundColor: FashionColors.peligro),
        );
      }
    }
  }

  Future<void> _cancelarPedido(OrderModel pedido) async {
    try {
      await WompiService.instance.cancelarCheckout(pedido.referencia);
      _cargarPedidos(reiniciar: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cancelado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar: $e'), backgroundColor: FashionColors.peligro),
        );
      }
    }
  }

  Future<void> _recomprar(OrderModel pedido) async {
    int agregados = 0;
    for (final it in pedido.detalles) {
      if (it.productoId != null) {
        final prod = await ProductService.instance.obtenerProducto(it.productoId!);
        if (prod != null) {
          final variante = prod.variantes.where((v) => v.idVariante == it.varianteId).firstOrNull;
          if (variante != null && variante.stock > 0) {
            ref.read(cartProvider.notifier).agregarPrenda(prod, variante, it.cantidad);
            agregados++;
          }
        }
      }
    }

    if (mounted) {
      if (agregados > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se agregaron $agregados prendas disponibles a tu bolsa.'),
            action: SnackBarAction(
              label: 'Ir a bolsa',
              onPressed: () => context.go('/carrito'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las prendas de este pedido no tienen stock disponible actualmente.')),
        );
      }
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Pagado':
      case 'Entregado':
        return FashionColors.verdeExito;
      case 'En_Preparacion':
      case 'Enviado':
        return FashionColors.azulInfo;
      case 'Pendiente_Pago':
      case 'Revision_Pago':
        return FashionColors.aviso;
      case 'Cancelado':
      case 'Rechazado':
      case 'Expirado':
      default:
        return FashionColors.peligro;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estados = [
      {'val': '', 'label': 'Todos'},
      {'val': 'Pendiente_Pago', 'label': 'Pendiente'},
      {'val': 'Pagado', 'label': 'Pagado'},
      {'val': 'En_Preparacion', 'label': 'En preparación'},
      {'val': 'Enviado', 'label': 'Enviado'},
      {'val': 'Entregado', 'label': 'Entregado'},
    ];

    return Column(
      children: [
        // CHIPS DE FILTRO POR ESTADO
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: estados.map((e) {
              final sel = _filtroEstado == e['val'];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(e['label']!),
                  selected: sel,
                  selectedColor: FashionColors.negroElegante,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? Colors.white : FashionColors.textoOscuro,
                  ),
                  onSelected: (_) {
                    setState(() => _filtroEstado = e['val']!);
                    _cargarPedidos(reiniciar: true);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // LISTA DE PEDIDOS O ESTADOS
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
              : _error != null
                  ? Center(child: Text(_error!))
                  : _pedidos.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No tienes pedidos registrados en este estado.',
                              style: TextStyle(color: FashionColors.textoMuted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pedidos.length + (_pagina < _totalPaginas ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _pedidos.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: FashionColors.fondoClaro, foregroundColor: FashionColors.textoOscuro),
                                    onPressed: _cargandoMas
                                        ? null
                                        : () {
                                            _pagina++;
                                            _cargarPedidos(reiniciar: false);
                                          },
                                    child: _cargandoMas
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Cargar más pedidos'),
                                  ),
                                ),
                              );
                            }

                            final pedido = _pedidos[index];
                            final expandido = _pedidoExpandido == pedido.id;
                            final esOnline = pedido.referencia.startsWith('FS-') && !pedido.referencia.startsWith('FS-PED-');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: FashionColors.grisBorde),
                              ),
                              child: Column(
                                children: [
                                  // Encabezado del pedido
                                  ListTile(
                                    onTap: () => setState(() => _pedidoExpandido = expandido ? null : pedido.id),
                                    title: Row(
                                      children: [
                                        Text(
                                          pedido.referencia,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _colorEstado(pedido.estado).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            OrderService.estadosPedido[pedido.estado] ?? pedido.estado,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _colorEstado(pedido.estado),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${pedido.fechaPedido} · Total: ${CurrencyFormatter.formatearCOP(pedido.total)}',
                                      style: const TextStyle(fontSize: 12, color: FashionColors.textoMuted),
                                    ),
                                    trailing: Icon(expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                                  ),

                                  // Detalle expandible
                                  if (expandido) ...[
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Ítems de la orden
                                          ...pedido.detalles.map((it) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${it.nombre} (${it.talla}) x${it.cantidad}',
                                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                    Text(
                                                      CurrencyFormatter.formatearCOP(it.subtotal),
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              )),

                                          const SizedBox(height: 12),
                                          if (pedido.numeroGuia.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: FashionColors.fondoClaro, borderRadius: BorderRadius.circular(6)),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.local_shipping, size: 16, color: FashionColors.rosaOscuro),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Guía: ${pedido.numeroGuia} (${pedido.empresaTransportadora})',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          const SizedBox(height: 12),
                                          // Acciones de pago o recompra
                                          Row(
                                            children: [
                                              if (pedido.estado == 'Pendiente_Pago' && esOnline) ...[
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                                                  onPressed: () => _pagarAhora(pedido),
                                                  child: const Text('Pagar ahora', style: TextStyle(fontSize: 12)),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: () => _cancelarPedido(pedido),
                                                  child: const Text('Cancelar', style: TextStyle(fontSize: 12, color: FashionColors.peligro)),
                                                ),
                                              ],
                                              const Spacer(),
                                              TextButton.icon(
                                                onPressed: () => _recomprar(pedido),
                                                icon: const Icon(Icons.replay, size: 16),
                                                label: const Text('Volver a comprar', style: TextStyle(fontSize: 12)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

// ============================================================================
// 3. SECCIÓN FAVORITOS (SeccionFavoritos.vue)
// ============================================================================

class _SeccionFavoritos extends ConsumerStatefulWidget {
  const _SeccionFavoritos();

  @override
  ConsumerState<_SeccionFavoritos> createState() => _SeccionFavoritosState();
}

class _SeccionFavoritosState extends ConsumerState<_SeccionFavoritos> {
  bool _cargando = true;
  List<Product> _productos = [];
  List<Promotion> _promociones = [];

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    try {
      final resultados = await Future.wait([
        ProductService.instance.obtenerProductos(),
        PromotionService.instance.obtenerPromocionesVigentes(),
      ]);

      if (mounted) {
        setState(() {
          _productos = resultados[0] as List<Product>;
          _promociones = resultados[1] as List<Promotion>;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favsState = ref.watch(favoritesProvider);
    final prendasFavoritas = _productos.where((p) => favsState.esFavorito(p.idProducto)).toList();

    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo));
    }

    if (prendasFavoritas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border, size: 48, color: FashionColors.textoMuted),
              const SizedBox(height: 12),
              const Text(
                'No tienes prendas guardadas en favoritos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                onPressed: () => context.go('/catalogo'),
                child: const Text('Descubrir catálogo'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prendasFavoritas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        return ProductCardWidget(
          producto: prendasFavoritas[index],
          promocionesVigentes: _promociones,
        );
      },
    );
  }
}
