// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/production/calculator_dataset.dart';
import 'package:fashion_style_mobile/data/models/production/formula_consumption_model.dart';
import 'package:fashion_style_mobile/data/models/production/production_formula_model.dart';
import 'package:fashion_style_mobile/data/models/production/raw_material_model.dart';

class ProductionService {
  static final ProductionService _instance = ProductionService._internal();
  static ProductionService get instance => _instance;

  ProductionService._internal();

  List<Map<String, dynamic>> _extraerLista(dynamic respuesta) {
    final datos = ApiResponseParser.extractData(respuesta);
    if (datos is List) {
      return datos.whereType<Map<String, dynamic>>().toList();
    }
    if (datos is Map<String, dynamic> && datos['data'] is List) {
      return (datos['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  // Materias Primas
  Future<List<Map<String, dynamic>>> listarMateriasPrimas([Map<String, dynamic>? params]) async {
    final response = await ApiClient.instance.dio.get('/materias-primas', queryParameters: params);
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> crearMateriaPrima(Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.post('/materias-primas', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> actualizarMateriaPrima(int id, Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.put('/materias-primas/$id', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> eliminarMateriaPrima(int id) async {
    await ApiClient.instance.dio.delete('/materias-primas/$id');
  }

  // Unidades de Medida
  Future<List<Map<String, dynamic>>> listarUnidadesMedida([Map<String, dynamic>? params]) async {
    final response = await ApiClient.instance.dio.get('/unidades-medida', queryParameters: params);
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> crearUnidadMedida(Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.post('/unidades-medida', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> actualizarUnidadMedida(int id, Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.put('/unidades-medida/$id', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> eliminarUnidadMedida(int id) async {
    await ApiClient.instance.dio.delete('/unidades-medida/$id');
  }

  // Proveedores
  Future<List<Map<String, dynamic>>> listarProveedores([Map<String, dynamic>? params]) async {
    final response = await ApiClient.instance.dio.get('/proveedores', queryParameters: params);
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> crearProveedor(Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.post('/proveedores', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> actualizarProveedor(int id, Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.put('/proveedores/$id', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> eliminarProveedor(int id) async {
    await ApiClient.instance.dio.delete('/proveedores/$id');
  }

  // Fórmulas de Producción
  Future<List<Map<String, dynamic>>> listarFormulas([Map<String, dynamic>? params]) async {
    final response = await ApiClient.instance.dio.get('/formulas-produccion', queryParameters: params);
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> crearFormula(Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.post('/formulas-produccion', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> crearFormulaLote(Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.post('/formulas-produccion/lote', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> actualizarFormula(int id, Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.put('/formulas-produccion/$id', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> eliminarFormula(int id) async {
    await ApiClient.instance.dio.delete('/formulas-produccion/$id');
  }

  // Órdenes de Producción
  Future<List<Map<String, dynamic>>> listarOrdenesProduccion([Map<String, dynamic>? params]) async {
    final response = await ApiClient.instance.dio.get('/ordenes-produccion', queryParameters: params);
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> crearOrdenProduccion(Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.post('/ordenes-produccion', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> actualizarOrdenProduccion(int id, Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.put('/ordenes-produccion/$id', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> completarOrdenProduccion(int id, [Map<String, dynamic> payload = const {}]) async {
    final response = await ApiClient.instance.dio.post('/ordenes-produccion/$id/completar', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> cancelarOrdenProduccion(int id, [String? notas]) async {
    final response = await ApiClient.instance.dio.put('/ordenes-produccion/$id', data: {
      'estado': 'cancelada',
      if (notas != null && notas.isNotEmpty) 'notas': notas,
    });
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> eliminarOrdenProduccion(int id) async {
    await ApiClient.instance.dio.delete('/ordenes-produccion/$id');
  }

  Future<List<Map<String, dynamic>>> obtenerVariantesProducto(int productoId) async {
    try {
      final response = await ApiClient.instance.dio.get('/productos/$productoId');
      final data = ApiResponseParser.extractData(response);
      if (data is Map<String, dynamic>) {
        final vars = data['variantes'];
        if (vars is List) {
          return vars.whereType<Map<String, dynamic>>().toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // Dataset para la Calculadora de Costos
  Future<CalculatorDataset> cargarDatosCalculadora() async {
    final resultados = await Future.wait<Response<dynamic>>([
      ApiClient.instance.dio.get('/materias-primas'),
      ApiClient.instance.dio.get('/formulas-produccion'),
      ApiClient.instance.dio.get('/productos'),
      ApiClient.instance.dio.get('/unidades-medida').catchError(
            (_) => Response(
              requestOptions: RequestOptions(path: '/unidades-medida'),
              data: const [],
            ),
          ),
    ]);

    final materiasRaw = _extraerLista(resultados[0]);
    final formulasRaw = _extraerLista(resultados[1]);
    final productosRaw = _extraerLista(resultados[2]);
    final unidadesRaw = _extraerLista(resultados[3]);

    // 1. Indexar unidades
    final Map<int, Map<String, String>> unidadesPorId = {};
    for (final u in unidadesRaw) {
      final id = JsonParser.toInt(u['id'] ?? u['id_unidad']);
      final nombre = JsonParser.toStr(u['nombre']);
      final abrev = JsonParser.toStr(u['abreviatura'], nombre);
      unidadesPorId[id] = {'nombre': nombre, 'abreviatura': abrev};
    }

    // 2. Indexar productos (variante S o primera)
    final Map<int, Map<String, dynamic>> productosPorId = {};
    for (final p in productosRaw) {
      final id = JsonParser.toInt(p['id_producto'] ?? p['id']);
      final variantes = p['variantes'] is List ? (p['variantes'] as List).whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
      Map<String, dynamic>? varianteS;
      for (final v in variantes) {
        if (v['talla']?.toString() == 'S') {
          varianteS = v;
          break;
        }
      }
      varianteS ??= variantes.isNotEmpty ? variantes.first : null;

      final precioVenta = JsonParser.toDouble(
        varianteS?['precio_venta'] ?? p['precio_venta'] ?? p['precio_base'],
      );

      productosPorId[id] = {
        'nombre': JsonParser.toStr(p['nombre']),
        'precio_venta': precioVenta,
      };
    }

    // 3. Normalizar materias primas
    final List<RawMaterialModel> materiasNormalizadas = [];
    final Map<int, RawMaterialModel> materiasPorId = {};

    for (final m in materiasRaw) {
      final id = JsonParser.toInt(m['id_material'] ?? m['id']);
      final unidadMedidaMap = m['unidad_medida'] is Map ? m['unidad_medida'] as Map : null;
      final unidadId = JsonParser.toInt(m['unidad_medida_id']);

      final unidadAbrev = JsonParser.toStr(
        m['unidad'] ??
            unidadMedidaMap?['abreviatura'] ??
            unidadesPorId[unidadId]?['abreviatura'] ??
            unidadesPorId[unidadId]?['nombre'],
        'un',
      );

      final material = RawMaterialModel.fromJson(m, unidadAbrev);
      materiasNormalizadas.add(material);
      materiasPorId[id] = material;
    }

    // 4. Agrupar fórmulas
    final bool yaAgrupadas = formulasRaw.any((f) => f['consumos'] is List);
    final List<ProductionFormulaModel> formulasAgrupadas = [];

    if (yaAgrupadas) {
      for (final f in formulasRaw) {
        final prodId = JsonParser.toInt(f['producto_id'] ?? f['id'] ?? f['id_formula']);
        final prod = productosPorId[prodId];
        final rawConsumos = f['consumos'] is List ? f['consumos'] as List : [];
        final List<FormulaConsumptionModel> consumos = [];

        for (final c in rawConsumos) {
          if (c is Map<String, dynamic>) {
            final mId = JsonParser.toInt(c['materia_prima_id']);
            final materia = materiasPorId[mId];
            consumos.add(
              FormulaConsumptionModel(
                materiaPrimaId: mId,
                cantidad: JsonParser.toDouble(c['cantidad']),
                insumoNombre: JsonParser.toStr(materia?.nombre ?? c['insumo_nombre'], 'Insumo'),
                insumoClasificacion: JsonParser.toStr(materia?.clasificacion ?? c['insumo_clasificacion'], 'Insumo'),
                insumoUnidad: JsonParser.toStr(c['unidad'] ?? materia?.unidad, 'un'),
                insumoCosto: JsonParser.toDouble(materia?.costoUnitario ?? c['costo_unitario_estimado']),
                insumoStock: JsonParser.toDouble(materia?.stockActual),
                desperdicioPorcentaje: JsonParser.toDouble(c['desperdicio_porcentaje']),
              ),
            );
          }
        }

        formulasAgrupadas.add(
          ProductionFormulaModel(
            id: prodId,
            idFormula: JsonParser.toInt(f['id_formula'], prodId),
            productoId: prodId,
            nombre: JsonParser.toStr(f['nombre'] ?? prod?['nombre'], 'Producto #$prodId'),
            precioVenta: JsonParser.toDouble(f['precio_venta'] ?? prod?['precio_venta']),
            manoObraSugerida: JsonParser.toDouble(f['mano_obra_sugerida'], 35000),
            desperdicioSugerido: JsonParser.toDouble(f['desperdicio_sugerido'], 0),
            consumos: consumos,
          ),
        );
      }
    } else {
      final Map<int, Map<String, dynamic>> mapaFormulas = {};

      for (final fila in formulasRaw) {
        final prodId = JsonParser.toInt(fila['producto_id']);
        if (prodId <= 0) continue;

        final prod = productosPorId[prodId];
        final mId = JsonParser.toInt(fila['materia_prima_id']);
        final materia = materiasPorId[mId];
        if (materia == null) continue;

        if (!mapaFormulas.containsKey(prodId)) {
          mapaFormulas[prodId] = {
            'id': prodId,
            'id_formula': JsonParser.toInt(fila['id_formula'], prodId),
            'producto_id': prodId,
            'nombre': JsonParser.toStr(prod?['nombre'], 'Producto #$prodId'),
            'precio_venta': JsonParser.toDouble(prod?['precio_venta']),
            'mano_obra_sugerida': 35000.0,
            'desperdicio_sugerido': 0.0,
            'consumos': <FormulaConsumptionModel>[],
          };
        }

        (mapaFormulas[prodId]!['consumos'] as List<FormulaConsumptionModel>).add(
          FormulaConsumptionModel(
            materiaPrimaId: materia.id,
            cantidad: JsonParser.toDouble(fila['cantidad']),
            insumoNombre: materia.nombre,
            insumoClasificacion: materia.clasificacion,
            insumoUnidad: materia.unidad,
            insumoCosto: materia.costoUnitario,
            insumoStock: materia.stockActual,
            desperdicioPorcentaje: JsonParser.toDouble(fila['desperdicio_porcentaje']),
          ),
        );
      }

      for (final entry in mapaFormulas.values) {
        formulasAgrupadas.add(
          ProductionFormulaModel(
            id: entry['id'] as int,
            idFormula: entry['id_formula'] as int,
            productoId: entry['producto_id'] as int,
            nombre: entry['nombre'] as String,
            precioVenta: entry['precio_venta'] as double,
            manoObraSugerida: entry['mano_obra_sugerida'] as double,
            desperdicioSugerido: entry['desperdicio_sugerido'] as double,
            consumos: entry['consumos'] as List<FormulaConsumptionModel>,
          ),
        );
      }
    }

    return CalculatorDataset(
      materiasPrimas: materiasNormalizadas,
      formulas: formulasAgrupadas,
    );
  }
}
