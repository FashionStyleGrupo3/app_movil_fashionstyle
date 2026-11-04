// @source-mirror: src/services/wompiServicio.js
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/fashion_theme.dart';
import '../../data/services/wompi_service.dart';

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
    bool cancelarAlCerrar = true,
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
      enableDrag: false,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WompiWebViewSheet(
        pedido: pedido,
        cliente: cliente,
      ),
    );

    // 4. Si el usuario cerró el modal sin completar transacción
    if (resultadoModal == null || resultadoModal.transaccionId == null) {
      if (cancelarAlCerrar) {
        try {
          await WompiService.instance.cancelarCheckout(pedido.referencia);
        } catch (_) {}
        return WompiPaymentOutcome(
          status: 'cancelado',
          referencia: pedido.referencia,
          monto: pedido.montoTotal,
          mensaje: 'Pago cancelado por el usuario.',
        );
      } else {
        return WompiPaymentOutcome(
          status: 'pendiente',
          referencia: pedido.referencia,
          monto: pedido.montoTotal,
          mensaje: 'El pago no se completó en la ventana del proveedor.',
        );
      }
    }

    // 5. Transacción completada en el widget: confirmación contra el backend
    final transaccionId = resultadoModal.transaccionId!;
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
        metodoPago: resultadoModal.metodoPago ?? confirmacion['metodo_pago']?.toString() ?? 'WOMPI',
        monto: pedido.montoTotal,
        mensaje: confirmacion['mensaje']?.toString(),
      );
    } catch (e) {
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
      background: #faf7f5;
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
      color: #333;
    }
    .spinner {
      border: 4px solid #f3f3f3;
      border-top: 4px solid #f43f5e;
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

        checkout.open(function ( result ) {
          var transaction = result.transaction;
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
              Navigator.of(context).pop(_ModalWompiResult(
                transaccionId: id,
                status: status,
                metodoPago: metodo,
              ));
            }
          } catch (_) {
            Navigator.of(context).pop(const _ModalWompiResult());
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _cargando = false);
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Barra superior de la pasarela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: FashionColors.grisBorde)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 18, color: FashionColors.verdeExito),
                const SizedBox(width: 8),
                const Text(
                  'Pago Seguro Wompi Bancolombia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FashionColors.textoOscuro),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Cancelar pago',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Indicador de carga superior si el webview aún está procesando
          if (_cargando)
            const LinearProgressIndicator(
              color: FashionColors.rosaCorporativo,
              backgroundColor: FashionColors.rosaSuave,
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
