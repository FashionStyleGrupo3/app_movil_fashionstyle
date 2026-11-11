// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class Catalog {
  final int idCatalogo;
  final String nombre;
  final String descripcion;
  final bool activo;
  final Map<String, dynamic> original;

  const Catalog({
    required this.idCatalogo,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    this.original = const {},
  });

  factory Catalog.fromJson(Map<String, dynamic> map) {
    return Catalog(
      idCatalogo: JsonParser.toInt(map['id_catalogo'] ?? map['id']),
      nombre: JsonParser.toStr(map['nombre']),
      descripcion: JsonParser.toStr(map['descripcion']),
      activo: map['activo'] == null ? true : JsonParser.toBool(map['activo']),
      original: map,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_catalogo': idCatalogo,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
    };
  }
}
