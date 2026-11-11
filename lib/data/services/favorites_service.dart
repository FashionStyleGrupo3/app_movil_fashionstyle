// @source-mirror: src/services/favoritosServicio.js, src/utils/Validarciudad.js
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

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
