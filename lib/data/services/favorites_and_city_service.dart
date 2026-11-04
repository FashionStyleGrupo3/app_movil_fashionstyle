// @source-mirror: src/services/favoritosServicio.js, src/utils/Validarciudad.js
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  static FavoritesService get instance => _instance;

  FavoritesService._internal();

  static const String ruta = '/favoritos';

  List<int> _leerIds(dynamic response) {
    final raw = ApiResponseParser.extractData(response);
    if (raw is Map<String, dynamic> && raw['ids'] is List) {
      return (raw['ids'] as List)
          .map((e) => JsonParser.toInt(e))
          .where((id) => id > 0)
          .toList();
    }
    if (raw is List) {
      return raw
          .map((e) => JsonParser.toInt(e))
          .where((id) => id > 0)
          .toList();
    }
    return [];
  }

  Future<List<int>> listarFavoritosApi() async {
    final response = await ApiClient.instance.dio.get(ruta);
    return _leerIds(response);
  }

  Future<List<int>> agregarFavoritoApi(int productoId) async {
    final response = await ApiClient.instance.dio.post(
      ruta,
      data: {'producto_id': productoId},
    );
    return _leerIds(response);
  }

  Future<List<int>> quitarFavoritoApi(int productoId) async {
    final response = await ApiClient.instance.dio.delete('$ruta/$productoId');
    return _leerIds(response);
  }

  Future<List<int>> sincronizarFavoritosApi(List<int> ids) async {
    final response = await ApiClient.instance.dio.post(
      '$ruta/sincronizar',
      data: {'ids': ids},
    );
    return _leerIds(response);
  }
}

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
