// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/production_helpers.dart';
import 'package:fashion_style_mobile/data/models/production/calculator_dataset.dart';
import 'package:fashion_style_mobile/data/models/production/formula_consumption_model.dart';
import 'package:fashion_style_mobile/data/models/production/production_formula_model.dart';
import 'package:fashion_style_mobile/data/models/production/raw_material_model.dart';
import 'package:fashion_style_mobile/data/services/production_service.dart';

String mensajeError(dynamic error, [String defecto = 'Ocurrió un error inesperado.']) {
  return ApiClient.obtenerMensajeError(error, defecto);
}

// --- SERVICIO DE PRODUCCIÓN ---
