// @source-mirror: src/services/wompiServicio.js
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/models/payment/wompi_checkout_data.dart';
import 'package:fashion_style_mobile/data/services/wompi_service.dart';
class WompiPaymentOutcome {
  final String status; // 'aprobado' | 'pendiente' | 'revision' | 'cancelado' | 'error'
  final String? transaccionId;
  final String referencia;
  final String? metodoPago;
  final double monto;
  final String? mensaje;

  const WompiPaymentOutcome({
    required this.status,
    this.transaccionId,
    required this.referencia,
    this.metodoPago,
    required this.monto,
    this.mensaje,
  });

  bool get esExitoso => status == 'aprobado';
}

class WompiCheckoutModal {
  static Future<WompiPaymentOutcome> iniciarPagoWompiModal(
    BuildContext context, {
    required WompiCheckoutData pedido,
    required Map<String, dynamic> cliente,
    bool cancelarAlCerrar = false,
  }) async {
    // 1. Manejo de checkout simulado (pruebas / local sin llaves reales)
    if (pedido.simulado) {
      final simId = 'SIM-${DateTime.now().millisecondsSinceEpoch}';
      try {
        final resultado = await WompiService.instance.confirmarCheckout(pedido.referencia, simId);
        final estado = resultado['estado']?.toString();
        final String statusFinal;
        if (estado == 'Pagado') {
          statusFinal = 'aprobado';
        } else if (estado == 'Revision_Pago') {
          statusFinal = 'revision';
        } else if (estado == 'Pendiente_Pago') {
          statusFinal = 'pendiente';
        } else {
          statusFinal = 'error';
        }

        return WompiPaymentOutcome(
          status: statusFinal,
          transaccionId: simId,
          referencia: pedido.referencia,
          metodoPago: 'SIMULADO',
          monto: pedido.montoTotal,
          mensaje: resultado['mensaje']?.toString() ?? 'Transacción simulada procesada con éxito.',
        );
      } catch (e) {
        return WompiPaymentOutcome(
          status: 'error',
          referencia: pedido.referencia,
          monto: pedido.montoTotal,
          mensaje: 'Error al confirmar checkout simulado: $e',
        );
      }
    }

    // 2. Validación de credenciales obligatorias
    if (pedido.referencia.isEmpty || pedido.firmaIntegridad.isEmpty || pedido.publicKey.isEmpty) {
      return WompiPaymentOutcome(
        status: 'error',
        referencia: pedido.referencia,
        monto: pedido.montoTotal,
        mensaje: 'La configuración de la pasarela Wompi está incompleta (falta llave pública o firma).',
      );
    }

    // 3. Despliegue de WebView con el Widget oficial de Wompi
    final resultadoModal = await showModalBottomSheet<_ModalWompiResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WompiWebViewSheet(
        pedido: pedido,
        cliente: cliente,
      ),
    );

    // 4. Si el usuario cerró el modal o no se extrajo directamente el transaccionId
    final transaccionId = resultadoModal?.transaccionId;

    if (transaccionId == null || transaccionId.trim().isEmpty) {
      // ANTES DE CANCELAR: Verificar si el backend ya registró el pago (por Webhook o API)
      try {
        final estadoBackend = await WompiService.instance.consultarEstadoPedido(pedido.referencia);
        final estado = estadoBackend['estado']?.toString();
        if (estado == 'Pagado') {
          return WompiPaymentOutcome(
            status: 'aprobado',
            referencia: pedido.referencia,
            metodoPago: estadoBackend['metodo_pago']?.toString() ?? 'WOMPI',
            monto: pedido.montoTotal,
            mensaje: 'Pago confirmado exitosamente por el banco.',
          );
        } else if (estado == 'Revision_Pago') {
          return WompiPaymentOutcome(
            status: 'revision',
            referencia: pedido.referencia,
            metodoPago: estadoBackend['metodo_pago']?.toString() ?? 'WOMPI',
            monto: pedido.montoTotal,
            mensaje: 'Pago recibido. Está en revisión de inventario.',
          );
        }
      } catch (_) {}

      // Al salir de Wompi o no completarse el pago, NO cancelar el pedido: se deja en estado Pendiente
      // para permitir que el cliente lo reintente pagar desde "Mis Pedidos", coincidiendo con el flujo Web.
      return WompiPaymentOutcome(
        status: 'pendiente',
        referencia: pedido.referencia,
        monto: pedido.montoTotal,
        mensaje: 'El pago continúa pendiente en Mis Pedidos para completarlo cuando desees.',
      );
    }

