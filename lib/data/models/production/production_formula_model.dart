// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/production/formula_consumption_model.dart';

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
