// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

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