    // 5. Transacción completada en el widget: confirmación contra el backend
    try {
      final confirmacion = await WompiService.instance.confirmarCheckout(
        pedido.referencia,
        transaccionId,
      );

      final estado = confirmacion['estado']?.toString();
      final String statusFinal;
      if (estado == 'Pagado') {
        statusFinal = 'aprobado';
      } else if (estado == 'Revision_Pago') {
        statusFinal = 'revision';
      } else if (estado == 'Pendiente_Pago') {
        statusFinal = 'pendiente';
      } else {
        statusFinal = 'error';
      }

      return WompiPaymentOutcome(
        status: statusFinal,
        transaccionId: transaccionId,
        referencia: pedido.referencia,
        metodoPago: resultadoModal?.metodoPago ?? confirmacion['metodo_pago']?.toString() ?? 'WOMPI',
        monto: pedido.montoTotal,
        mensaje: confirmacion['mensaje']?.toString(),
      );
    } catch (e) {
      // Re-verificación de resiliencia: si falló la confirmación pero el webhook o backend ya lo actualizó
      try {
        final estadoBackend = await WompiService.instance.consultarEstadoPedido(pedido.referencia);
        final estado = estadoBackend['estado']?.toString();
        if (estado == 'Pagado') {
          return WompiPaymentOutcome(
            status: 'aprobado',
            transaccionId: transaccionId,
            referencia: pedido.referencia,
            metodoPago: estadoBackend['metodo_pago']?.toString() ?? 'WOMPI',
            monto: pedido.montoTotal,
            mensaje: 'Pago confirmado por el servidor.',
          );
        } else if (estado == 'Revision_Pago') {
          return WompiPaymentOutcome(
            status: 'revision',
            transaccionId: transaccionId,
            referencia: pedido.referencia,
            metodoPago: estadoBackend['metodo_pago']?.toString() ?? 'WOMPI',
            monto: pedido.montoTotal,
            mensaje: 'Pago en revisión de inventario.',
          );
        }
      } catch (_) {}

      return WompiPaymentOutcome(
        status: 'error',
        transaccionId: transaccionId,
        referencia: pedido.referencia,
        monto: pedido.montoTotal,
        mensaje: 'Error al confirmar la transacción con el servidor: $e',
      );
    }
  }
}

class _ModalWompiResult {
  final String? transaccionId;
  final String? status;
  final String? metodoPago;

  const _ModalWompiResult({
    this.transaccionId,
    this.status,
    this.metodoPago,
  });
}

class _WompiWebViewSheet extends StatefulWidget {
  final WompiCheckoutData pedido;
  final Map<String, dynamic> cliente;

  const _WompiWebViewSheet({
    required this.pedido,
    required this.cliente,
  });

  @override
  State<_WompiWebViewSheet> createState() => _WompiWebViewSheetState();
}

