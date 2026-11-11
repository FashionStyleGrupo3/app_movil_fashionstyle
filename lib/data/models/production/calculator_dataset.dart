// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/error_message.dart';
import 'package:fashion_style_mobile/core/utils/production_helpers.dart';
import 'package:fashion_style_mobile/data/models/production/formula_consumption_model.dart';
import 'package:fashion_style_mobile/data/models/production/production_formula_model.dart';
import 'package:fashion_style_mobile/data/models/production/raw_material_model.dart';
import 'package:fashion_style_mobile/data/services/production_service.dart';

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
