// @source-mirror: src/views/publico/VistaCarrito.vue, src/views/publico/VistaTerminos.vue
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/validators/garment_and_field_validators.dart';
import '../../../data/models/product_models.dart';
import '../../../data/services/favorites_and_city_service.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/promotion_service.dart';
import '../../../data/services/wompi_service.dart';
import '../../layouts/public_shell_layout.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/storefront_widgets.dart';
import '../../widgets/wompi_checkout_modal.dart';

// ============================================================================
// VISTA CARRITO Y CHECKOUT (VistaCarrito.vue)
// ============================================================================

class CartCheckoutScreen extends ConsumerStatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  ConsumerState<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends ConsumerState<CartCheckoutScreen> {
  bool _cargandoPago = false;
  String? _errorPago;
  bool _mostrarFormularioEnvio = false;
  WompiPaymentOutcome? _reciboConfirmado;

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();
  final TextEditingController _departamentoCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();

  List<Product> _productosRelacionados = [];
  List<Promotion> _promociones = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precargarDatosCliente();
      _cargarRelacionados();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _ciudadCtrl.dispose();
    _departamentoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _precargarDatosCliente() {
    final usuario = ref.read(authProvider).usuario;
    if (usuario != null) {
      if (_nombreCtrl.text.isEmpty) _nombreCtrl.text = usuario['nombre']?.toString() ?? '';
      if (_correoCtrl.text.isEmpty) _correoCtrl.text = usuario['correo']?.toString() ?? usuario['email']?.toString() ?? '';
      if (_telefonoCtrl.text.isEmpty) _telefonoCtrl.text = usuario['telefono']?.toString() ?? '';
      if (_ciudadCtrl.text.isEmpty) _ciudadCtrl.text = usuario['ciudad']?.toString() ?? '';
      if (_departamentoCtrl.text.isEmpty) _departamentoCtrl.text = usuario['departamento']?.toString() ?? usuario['ciudad']?.toString() ?? '';
      if (_direccionCtrl.text.isEmpty) _direccionCtrl.text = usuario['direccion']?.toString() ?? '';
    }
  }

  Future<void> _cargarRelacionados() async {
    try {
      final resultados = await Future.wait([
        ProductService.instance.obtenerProductos(),
        PromotionService.instance.obtenerPromocionesVigentes(),
      ]);

      if (mounted) {
        final todos = resultados[0] as List<Product>;
        final itemsCarrito = ref.read(cartProvider).items;
        final categoriasEnCarrito = itemsCarrito.map((i) => i.categoriaId).whereType<int>().toSet();
        final idsEnCarrito = itemsCarrito.map((i) => i.productoId).toSet();

        final relacionados = todos.where((p) {
          if (idsEnCarrito.contains(p.idProducto)) return false;
          final catId = p.categoria?.idCategoria;
          return catId != null && categoriasEnCarrito.contains(catId);
        }).take(4).toList();

        setState(() {
          _productosRelacionados = relacionados.isNotEmpty ? relacionados : todos.take(4).toList();
          _promociones = resultados[1] as List<Promotion>;
        });
      }
    } catch (_) {}
  }

  bool _validarDatosEnvio() {
    final datos = {
      'nombre': _nombreCtrl.text.trim(),
      'correo': _correoCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'ciudad': _ciudadCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
    };
    final error = validarDatosEntrega(datos);
    if (error.isNotEmpty) {
      setState(() => _errorPago = error);
      return false;
    }
    return true;
  }

