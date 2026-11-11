// @source-mirror: src/services/favoritosServicio.js, src/utils/Validarciudad.js
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class CityValidationService {
  static final CityValidationService _instance = CityValidationService._internal();
  static CityValidationService get instance => _instance;

  CityValidationService._internal();

  bool ciudadTieneFormatoValido(String? ciudad) {
    final valor = (ciudad ?? '').trim();
    if (valor.length < 3 || valor.length > 100) return false;
    return RegExp(r"^[\p{L}][\p{L}\s.'-]*$", unicode: true).hasMatch(valor);
  }

  Future<List<String>> buscarCiudades(String texto) async {
    try {
      final response = await ApiClient.instance.dio.get(
        '/ciudades/buscar',
        queryParameters: {'q': texto},
      );
      final data = ApiResponseParser.extractData(response);
      if (data is List) {
        return data.map((e) => e.toString().trim()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool?> ciudadExiste(String ciudad) async {
    if (!ciudadTieneFormatoValido(ciudad)) return false;
    try {
      final response = await ApiClient.instance.dio.get(
        '/ciudades/existe',
        queryParameters: {'nombre': ciudad.trim()},
      );
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw.containsKey('existe')) {
        return JsonParser.toBool(raw['existe']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
