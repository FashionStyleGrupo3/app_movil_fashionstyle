// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class Promotion {
  final int? id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final double valor;
  final int? idProducto;
  final String? nombreProducto;
  final String? fechaInicio;
  final String? fechaFin;
  final bool activa;
  final Map<String, dynamic> original;

  const Promotion({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    this.idProducto,
    this.nombreProducto,
    this.fechaInicio,
    this.fechaFin,
    required this.activa,
    required this.original,
  });

  factory Promotion.fromJson(Map<String, dynamic> map) {
    final tipoCrudo = JsonParser.toStr(map['tipo_descuento'] ?? map['tipo'] ?? 'porcentaje').toLowerCase();
    final tipo = ['monto', 'valor', 'fijo'].contains(tipoCrudo) ? 'monto' : 'porcentaje';

    final prodMap = map['producto'] is Map<String, dynamic> ? map['producto'] as Map<String, dynamic> : null;
    final idProdRaw = map['id_producto'] ?? map['producto_id'] ?? prodMap?['id_producto'] ?? prodMap?['id'];
    final idProducto = idProdRaw != null ? JsonParser.toInt(idProdRaw) : null;

    final nombreProdRaw = prodMap?['nombre'] ?? map['nombre_producto'];
    final nombreProducto = nombreProdRaw != null ? JsonParser.toStr(nombreProdRaw) : null;

    final valor = JsonParser.toDouble(map['valor'] ?? map['porcentaje_descuento'] ?? map['descuento']);
    final activa = JsonParser.toBool(map['activa'] ?? map['estado'], true);

    final rawId = map['id_promocion'] ?? map['id'];

    return Promotion(
      id: rawId != null ? JsonParser.toInt(rawId) : null,
      nombre: JsonParser.toStr(map['nombre'] ?? map['titulo'], 'Promoción'),
      descripcion: JsonParser.toStr(map['descripcion']),
      tipo: tipo,
      valor: valor,
      idProducto: idProducto != null && idProducto > 0 ? idProducto : null,
      nombreProducto: nombreProducto,
      fechaInicio: map['fecha_inicio']?.toString(),
      fechaFin: map['fecha_fin']?.toString(),
      activa: activa,
      original: map,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id_promocion': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
      'valor': valor,
      'id_producto': idProducto,
      'nombre_producto': nombreProducto,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'activa': activa,
    };
  }
}
