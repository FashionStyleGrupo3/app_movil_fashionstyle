import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_style_mobile/data/models/payment/wompi_checkout_data.dart';
import 'package:fashion_style_mobile/presentation/widgets/payment/wompi_checkout_modal.dart';

void main() {
  group('WompiCheckoutData Tests', () {
    test('Parsea correctamente JSON del backend Laravel', () {
      final json = {
        'referencia': 'FS-261110-XYZ123',
        'monto_total': 185000.0,
        'monto_centavos': 18500000,
        'moneda': 'COP',
        'firma_integridad': 'abc123hash',
        'public_key': 'pub_test_wompiKey',
        'simulado': false,
      };

      final data = WompiCheckoutData.fromJson(json);

      expect(data.referencia, 'FS-261110-XYZ123');
      expect(data.montoTotal, 185000.0);
      expect(data.montoCentavos, 18500000);
      expect(data.moneda, 'COP');
      expect(data.firmaIntegridad, 'abc123hash');
      expect(data.publicKey, 'pub_test_wompiKey');
      expect(data.simulado, false);
    });

    test('WompiPaymentOutcome calcula esExitoso adecuadamente', () {
      const outcomeAprobado = WompiPaymentOutcome(
        status: 'aprobado',
        referencia: 'FS-TEST',
        transaccionId: '12345-67890',
        monto: 50000,
      );
      expect(outcomeAprobado.esExitoso, true);

      const outcomePendiente = WompiPaymentOutcome(
        status: 'pendiente',
        referencia: 'FS-TEST',
        monto: 50000,
      );
      expect(outcomePendiente.esExitoso, false);

      const outcomeCancelado = WompiPaymentOutcome(
        status: 'cancelado',
        referencia: 'FS-TEST',
        monto: 50000,
      );
      expect(outcomeCancelado.esExitoso, false);
    });

    test('Intercepción de deep link y query params de Wompi', () {
      final uri = Uri.parse('fashionstyle://retorno-pago?id=tx_998877&env=test');
      expect(uri.scheme, 'fashionstyle');
      expect(uri.host, 'retorno-pago');
      expect(uri.queryParameters['id'], 'tx_998877');
      expect(uri.queryParameters['env'], 'test');
    });
  });
}
