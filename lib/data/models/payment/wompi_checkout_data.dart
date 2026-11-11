// @source-mirror: src/services/wompiServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class WompiCheckoutData {
  final String referencia;
  final double montoTotal;
  final int montoCentavos;
  final String moneda;
  final String firmaIntegridad;
  final String publicKey;
  final String? expiraEn;
  final bool simulado;

  const WompiCheckoutData({
    required this.referencia,
    required this.montoTotal,
    required this.montoCentavos,
    required this.moneda,
    required this.firmaIntegridad,
    required this.publicKey,
    this.expiraEn,
    required this.simulado,
  });

  factory WompiCheckoutData.fromJson(Map<String, dynamic> map) {
    const defaultPublicKey = String.fromEnvironment('WOMPI_PUBLIC_KEY', defaultValue: '');
    final pubKey = JsonParser.toStr(map['public_key'], defaultPublicKey);

    return WompiCheckoutData(
      referencia: JsonParser.toStr(map['referencia']),
      montoTotal: JsonParser.toDouble(map['monto_total']),
      montoCentavos: JsonParser.toInt(map['monto_centavos']),
      moneda: JsonParser.toStr(map['moneda'], 'COP'),
      firmaIntegridad: JsonParser.toStr(map['firma_integridad']),
      publicKey: pubKey,
      expiraEn: map['expira_en']?.toString(),
      simulado: JsonParser.toBool(map['simulado']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referencia': referencia,
      'monto_total': montoTotal,
      'monto_centavos': montoCentavos,
      'moneda': moneda,
      'firma_integridad': firmaIntegridad,
      'public_key': publicKey,
      'expira_en': expiraEn,
      'simulado': simulado,
    };
  }
}
