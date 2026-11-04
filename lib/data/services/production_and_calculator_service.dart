// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';

// --- MODELOS DE CALCULADORA Y PRODUCCIÓN ---

class RawMaterialModel {
  final int id;
  final int idMaterial;
  final String codigo;
  final String nombre;
  final String clasificacion;
  final String unidad;
  final double costoUnitario;
  final double stockActual;
  final double stock;

  const RawMaterialModel({
    required this.id,
    required this.idMaterial,
    required this.codigo,
    required this.nombre,
    required this.clasificacion,
    required this.unidad,
    required this.costoUnitario,
    required this.stockActual,
    required this.stock,
  });

  factory RawMaterialModel.fromJson(Map<String, dynamic> map, [String unidadFallback = 'un']) {
    final id = JsonParser.toInt(map['id_material'] ?? map['id']);
    final stockVal = JsonParser.toDouble(map['stock_actual'] ?? map['stock'] ?? map['Stock']);

    return RawMaterialModel(
      id: id,
      idMaterial: id,
      codigo: JsonParser.toStr(map['codigo']),
      nombre: JsonParser.toStr(map['nombre']),
      clasificacion: JsonParser.toStr(map['clasificacion'], 'Insumo'),
      unidad: JsonParser.toStr(map['unidad'], unidadFallback),
      costoUnitario: JsonParser.toDouble(map['costo_unitario']),
      stockActual: stockVal,
      stock: stockVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_material': idMaterial,
      'codigo': codigo,
      'nombre': nombre,
      'clasificacion': clasificacion,
      'unidad': unidad,
      'costo_unitario': costoUnitario,
      'stock_actual': stockActual,
      'stock': stock,
    };
  }
}

class FormulaConsumptionModel {
  final int materiaPrimaId;
  final double cantidad;
  final String insumoNombre;
  final String insumoClasificacion;
  final String insumoUnidad;
  final double insumoCosto;
  final double insumoStock;
  final double desperdicioPorcentaje;

  const FormulaConsumptionModel({
    required this.materiaPrimaId,
    required this.cantidad,
    required this.insumoNombre,
    required this.insumoClasificacion,
    required this.insumoUnidad,
    required this.insumoCosto,
    required this.insumoStock,
    required this.desperdicioPorcentaje,
  });

  factory FormulaConsumptionModel.fromJson(Map<String, dynamic> map) {
    return FormulaConsumptionModel(
      materiaPrimaId: JsonParser.toInt(map['materia_prima_id']),
      cantidad: JsonParser.toDouble(map['cantidad']),
      insumoNombre: JsonParser.toStr(map['insumo_nombre'], 'Insumo'),
      insumoClasificacion: JsonParser.toStr(map['insumo_clasificacion'], 'Insumo'),
      insumoUnidad: JsonParser.toStr(map['insumo_unidad'], 'un'),
      insumoCosto: JsonParser.toDouble(map['insumo_costo'] ?? map['costo_unitario_estimado']),
      insumoStock: JsonParser.toDouble(map['insumo_stock']),
      desperdicioPorcentaje: JsonParser.toDouble(map['desperdicio_porcentaje']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'materia_prima_id': materiaPrimaId,
      'cantidad': cantidad,
      'insumo_nombre': insumoNombre,
      'insumo_clasificacion': insumoClasificacion,
      'insumo_unidad': insumoUnidad,
      'insumo_costo': insumoCosto,
      'insumo_stock': insumoStock,
      'desperdicio_porcentaje': desperdicioPorcentaje,
    };
  }
}

class ProductionFormulaModel {
  final int id;
  final int idFormula;
  final int productoId;
  final String nombre;
  final double precioVenta;
  final double manoObraSugerida;
  final double desperdicioSugerido;
  final List<FormulaConsumptionModel> consumos;

  const ProductionFormulaModel({
    required this.id,
    required this.idFormula,
    required this.productoId,
    required this.nombre,
    required this.precioVenta,
    required this.manoObraSugerida,
    required this.desperdicioSugerido,
    required this.consumos,
  });

  factory ProductionFormulaModel.fromJson(Map<String, dynamic> map) {
    final prodId = JsonParser.toInt(map['producto_id'] ?? map['id'] ?? map['id_formula']);
    final rawConsumos = map['consumos'];
    final List<FormulaConsumptionModel> items = [];
    if (rawConsumos is List) {
      for (final c in rawConsumos) {
        if (c is Map<String, dynamic>) {
          items.add(FormulaConsumptionModel.fromJson(c));
        }
      }
    }

    return ProductionFormulaModel(
      id: prodId,
      idFormula: JsonParser.toInt(map['id_formula'], prodId),
      productoId: prodId,
      nombre: JsonParser.toStr(map['nombre'], 'Producto #$prodId'),
      precioVenta: JsonParser.toDouble(map['precio_venta']),
      manoObraSugerida: JsonParser.toDouble(map['mano_obra_sugerida'], 35000),
      desperdicioSugerido: JsonParser.toDouble(map['desperdicio_sugerido'], 0),
      consumos: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_formula': idFormula,
      'producto_id': productoId,
      'nombre': nombre,
      'precio_venta': precioVenta,
      'mano_obra_sugerida': manoObraSugerida,
      'desperdicio_sugerido': desperdicioSugerido,
      'consumos': consumos.map((c) => c.toJson()).toList(),
    };
  }
}

class CalculatorDataset {
  final List<RawMaterialModel> materiasPrimas;
  final List<ProductionFormulaModel> formulas;

  const CalculatorDataset({
    required this.materiasPrimas,
    required this.formulas,
  });

  RawMaterialModel? buscarMateriaPorId(int id) {
    for (final m in materiasPrimas) {
      if (m.id == id) return m;
    }
    return null;
  }
}

// --- UTILIDADES ---

String unidadDe(Map<String, dynamic>? materia, List<dynamic> unidades) {
  if (materia == null) return '';
  final relacion = materia['unidad_medida'] ?? materia['unidad'];
  if (relacion is Map && relacion['nombre'] != null) {
    return relacion['nombre'].toString();
  }
  final id = materia['unidad_medida_id'];
  for (final u in unidades) {
    if (u is Map && String.fromCharCode(0) != '' && (u['id']?.toString() == id?.toString())) {
      return u['nombre']?.toString() ?? '';
    }
  }
  return '';
}

String mensajeError(dynamic error, [String defecto = 'Ocurrió un error inesperado.']) {
  return ApiClient.obtenerMensajeError(error, defecto);
}

// --- SERVICIO DE PRODUCCIÓN ---

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
