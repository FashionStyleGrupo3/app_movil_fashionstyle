// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_item_detail.dart';

class InvoiceModel {
  final int id;
  final String numero;
  final String? fecha;
  final String estado;
  final int? pedidoId;
  final int? ventaId;
  final String origen;
  final double subtotal;
  final double impuestos;
  final double descuento;
  final double total;
  final String metodoPago;
  final String notas;
  final String clienteNombre;
  final String clienteDocumento;
  final String clienteCorreo;
  final String clienteDireccion;
  final String clienteCiudad;
  final List<InvoiceItemDetail> detalles;
  final Map<String, dynamic> original;

  const InvoiceModel({
    required this.id,
    required this.numero,
    this.fecha,
    required this.estado,
    this.pedidoId,
    this.ventaId,
    required this.origen,
    required this.subtotal,
    required this.impuestos,
    required this.descuento,
    required this.total,
    required this.metodoPago,
    required this.notas,
    required this.clienteNombre,
    required this.clienteDocumento,
    required this.clienteCorreo,
    required this.clienteDireccion,
    required this.clienteCiudad,
    required this.detalles,
    required this.original,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id'] ?? map['id_factura']);
    final pedido = map['pedido'] is Map<String, dynamic> ? map['pedido'] as Map<String, dynamic> : {};
    final venta = map['venta'] is Map<String, dynamic> ? map['venta'] as Map<String, dynamic> : {};
    final usuario = pedido['usuario'] is Map<String, dynamic>
        ? pedido['usuario'] as Map<String, dynamic>
        : (venta['cliente'] is Map<String, dynamic>
            ? venta['cliente'] as Map<String, dynamic>
            : (map['usuario'] is Map<String, dynamic> ? map['usuario'] as Map<String, dynamic> : {}));

    final rawDetalles = map['detalles'] ?? pedido['detalles'] ?? venta['detalles'] ?? [];
    final List<InvoiceItemDetail> items = [];
    if (rawDetalles is List) {
      for (final d in rawDetalles) {
        if (d is Map<String, dynamic>) {
          items.add(InvoiceItemDetail.fromJson(d));
        }
      }
    }

    final subtotal = JsonParser.toDouble(map['subtotal']);
    final impuestos = JsonParser.toDouble(map['impuestos'] ?? map['iva'] ?? map['valor_iva']);
    final descuento = JsonParser.toDouble(map['descuento']);
    final pedidoId = map['pedido_id'] != null ? JsonParser.toInt(map['pedido_id']) : null;
    final ventaId = map['venta_id'] != null ? JsonParser.toInt(map['venta_id']) : null;

    final origen = pedidoId != null ? 'pedido' : (ventaId != null ? 'venta' : 'manual');

    return InvoiceModel(
      id: id,
      numero: JsonParser.toStr(map['numero_factura'] ?? map['numero'] ?? map['consecutivo'], 'FAC-$id'),
      fecha: map['fecha_emision']?.toString() ?? map['created_at']?.toString(),
      estado: JsonParser.toStr(map['estado'], 'Emitida'),
      pedidoId: pedidoId,
      ventaId: ventaId,
      origen: origen,
      subtotal: subtotal,
      impuestos: impuestos,
      descuento: descuento,
      total: JsonParser.toDouble(map['total'] ?? map['monto_total'], subtotal + impuestos - descuento),
      metodoPago: JsonParser.toStr(map['metodo_pago'] ?? venta['medio_pago'] ?? pedido['metodo_pago']),
      notas: JsonParser.toStr(map['notas'] ?? map['observaciones']),
      clienteNombre: JsonParser.toStr(map['cliente_nombre'] ?? usuario['nombre'], 'Consumidor final'),
      clienteDocumento: JsonParser.toStr(map['cliente_documento'] ?? map['nit'] ?? usuario['documento']),
      clienteCorreo: JsonParser.toStr(map['cliente_correo'] ?? usuario['correo'] ?? usuario['email']),
      clienteDireccion: JsonParser.toStr(map['cliente_direccion'] ?? pedido['direccion_envio']),
      clienteCiudad: JsonParser.toStr(pedido['ciudad_envio']),
      detalles: items,
      original: map,
    );
  }
}
