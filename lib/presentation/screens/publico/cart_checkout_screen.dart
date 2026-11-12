// @source-mirror: src/views/publico/VistaCarrito.vue, src/views/publico/VistaTerminos.vue
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/data/models/cart/cart_item.dart';
import 'package:fashion_style_mobile/data/models/payment/wompi_checkout_data.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/city_validation_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/data/services/wompi_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/product_card.dart';
import 'package:fashion_style_mobile/presentation/widgets/payment/wompi_checkout_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
        final crudo = cuerpo is Map ? (cuerpo['message'] ?? datosError['message'] ?? mensaje) : mensaje;
        mensaje = ApiClient.sanitizarTextoError(
          crudo,
          'Algunas prendas seleccionadas ya no tienen stock suficiente. Se actualizó tu bolsa.',
        );
      } else {
        mensaje = ApiClient.obtenerMensajeError(
          err,
          'No fue posible preparar tu pedido. Por favor intenta nuevamente.',
        );
      }

      setState(() => _errorPago = mensaje);
      return;
    }

    if (!mounted) return;
    final outcome = await WompiCheckoutModal.iniciarPagoWompiModal(
      context,
      pedido: pedido,
      cliente: datosCliente,
      cancelarAlCerrar: false,
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

    final lineas = cartState.items.map((i) {
      return '- ${i.nombre} (Talla: ${i.talla}) x${i.cantidad} = ${CurrencyFormatter.formatearCOP(i.precio * i.cantidad)}';
    }).join('\n');

    final mensaje = '''
¡Hola Fashion Style! Deseo consultar la disponibilidad y apartar las siguientes prendas de mi bolsa:

$lineas

Total estimado: ${CurrencyFormatter.formatearCOP(cartState.totalMonto)}
Destino: ${_ciudadCtrl.text.isNotEmpty ? _ciudadCtrl.text : 'A convenir'}

¿Podrían asistirme con el despacho? ¡Muchas gracias!
''';

    final uri = Uri.parse('https://wa.me/573001234567?text=${Uri.encodeComponent(mensaje.trim())}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmarVaciarCarrito() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FashionColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Vaciar bolsa de compras?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Se eliminarán todas las prendas que tienes agregadas en este momento.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FashionColors.statusDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref.read(cartProvider.notifier).limpiarCarrito();
              Navigator.pop(ctx);
            },
            child: const Text('Vaciar bolsa'),
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
        color: FashionColors.brandAccent,
        backgroundColor: FashionColors.surfaceCard,
        onRefresh: _cargarRelacionados,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // Clearance para Floating Pill Dock
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
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: FashionColors.inkPrimary,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: FashionColors.statusDanger),
                    onPressed: _confirmarVaciarCarrito,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(
                      'Vaciar bolsa',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // LISTA DE PRENDAS EN BOLSA
              ...cartState.items.map((item) => _construirTarjetaItem(item)),

              const SizedBox(height: 20),

              // RESUMEN DE COMPRA CON JETBRAINS MONO
              _construirResumenFinanciero(cartState),

              const SizedBox(height: 20),

              // AVISO DE AUTENTICACIÓN SI ES REQUERIDO
              if (!authState.estaAutenticado)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FashionColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FashionColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: FashionColors.brandAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inicia sesión para pagar',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13.5, color: FashionColors.inkPrimary),
                            ),
                            Text(
                              'Guarda tu pedido, genera tu recibo y dale seguimiento a tus despachos.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: FashionColors.inkSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FashionColors.inkPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => context.go('/login?redir=%2Fcarrito'),
                        child: Text(
                          'Ingresar',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
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
                    color: FashionColors.statusDanger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FashionColors.statusDanger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: FashionColors.statusDanger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorPago!,
                          style: GoogleFonts.plusJakartaSans(color: FashionColors.statusDanger, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // BOTONES DE ACCIÓN: PAGAR CON WOMPI TERRACOTTA (#B83A24) O WHATSAPP
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.brandAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
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
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FashionColors.slateAccent,
                    side: const BorderSide(color: FashionColors.slateAccent),
                    backgroundColor: FashionColors.surfaceCard,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _enviarWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(
                    'Consultar y apartar por WhatsApp',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // SECCIÓN INFERIOR DE PRODUCTOS RELACIONADOS
              if (_productosRelacionados.isNotEmpty) ...[
                const Divider(color: FashionColors.borderSubtle),
                const SizedBox(height: 16),
                Text(
                  'También te podría gustar',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: FashionColors.inkPrimary,
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
                    childAspectRatio: 0.63,
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
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FashionColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 96,
              child: item.imagen.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imagen,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: FashionColors.surfaceMuted),
                      errorWidget: (_, __, ___) => const Icon(Icons.checkroom_rounded, color: FashionColors.inkSecondary),
                    )
                  : const Icon(Icons.checkroom_rounded, color: FashionColors.inkSecondary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: FashionColors.inkPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: FashionColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Talla: ${item.talla}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.formatearCOP(item.precio),
                      style: FashionTheme.priceTextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: FashionColors.inkPrimary,
                      ),
                    ),
                    if (item.precioOriginal > item.precio) ...[
                      const SizedBox(width: 6),
                      Text(
                        CurrencyFormatter.formatearCOP(item.precioOriginal),
                        style: FashionTheme.priceTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.lineThrough,
                          color: FashionColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: FashionColors.statusDanger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${item.porcentajeDescuento}%',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.statusDanger,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: FashionColors.borderSubtle),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: item.cantidad > 1
                                ? () => ref.read(cartProvider.notifier).actualizarCantidad(item.varianteId, item.cantidad - 1)
                                : null,
                            child: const Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Icon(Icons.remove, size: 16, color: FashionColors.inkPrimary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${item.cantidad}',
                              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 13, color: FashionColors.inkPrimary),
                            ),
                          ),
                          InkWell(
                            onTap: item.cantidad < item.stockMaximo
                                ? () => ref.read(cartProvider.notifier).actualizarCantidad(item.varianteId, item.cantidad + 1)
                                : null,
                            child: const Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Icon(Icons.add, size: 16, color: FashionColors.inkPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: FashionColors.statusDanger),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FashionColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal prendas:', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13)),
              Text(
                CurrencyFormatter.formatearCOP(cart.totalMonto),
                style: FashionTheme.priceTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Costo de envío:', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13)),
              Text(
                'Gratis a nivel nacional',
                style: GoogleFonts.plusJakartaSans(color: FashionColors.statusSuccess, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
          const Divider(height: 24, color: FashionColors.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total a pagar:',
                style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
              ),
              Text(
                CurrencyFormatter.formatearCOP(cart.totalMonto),
                style: FashionTheme.priceTextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.inkPrimary,
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
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FashionColors.borderSubtle),
      ),
      child: ExpansionTile(
        initiallyExpanded: _mostrarFormularioEnvio,
        onExpansionChanged: (exp) => setState(() => _mostrarFormularioEnvio = exp),
        title: Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: FashionColors.brandAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              'Datos para el Envío y Factura',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14, color: FashionColors.inkPrimary),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          TextField(
            controller: _nombreCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre completo destinatario *',
              filled: true,
              fillColor: FashionColors.surfaceMuted,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo electrónico *',
              filled: true,
              fillColor: FashionColors.surfaceMuted,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono de contacto (10 dígitos) *',
              filled: true,
              fillColor: FashionColors.surfaceMuted,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
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
                decoration: InputDecoration(
                  labelText: 'Ciudad de destino *',
                  hintText: 'Ej. Medellín, Bogotá, Cali...',
                  filled: true,
                  fillColor: FashionColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  suffixIcon: const Icon(Icons.location_city, size: 18, color: FashionColors.inkSecondary),
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
            decoration: InputDecoration(
              labelText: 'Dirección completa (calle, número, apto/barrio) *',
              filled: true,
              fillColor: FashionColors.surfaceMuted,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCarritoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const AtelierEmptyStateIllustration(
              type: AtelierEmptyStateType.emptyBag,
              size: 140,
            ),
            const SizedBox(height: 20),
            Text(
              'Tu bolsa de compras está vacía',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: FashionColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Descubre nuestras colecciones exclusivas y agrega tus prendas favoritas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.inkPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FashionColors.statusSuccess.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FashionColors.statusSuccess.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 48, color: FashionColors.statusSuccess),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Pago Confirmado con Éxito!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FashionColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tu orden ha sido registrada en el sistema de Fashion Style y comenzará su confección y despacho.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkSecondary),
          ),
          const SizedBox(height: 20),
          const Divider(color: FashionColors.borderSubtle),
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FashionColors.inkPrimary,
                    side: const BorderSide(color: FashionColors.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.go('/catalogo'),
                  child: const Text('Seguir comprando'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.inkPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
          Text(etiqueta, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary)),
          Text(
            valor,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
          ),
        ],
      ),
    );
  }
}
