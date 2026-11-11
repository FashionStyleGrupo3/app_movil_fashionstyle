// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/order/order_item_detail.dart';
import 'package:fashion_style_mobile/data/models/order/order_status.dart';

class OrderModel {
  final int id;
  final String referencia;
  final String estado;
  final double total;
  final double subtotal;
  final double envio;
  final String? fecha;
  final String? fechaPedido;
  final String clienteNombre;
  final String clienteCorreo;
  final String telefono;
  final String direccion;
  final String ciudad;
  final String departamento;
  final String metodoPago;
  final String notas;
  final String empresaTransportadora;
  final String numeroGuia;
  final int? facturaId;
  final List<OrderItemDetail> detalles;
  final Map<String, dynamic> original;

  const OrderModel({
    required this.id,
    required this.referencia,
    required this.estado,
    required this.total,
    required this.subtotal,
    required this.envio,
    this.fecha,
    this.fechaPedido,
    required this.clienteNombre,
    required this.clienteCorreo,
    required this.telefono,
    required this.direccion,
    required this.ciudad,
    required this.departamento,
    required this.metodoPago,
    required this.notas,
    required this.empresaTransportadora,
    required this.numeroGuia,
    this.facturaId,
    required this.detalles,
    required this.original,
  });

  factory OrderModel.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id'] ?? map['id_pedido']);
    final userMap = map['usuario'] is Map<String, dynamic>
        ? map['usuario'] as Map<String, dynamic>
        : (map['cliente'] is Map<String, dynamic>
            ? map['cliente'] as Map<String, dynamic>
            : (map['user'] is Map<String, dynamic> ? map['user'] as Map<String, dynamic> : {}));

    final rawDetalles = map['detalles'] ?? map['detalle_pedidos'] ?? map['detalles_pedido'] ?? map['items'];
    final List<OrderItemDetail> items = [];
    if (rawDetalles is List) {
      for (final d in rawDetalles) {
        if (d is Map<String, dynamic>) {
          items.add(OrderItemDetail.fromJson(d));
        }
      }
    }

    final facturaMap = map['factura'] is Map<String, dynamic> ? map['factura'] as Map<String, dynamic> : null;
    final rawFacturaId = facturaMap?['id'] ?? map['factura_id'];

    return OrderModel(
      id: id,
      referencia: JsonParser.toStr(
        map['referencia'] ?? map['referencia_pasarela'] ?? map['codigo'],
        'PED-$id',
      ),
      estado: normalizarEstadoPedido(map['estado']),
      total: JsonParser.toDouble(map['monto_total'] ?? map['total']),
      subtotal: JsonParser.toDouble(map['subtotal'] ?? map['monto_subtotal']),
      envio: JsonParser.toDouble(map['costo_envio'] ?? map['envio']),
      fecha: map['created_at']?.toString() ?? map['fecha_pedido']?.toString() ?? map['fecha']?.toString(),
      fechaPedido: map['fecha_pedido']?.toString() ?? map['created_at']?.toString(),
      clienteNombre: JsonParser.toStr(userMap['nombre'] ?? map['nombre_cliente'], 'Cliente'),
      clienteCorreo: JsonParser.toStr(userMap['correo'] ?? userMap['email']),
      telefono: JsonParser.toStr(map['telefono_contacto'] ?? userMap['telefono']),
      direccion: JsonParser.toStr(map['direccion_envio'] ?? userMap['direccion']),
      ciudad: JsonParser.toStr(map['ciudad_envio'] ?? userMap['ciudad']),
      departamento: JsonParser.toStr(map['departamento_envio'] ?? userMap['departamento']),
      metodoPago: JsonParser.toStr(map['metodo_pago']),
      notas: JsonParser.toStr(map['notas_cliente'] ?? map['notas']),
      empresaTransportadora: JsonParser.toStr(map['empresa_transportadora']),
      numeroGuia: JsonParser.toStr(map['numero_guia']),
      facturaId: rawFacturaId != null ? JsonParser.toInt(rawFacturaId) : null,
      detalles: items,
      original: map,
    );
  }
}
