// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class Category {
  final int idCategoria;
  final String nombre;
  final String descripcion;
  final bool activo;
  final Map<String, dynamic> original;

  const Category({
    required this.idCategoria,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    this.original = const {},
  });

  factory Category.fromJson(Map<String, dynamic> map) {
    return Category(
      idCategoria: JsonParser.toInt(map['id_categoria'] ?? map['id']),
      nombre: JsonParser.toStr(map['nombre']),
      descripcion: JsonParser.toStr(map['descripcion']),
      activo: map['activo'] == null ? true : JsonParser.toBool(map['activo']),
      original: map,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
    };
  }
}