  Future<void> _pagarConWompi() async {
    final cartState = ref.read(cartProvider);
    final authState = ref.read(authProvider);

    if (cartState.items.isEmpty) return;
    setState(() => _errorPago = null);

    if (!authState.estaAutenticado) {
      setState(() => _errorPago = 'Inicia sesión para finalizar tu compra.');
      return;
    }

    _precargarDatosCliente();

    if (!_validarDatosEnvio()) {
      setState(() => _mostrarFormularioEnvio = true);
      return;
    }

    setState(() => _cargandoPago = true);

    final datosCliente = {
      'nombre': _nombreCtrl.text.trim(),
      'correo': _correoCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'ciudad': _ciudadCtrl.text.trim(),
      'departamento': _departamentoCtrl.text.trim().isNotEmpty ? _departamentoCtrl.text.trim() : _ciudadCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
    };

    final lineas = cartState.items.map((i) => {
      'id_variante': i.varianteId,
      'cantidad': i.cantidad,
    }).toList();

    WompiCheckoutData pedido;
    try {
      pedido = await WompiService.instance.crearCheckout(lineas, datosCliente);
    } catch (err) {
      if (!mounted) return;
      setState(() => _cargandoPago = false);

      String mensaje = 'No fue posible preparar tu pedido. Intenta de nuevo.';
      if (err is DioException && err.response != null) {
        final cuerpo = err.response?.data;
        final datosError = cuerpo is Map ? (cuerpo['data'] ?? cuerpo) : {};
        final listaSinStock = datosError['sin_stock'] ?? (cuerpo is Map ? cuerpo['sin_stock'] : null);

        if (listaSinStock is List) {
          for (final item in listaSinStock) {
            if (item is Map) {
              final vId = JsonParser.toInt(item['id_variante']);
              final disp = JsonParser.toInt(item['disponible']);
              if (disp > 0) {
                ref.read(cartProvider.notifier).actualizarCantidad(vId, disp);
              } else {
                ref.read(cartProvider.notifier).eliminarPrenda(vId);
              }
            }
          }
        }
        mensaje = cuerpo is Map ? (cuerpo['message'] ?? datosError['message'] ?? mensaje) : mensaje;
      }

      setState(() => _errorPago = mensaje);
      return;
    }

    if (!mounted) return;
    final outcome = await WompiCheckoutModal.iniciarPagoWompiModal(
      context,
      pedido: pedido,
      cliente: datosCliente,
      cancelarAlCerrar: true,
    );

    if (!mounted) return;
    setState(() => _cargandoPago = false);

    if (outcome.status == 'aprobado') {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'fs_ultimo_pedido',
          jsonEncode({
            'referencia': outcome.referencia,
            'idTransaccion': outcome.transaccionId,
            'total': outcome.monto,
            'items': cartState.items.map((e) => e.toJson()).toList(),
            'fecha': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}

      ref.read(cartProvider.notifier).limpiarCarrito();
      setState(() => _reciboConfirmado = outcome);
    } else if (outcome.status == 'revision') {
      setState(() {
        _errorPago = 'Recibimos tu pago (ref. ${outcome.referencia}), pero una prenda se agotó mientras se procesaba. Nuestro equipo te contactará para resolverlo o reembolsarte.';
      });
    } else if (outcome.status == 'pendiente') {
      setState(() {
        _errorPago = 'Tu pago está pendiente de confirmación (ref. ${outcome.referencia}). Te avisaremos cuando se apruebe.';
      });
    } else if (outcome.status == 'error') {
      setState(() {
        _errorPago = outcome.mensaje ?? 'Ocurrió un error al procesar el pago.';
      });
    }
  }

  Future<void> _enviarWhatsApp() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return;

    final buffer = StringBuffer('¡Hola Fashion Style! Me gustaría consultar y apartar las siguientes prendas:\n\n');
    for (int i = 0; i < cartState.items.length; i++) {
      final it = cartState.items[i];
      buffer.writeln('${i + 1}. ${it.nombre} (Talla: ${it.talla}) x${it.cantidad} — ${CurrencyFormatter.formatearCOP(it.precio * it.cantidad)}');
    }
    buffer.writeln('\nTotal estimado: ${CurrencyFormatter.formatearCOP(cartState.totalMonto)}');

    final uri = Uri.parse('https://wa.me/573000000000?text=${Uri.encodeComponent(buffer.toString())}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmarVaciarCarrito() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar bolsa de compras'),
        content: const Text('¿Estás seguro de que deseas eliminar todas las prendas de tu bolsa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.peligro),
            onPressed: () {
              ref.read(cartProvider.notifier).limpiarCarrito();
              Navigator.pop(ctx);
            },
            child: const Text('Vaciar bolsa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);

    return PublicShellLayout(
      child: RefreshIndicator(
        color: FashionColors.rosaCorporativo,
        onRefresh: () async => _cargarRelacionados(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // SI SE RECIBIÓ CONFIRMACIÓN DE PAGO
            if (_reciboConfirmado != null)
              _construirReciboConfirmado()
            // SI EL CARRITO ESTÁ VACÍO
            else if (cartState.items.isEmpty)
              _construirCarritoVacio()
            // CARRITO CON ITEMS Y FORMULARIO DE CHECKOUT
            else ...[
              // ENCABEZADO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bolsa de Compras (${cartState.totalPrendas})',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: FashionColors.textoOscuro,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
                    onPressed: _confirmarVaciarCarrito,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Vaciar bolsa', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // LISTA DE PRENDAS EN BOLSA
              ...cartState.items.map((item) => _construirTarjetaItem(item)),

              const SizedBox(height: 20),

              // RESUMEN DE COMPRA
              _construirResumenFinanciero(cartState),

              const SizedBox(height: 20),

              // AVISO DE AUTENTICACIÓN SI ES REQUERIDO
              if (!authState.estaAutenticado)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FashionColors.rosaSuave,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FashionColors.rosaCorporativo.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: FashionColors.rosaOscuro),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inicia sesión para pagar',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FashionColors.textoOscuro),
                            ),
                            const Text(
                              'Guarda tu pedido, genera tu recibo y dale seguimiento a tus despachos.',
                              style: TextStyle(fontSize: 11, color: FashionColors.textoMuted),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FashionColors.negroElegante,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => context.go('/login?redir=%2Fcarrito'),
                        child: const Text('Ingresar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // FORMULARIO DE DATOS DE ENTREGA
              _construirFormularioEntrega(),

              const SizedBox(height: 16),

              // MENSAJE DE ERROR DE PAGO SI EXISTE
              if (_errorPago != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FashionColors.peligro.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FashionColors.peligro.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: FashionColors.peligro, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorPago!,
                          style: const TextStyle(color: FashionColors.peligro, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // BOTONES DE ACCIÓN: PAGAR CON WOMPI O WHATSAPP
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.negroElegante,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _cargandoPago ? null : _pagarConWompi,
                  icon: _cargandoPago
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.credit_card),
                  label: Text(
                    _cargandoPago ? 'Conectando con Wompi...' : 'Pagar con Wompi Bancolombia',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    backgroundColor: const Color(0xFFF0FDFA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _enviarWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Consultar y apartar por WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),

              const SizedBox(height: 32),

              // SECCIÓN INFERIOR DE PRODUCTOS RELACIONADOS
              if (_productosRelacionados.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'También te podría gustar',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FashionColors.textoOscuro,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _productosRelacionados.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCardWidget(
                      producto: _productosRelacionados[index],
                      promocionesVigentes: _promociones,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FashionColors.grisBorde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 85,
              child: item.imagen.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imagen,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: FashionColors.rosaSuave),
                      errorWidget: (_, __, ___) => const Icon(Icons.style, color: FashionColors.textoMuted),
                    )
                  : const Icon(Icons.style, color: FashionColors.textoMuted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: FashionColors.fondoClaro,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: FashionColors.grisBorde),
                  ),
                  child: Text(
                    'Talla: ${item.talla}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.formatearCOP(item.precio),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: FashionColors.textoOscuro,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: FashionColors.grisBorde),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: item.cantidad > 1
                                ? () => ref.read(cartProvider.notifier).actualizarCantidad(item.varianteId, item.cantidad - 1)
                                : null,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${item.cantidad}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          InkWell(
                            onTap: item.cantidad < item.stockMaximo
                                ? () => ref.read(cartProvider.notifier).actualizarCantidad(item.varianteId, item.cantidad + 1)
                                : null,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: FashionColors.peligro),
                      tooltip: 'Eliminar',
                      onPressed: () => ref.read(cartProvider.notifier).eliminarPrenda(item.varianteId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirResumenFinanciero(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FashionColors.grisBorde),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal prendas:', style: TextStyle(color: FashionColors.textoMuted)),
              Text(CurrencyFormatter.formatearCOP(cart.totalMonto), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Costo de envío:', style: TextStyle(color: FashionColors.textoMuted)),
              Text('Gratis a nivel nacional', style: TextStyle(color: FashionColors.verdeExito, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a pagar:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                CurrencyFormatter.formatearCOP(cart.totalMonto),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.textoOscuro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirFormularioEntrega() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FashionColors.grisBorde),
      ),
      child: ExpansionTile(
        initiallyExpanded: _mostrarFormularioEnvio,
        onExpansionChanged: (exp) => setState(() => _mostrarFormularioEnvio = exp),
        title: const Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: FashionColors.rosaOscuro, size: 20),
            SizedBox(width: 8),
            Text(
              'Datos para el Envío y Factura',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre completo destinatario *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono de contacto (10 dígitos) *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          // Autocomplete de ciudad colombiana
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _ciudadCtrl.text),
            optionsBuilder: (textEditingValue) async {
              if (textEditingValue.text.length < 2) return const [];
              return await CityValidationService.instance.buscarCiudades(textEditingValue.text);
            },
            onSelected: (seleccion) {
              _ciudadCtrl.text = seleccion;
              _departamentoCtrl.text = seleccion;
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Ciudad de destino *',
                  hintText: 'Ej. Medellín, Bogotá, Cali...',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.location_city, size: 18),
                ),
                onChanged: (val) {
                  _ciudadCtrl.text = val;
                  _departamentoCtrl.text = val;
                },
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _direccionCtrl,
            decoration: const InputDecoration(
              labelText: 'Dirección completa (calle, número, apto/barrio) *',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCarritoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: FashionColors.rosaSuave,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 54, color: FashionColors.rosaOscuro),
            ),
            const SizedBox(height: 20),
            Text(
              'Tu bolsa de compras está vacía',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: FashionColors.textoOscuro,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Descubre nuestras colecciones exclusivas y agrega tus prendas favoritas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FashionColors.textoMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.negroElegante,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => context.go('/catalogo'),
              child: const Text('Explorar el catálogo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirReciboConfirmado() {
    final r = _reciboConfirmado!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FashionColors.verdeExito.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, size: 48, color: FashionColors.verdeExito),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Pago Confirmado con Éxito!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FashionColors.textoOscuro,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tu orden ha sido registrada en el sistema de Fashion Style y comenzará su empaque.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: FashionColors.textoMuted),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _filaRecibo('Referencia de pedido:', r.referencia),
          if (r.transaccionId != null) _filaRecibo('ID Transacción Wompi:', r.transaccionId!),
          if (r.metodoPago != null) _filaRecibo('Método utilizado:', r.metodoPago!),
          _filaRecibo('Monto abonado:', CurrencyFormatter.formatearCOP(r.monto)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/catalogo'),
                  child: const Text('Seguir comprando'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                  onPressed: () => context.go('/perfil?seccion=pedidos'),
                  child: const Text('Ver mis pedidos'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filaRecibo(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 12, color: FashionColors.textoMuted)),
          Text(valor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FashionColors.textoOscuro)),
        ],
      ),
    );
  }
}

// ============================================================================
// VISTA TÉRMINOS Y CONDICIONES (VistaTerminos.vue)
// ============================================================================

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _termino;

  @override
  void initState() {
    super.initState();
    _cargarTerminos();
  }

  Future<void> _cargarTerminos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.dio.get('/terminos-condiciones');
      final data = ApiResponseParser.extractData(response);
      if (mounted) {
        setState(() {
          _termino = data is Map<String, dynamic> ? data : {};
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No fue posible cargar los términos y condiciones desde el servidor.';
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicShellLayout(
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: FashionColors.peligro),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante),
                          onPressed: _cargarTerminos,
                          child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: FashionColors.grisBorde),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _termino?['titulo']?.toString() ?? 'Términos y Condiciones de Uso',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.textoOscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Versión ${_termino?['version'] ?? '1.0'}',
                          style: const TextStyle(fontSize: 12, color: FashionColors.textoMuted),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          _termino?['contenido']?.toString() ??
                              'Al acceder a nuestra plataforma y adquirir productos, aceptas nuestros términos de despacho, garantías y tratamiento seguro de datos.',
                          style: const TextStyle(fontSize: 14, height: 1.6, color: FashionColors.textoOscuro),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
