// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

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
