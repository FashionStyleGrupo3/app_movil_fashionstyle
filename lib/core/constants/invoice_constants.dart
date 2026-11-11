// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js

const List<String> extensionesCargaMasiva = ['xlsx', 'csv'];

const int tamanoMaximoCargaMb = 5;

const String plantillaCsvContenido = '''pedido_id,venta_id,fecha_emision,cliente_documento,notas
15,,2026-10-16,1020304050,Factura pedido online
,8,2026-10-16,,Venta de mostrador''';
