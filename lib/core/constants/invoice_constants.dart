// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_item_detail.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_item_detail.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_status.dart';
import 'package:fashion_style_mobile/data/services/invoice_service.dart';
import 'package:fashion_style_mobile/data/services/order_service.dart';

const List<String> extensionesCargaMasiva = ['xlsx', 'csv'];

const int tamanoMaximoCargaMb = 5;

const String plantillaCsvContenido = '''pedido_id,venta_id,fecha_emision,cliente_documento,notas
15,,2026-10-16,1020304050,Factura pedido online
,8,2026-10-16,,Venta de mostrador''';
