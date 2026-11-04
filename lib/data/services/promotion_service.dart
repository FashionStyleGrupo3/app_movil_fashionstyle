// @source-mirror: src/services/promocionServicio.js, src/composables/usePromociones.js
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';
import '../models/product_models.dart';

class PromotionService {
  static final PromotionService _instance = PromotionService._internal();
  static PromotionService get instance => _instance;

  PromotionService._internal();

  static const String ruta = '/promociones';
  static const int ttlCacheMs = 60000;
  static const int porcentajeMaximo = 90;

  List<Promotion>? _cacheVigentes;
  int _cacheMarca = 0;
  Future<List<Promotion>>? _peticionEnCurso;

  bool estaVigente(Promotion promo, [DateTime? ahora]) {
    if (!promo.activa || promo.valor <= 0) return false;

    DateTime? inicio;
    if (promo.fechaInicio != null && promo.fechaInicio!.isNotEmpty) {
      inicio = DateTime.tryParse(promo.fechaInicio!);
    }

    DateTime? fin;
    if (promo.fechaFin != null && promo.fechaFin!.isNotEmpty) {
      fin = DateTime.tryParse(promo.fechaFin!);
      if (fin != null && promo.fechaFin!.trim().length <= 10) {
        fin = DateTime(fin.year, fin.month, fin.day, 23, 59, 59, 999);
      }
    }

    final now = ahora ?? DateTime.now();
    if (inicio != null && now.isBefore(inicio)) return false;
    if (fin != null && now.isAfter(fin)) return false;

    return true;
  }

  Map<String, dynamic> aPayloadBackend(
    Map<String, dynamic> form, {
    int? currentUserId,
  }) {
    final int? prodId;
    if (form['alcance'] == 'prenda') {
      final raw = form['idProducto'] ?? form['producto_id'];
      prodId = raw != null ? JsonParser.toInt(raw) : null;
    } else {
      final raw = form['producto_id'];
      prodId = raw != null ? JsonParser.toInt(raw) : null;
    }

    return {
      'nombre': JsonParser.toStr(form['nombre']),
      'descripcion': form['descripcion'] != null && form['descripcion'].toString().trim().isNotEmpty
          ? form['descripcion'].toString().trim()
          : null,
      'tipo': form['tipo'] == 'monto' ? 'monto' : 'porcentaje',
      'valor': JsonParser.toDouble(form['valor']),
      'producto_id': prodId != null && prodId > 0 ? prodId : null,
      'fecha_inicio': form['fechaInicio'] ?? form['fecha_inicio'],
      'fecha_fin': form['fechaFin'] ?? form['fecha_fin'],
      'activa': form['activa'] == null ? true : JsonParser.toBool(form['activa']),
      'usuario_id': currentUserId ?? JsonParser.toInt(form['usuario_id'], 1),
    };
  }

  void invalidarCachePromociones() {
    _cacheVigentes = null;
    _cacheMarca = 0;
  }

  Future<List<Promotion>> listarPromociones([Map<String, dynamic>? params]) async {
    final response = await ApiClient.instance.dio.get(ruta, queryParameters: params);
    final rawData = ApiResponseParser.extractData(response);

    List<dynamic> list = [];
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData['promociones'] is List) {
        list = rawData['promociones'] as List;
      }
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => Promotion.fromJson(m))
        .toList();
  }

  Future<Promotion> crearPromocion(
    Map<String, dynamic> form, {
    int? currentUserId,
  }) async {
    final payload = aPayloadBackend(form, currentUserId: currentUserId);
    final response = await ApiClient.instance.dio.post(ruta, data: payload);
    invalidarCachePromociones();
    final data = ApiResponseParser.extractData(response);
    return Promotion.fromJson(data is Map<String, dynamic> ? data : payload);
  }

  Future<Promotion> actualizarPromocion(
    int id,
    Map<String, dynamic> form, {
    int? currentUserId,
  }) async {
    final payload = aPayloadBackend(form, currentUserId: currentUserId);
    final response = await ApiClient.instance.dio.put('$ruta/$id', data: payload);
    invalidarCachePromociones();
    final data = ApiResponseParser.extractData(response);
    return Promotion.fromJson(data is Map<String, dynamic> ? data : payload);
  }

  Future<void> eliminarPromocion(int id) async {
    await ApiClient.instance.dio.delete('$ruta/$id');
    invalidarCachePromociones();
  }

  Future<List<Promotion>> obtenerPromocionesVigentes({bool forzar = false}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!forzar && _cacheVigentes != null && (nowMs - _cacheMarca < ttlCacheMs)) {
      return _cacheVigentes!;
    }

    if (!forzar && _peticionEnCurso != null) {
      return _peticionEnCurso!;
    }

    _peticionEnCurso = listarPromociones({'vigentes': 1}).then((lista) {
      _cacheVigentes = lista.where((p) => estaVigente(p)).toList();
      _cacheMarca = DateTime.now().millisecondsSinceEpoch;
      return _cacheVigentes!;
    }).whenComplete(() {
      _peticionEnCurso = null;
    });

    return _peticionEnCurso!;
  }

  PriceInfo calcularPrecioPromocional(
    Product? producto,
    num precioBase,
    List<Promotion> promociones,
  ) {
    final base = precioBase.toDouble() > 0 ? precioBase.toDouble() : 0.0;

    // Si el backend ya calculó un precio con descuento menor a la base, se respeta
    final precioBack = producto?.precioFinalBackend;
    if (precioBack != null && precioBack < base) {
      final ahorro = base - precioBack;
      return PriceInfo(
        precioOriginal: base,
        precioFinal: precioBack,
        ahorro: ahorro,
        porcentaje: base > 0 ? ((ahorro / base) * 100).round() : 0,
        promocion: const Promotion(
          nombre: 'Promoción',
          descripcion: '',
          tipo: 'monto',
          valor: 0,
          activa: true,
          original: {},
        ),
      );
    }

    final prodId = producto?.idProducto;
    final aplicables = promociones.where((p) {
      if (!estaVigente(p)) return false;
      return p.idProducto == null || (prodId != null && p.idProducto == prodId);
    }).toList();

    Promotion? mejor;
    double mejorAhorro = 0;

    for (final promo in aplicables) {
      double ahorro = 0;
      if (promo.tipo == 'monto') {
        ahorro = promo.valor > base ? base : promo.valor;
      } else {
        final porcentaje = promo.valor.clamp(0.0, porcentajeMaximo.toDouble());
        ahorro = ((base * porcentaje) / 100).roundToDouble();
      }

      if (ahorro > mejorAhorro) {
        mejor = promo;
        mejorAhorro = ahorro;
      }
    }

    final precioFinal = base - mejorAhorro;

    return PriceInfo(
      precioOriginal: base,
      precioFinal: precioFinal < 0 ? 0.0 : precioFinal,
      ahorro: mejorAhorro,
      porcentaje: base > 0 ? ((mejorAhorro / base) * 100).round() : 0,
      promocion: mejor,
    );
  }
}
