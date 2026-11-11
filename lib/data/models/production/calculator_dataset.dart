// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:fashion_style_mobile/data/models/production/production_formula_model.dart';
import 'package:fashion_style_mobile/data/models/production/raw_material_model.dart';

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