class _WompiWebViewSheetState extends State<_WompiWebViewSheet> {
  late final WebViewController _controller;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializarWebView();
  }

  void _inicializarWebView() {
    final pedido = widget.pedido;
    final cliente = widget.cliente;

    final emailCliente = (cliente['correo'] ?? cliente['email'] ?? '').toString().trim();
    final nombreCliente = (cliente['nombre'] ?? '').toString().trim();
    final telefonoCliente = (cliente['telefono'] ?? '').toString().trim();
    final direccionCliente = (cliente['direccion'] ?? '').toString().trim();
    final ciudadCliente = (cliente['ciudad'] ?? '').toString().trim();
    final regionCliente = (cliente['departamento'] ?? cliente['ciudad'] ?? '').toString().trim();

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Pasarela Wompi</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background: #F6F7F9;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      box-sizing: border-box;
    }
    .cargando-box {
      text-align: center;
      color: #14161F;
    }
    .spinner {
      border: 4px solid #DFE3EC;
      border-top: 4px solid #B83A24;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 1s linear infinite;
      margin: 0 auto 16px auto;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
  <script type="text/javascript" src="https://checkout.wompi.co/widget.js"></script>
</head>
<body>
  <div class="cargando-box" id="loader">
    <div class="spinner"></div>
    <p>Conectando de forma segura con Bancolombia / Wompi...</p>
  </div>

  <script type="text/javascript">
    window.addEventListener('DOMContentLoaded', function() {
      try {
        var checkout = new WidgetCheckout({
          currency: '${pedido.moneda}',
          amountInCents: ${pedido.montoCentavos},
          reference: '${pedido.referencia}',
          publicKey: '${pedido.publicKey}',
          signature: { integrity: '${pedido.firmaIntegridad}' },
          customerData: {
            email: '${jsonEncode(emailCliente).replaceAll('"', '')}',
            fullName: '${jsonEncode(nombreCliente).replaceAll('"', '')}',
            phoneNumber: '${jsonEncode(telefonoCliente).replaceAll('"', '')}',
            phoneNumberPrefix: '+57',
            legalId: '000000000',
            legalIdType: 'CC'
          },
          shippingAddress: {
            addressLine1: '${jsonEncode(direccionCliente).replaceAll('"', '')}',
            city: '${jsonEncode(ciudadCliente).replaceAll('"', '')}',
            phoneNumber: '${jsonEncode(telefonoCliente).replaceAll('"', '')}',
            region: '${jsonEncode(regionCliente).replaceAll('"', '')}',
            country: 'CO'
          }
        });

        window.addEventListener('message', function(e) {
          try {
            var data = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
            if (data && (data.event === 'wompi:transaction_completed' || data.type === 'WOMPI_TRANSACTION_UPDATED')) {
              var t = data.data || data.transaction;
              if (window.WompiChannel && t) {
                window.WompiChannel.postMessage(JSON.stringify({
                  id: t.id || null,
                  status: t.status || 'APPROVED',
                  payment_method_type: t.payment_method_type || null
                }));
              }
            }
          } catch (_) {}
        });

        checkout.open(function ( result ) {
          var transaction = result ? result.transaction : null;
          if (window.WompiChannel) {
            window.WompiChannel.postMessage(JSON.stringify({
              id: transaction ? transaction.id : null,
              status: transaction ? transaction.status : 'CANCELLED',
              payment_method_type: transaction ? transaction.payment_method_type : null
            }));
          }
        });
      } catch (err) {
        if (window.WompiChannel) {
          window.WompiChannel.postMessage(JSON.stringify({
            error: err.toString()
          }));
        }
      }
    });
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(FashionColors.fondoClaro)
      ..addJavaScriptChannel(
        'WompiChannel',
        onMessageReceived: (JavaScriptMessage msg) {
          try {
            final data = jsonDecode(msg.message);
            if (data is Map<String, dynamic>) {
              final id = data['id']?.toString();
              final status = data['status']?.toString();
              final metodo = data['payment_method_type']?.toString();
              if (id != null && id.isNotEmpty) {
                Navigator.of(context).pop(_ModalWompiResult(
                  transaccionId: id,
                  status: status,
                  metodoPago: metodo,
                ));
                return;
              }
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            final uri = Uri.tryParse(url);
            if (uri != null) {
              final scheme = uri.scheme.toLowerCase();
              final host = uri.host.toLowerCase();

              // Interceptar retorno al comercio (botón de Wompi "Volver al comercio")
              final esRetornoComercio = scheme == 'fashionstyle' ||
                  host.contains('retorno-pago') ||
                  url.contains('retorno-pago') ||
                  (url.contains('id=') && (url.contains('env=') || url.contains('status=')));

              if (esRetornoComercio) {
                final id = uri.queryParameters['id'] ??
                    uri.queryParameters['transaccion_id'] ??
                    uri.queryParameters['transaction_id'];
                final status = uri.queryParameters['status'] ?? uri.queryParameters['env'];

                Navigator.of(context).pop(_ModalWompiResult(
                  transaccionId: id,
                  status: status,
                  metodoPago: 'WOMPI',
                ));
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _cargando = false);
          },
        ),
      )
      ..loadHtmlString(htmlContent, baseUrl: 'https://checkout.wompi.co');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Barra superior de la pasarela en Nocturnal Dark #14161F
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: FashionColors.inkPrimary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                // Pill Slate de Pago Seguro
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: FashionColors.slateAccent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Pago Seguro',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wompi · Bancolombia',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: Colors.white70),
                  tooltip: 'Cerrar pasarela',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Indicador de carga superior Terracotta
          if (_cargando)
            const LinearProgressIndicator(
              color: FashionColors.brandAccent,
              backgroundColor: FashionColors.inkPrimary,
              minHeight: 3,
            ),
          // WebView con el widget
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
