// @source-mirror: src/services/wompiServicio.js
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';

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

class WompiService {
  static final WompiService _instance = WompiService._internal();
  static WompiService get instance => _instance;

  WompiService._internal();

  Future<WompiCheckoutData> crearCheckout(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> cliente,
  ) async {
    final lineas = items.map((item) {
      final rawVar = item['id_variante'] ?? item['varianteId'] ?? item['producto_variante_id'];
      final idVariante = JsonParser.toInt(rawVar);

      if (idVariante <= 0) {
        throw ArgumentError('Un producto de la bolsa no tiene una variante válida.');
      }

      final rawCant = JsonParser.toInt(item['cantidad'], 1);
      final cantidad = rawCant < 1 ? 1 : rawCant;

      return {
        'id_variante': idVariante,
        'cantidad': cantidad,
      };
    }).toList();

    final clientePayload = {
      'nombre': JsonParser.toStr(cliente['nombre']),
      'telefono': JsonParser.toStr(cliente['telefono']),
      'ciudad': JsonParser.toStr(cliente['ciudad']),
      'departamento': JsonParser.toStr(cliente['departamento'] ?? cliente['ciudad']),
      'direccion': JsonParser.toStr(cliente['direccion']),
    };

    final response = await ApiClient.instance.dio.post(
      '/checkout',
      data: {
        'items': lineas,
        'cliente': clientePayload,
      },
    );

    final data = ApiResponseParser.extractData(response);
    if (data is Map<String, dynamic>) {
      return WompiCheckoutData.fromJson(data);
    }
    throw StateError('Respuesta inesperada al inicializar checkout de Wompi.');
  }

  Future<WompiCheckoutData> reanudarCheckout(String referencia) async {
    final encoded = Uri.encodeComponent(referencia);
    final response = await ApiClient.instance.dio.post('/checkout/$encoded/reanudar');
    final data = ApiResponseParser.extractData(response);
    if (data is Map<String, dynamic>) {
      return WompiCheckoutData.fromJson(data);
    }
    throw StateError('Respuesta inesperada al reanudar checkout de Wompi.');
  }

  Future<Map<String, dynamic>> cancelarCheckout(String referencia) async {
    final encoded = Uri.encodeComponent(referencia);
    final response = await ApiClient.instance.dio.post('/checkout/$encoded/cancelar');
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> confirmarCheckout(
    String referencia,
    String transaccionId,
  ) async {
    final encoded = Uri.encodeComponent(referencia);
    final response = await ApiClient.instance.dio.post(
      '/checkout/$encoded/confirmar',
      data: {'transaccion_id': transaccionId},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>?> consultarTransaccionWompi(
    String transaccionId, [
    String? publicKey,
  ]) async {
    final id = transaccionId.trim();
    if (id.isEmpty) return null;

    final key = publicKey ?? const String.fromEnvironment('WOMPI_PUBLIC_KEY', defaultValue: '');
    final esSandbox = key.isEmpty || key.startsWith('pub_test_');
    final host = esSandbox ? 'https://sandbox.wompi.co' : 'https://production.wompi.co';

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: key.isNotEmpty ? {'Authorization': 'Bearer $key'} : {},
        ),
      );

      final response = await dio.get('$host/v1/transactions/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
