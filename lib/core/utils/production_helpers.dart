// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/error_message.dart';
import 'package:fashion_style_mobile/data/models/production/calculator_dataset.dart';
import 'package:fashion_style_mobile/data/models/production/formula_consumption_model.dart';
import 'package:fashion_style_mobile/data/models/production/production_formula_model.dart';
import 'package:fashion_style_mobile/data/models/production/raw_material_model.dart';
import 'package:fashion_style_mobile/data/services/production_service.dart';

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
