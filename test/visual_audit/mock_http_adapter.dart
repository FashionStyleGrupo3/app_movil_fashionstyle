import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class MockAuditHttpAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    dynamic responseData;

    final singleProdMatch = RegExp(r'/productos/(\d+)').firstMatch(path);
    if (singleProdMatch != null) {
      final pid = int.tryParse(singleProdMatch.group(1)!) ?? 1;
      responseData = {
        'id': pid,
        'id_producto': pid,
        'nombre': 'Vestido Midi Terracotta Mineral',
        'descripcion': 'Vestido midi con drapeado sartorial en lino belga.',
        'color': 'Terracotta',
        'activo': true,
        'publicado': true,
        'categoria_id': 1,
        'catalogo_id': 1,
        'precio_final': 245000.0,
        'imagenes': [
          {'id': 1, 'url': '', 'es_principal': true}
        ],
        'variantes': [
          {'id': 101, 'talla': 'S', 'sku': 'VMD-TER-S', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 8},
          {'id': 102, 'talla': 'M', 'sku': 'VMD-TER-M', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 4},
          {'id': 103, 'talla': 'L', 'sku': 'VMD-TER-L', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 0},
        ]
      };
    } else if (path.contains('/productos') || path.contains('/prendas')) {
      responseData = [
        {
          'id': 1,
          'id_producto': 1,
          'nombre': 'Vestido Midi Terracotta Mineral',
          'descripcion': 'Vestido midi con drapeado sartorial en lino belga.',
          'color': 'Terracotta',
          'activo': true,
          'publicado': true,
          'categoria_id': 1,
          'catalogo_id': 1,
          'precio_final': 245000.0,
          'imagenes': [
            {'id': 1, 'url': '', 'es_principal': true}
          ],
          'variantes': [
            {'id': 101, 'talla': 'S', 'sku': 'VMD-TER-S', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 8},
            {'id': 102, 'talla': 'M', 'sku': 'VMD-TER-M', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 4},
            {'id': 103, 'talla': 'L', 'sku': 'VMD-TER-L', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 0},
          ]
        },
        {
          'id': 2,
          'id_producto': 2,
          'nombre': 'Blusa Sartorial Lino Jade',
          'descripcion': 'Blusa de corte asimétrico con pespuntes artesanales.',
          'color': 'Jade',
          'activo': true,
          'publicado': true,
          'categoria_id': 2,
          'catalogo_id': 1,
          'precio_final': 185000.0,
          'imagenes': [
            {'id': 2, 'url': '', 'es_principal': true}
          ],
          'variantes': [
            {'id': 201, 'talla': 'XS', 'sku': 'BLS-JAD-XS', 'precio_venta': 185000.0, 'precio_original': 185000.0, 'stock': 12},
            {'id': 202, 'talla': 'S', 'sku': 'BLS-JAD-S', 'precio_venta': 185000.0, 'precio_original': 185000.0, 'stock': 6},
          ]
        },
        {
          'id': 3,
          'id_producto': 3,
          'nombre': 'Pantalón Palazzio Crepé Carbón',
          'descripcion': 'Pantalón palazzo tiro alto con pretina arquitectónica.',
          'color': 'Carbón',
          'activo': true,
          'publicado': true,
          'categoria_id': 3,
          'catalogo_id': 2,
          'precio_final': 210000.0,
          'imagenes': [
            {'id': 3, 'url': '', 'es_principal': true}
          ],
          'variantes': [
            {'id': 301, 'talla': '6', 'sku': 'PAL-CRB-06', 'precio_venta': 210000.0, 'precio_original': 210000.0, 'stock': 5},
          ]
        },
      ];
    } else if (path.contains('/categorias')) {
      responseData = [
        {'id': 1, 'id_categoria': 1, 'nombre': 'Vestidos & Enterizos', 'activo': true},
        {'id': 2, 'id_categoria': 2, 'nombre': 'Blusas & Camisas', 'activo': true},
        {'id': 3, 'id_categoria': 3, 'nombre': 'Pantalones & Faldas', 'activo': true},
      ];
    } else if (path.contains('/catalogos')) {
      responseData = [
        {'id': 1, 'id_catalogo': 1, 'nombre': 'Colección Neo-Atelier 2026', 'activo': true},
        {'id': 2, 'id_catalogo': 2, 'nombre': 'Atelier Esenciales', 'activo': true},
      ];
    } else if (path.contains('/promociones')) {
      responseData = [
        {
          'id': 1,
          'nombre': 'Atelier Bienvenida -15%',
          'descripcion': '15% de descuento en vestidos y sastrería',
          'tipo': 'porcentaje',
          'valor': 15.0,
          'activa': true,
        }
      ];
    } else if (path.contains('/dashboard')) {
      responseData = {
        'kpis': {
          'ventas_hoy': 1280000.0,
          'ventas_mes': 18650000.0,
          'transacciones_mes': 48,
          'pedidos_pendientes': 3,
          'ordenes_activas': 5,
          'stock_total': 142,
          'alertas_pendientes': 2,
        },
        'ventas_por_mes': [
          {'mes': 'Jun', 'total': 12400000.0, 'pos': 5200000.0, 'web': 7200000.0},
          {'mes': 'Jul', 'total': 14100000.0, 'pos': 6100000.0, 'web': 8000000.0},
          {'mes': 'Ago', 'total': 15800000.0, 'pos': 6900000.0, 'web': 8900000.0},
          {'mes': 'Sep', 'total': 16500000.0, 'pos': 7100000.0, 'web': 9400000.0},
          {'mes': 'Oct', 'total': 17900000.0, 'pos': 7800000.0, 'web': 10100000.0},
          {'mes': 'Nov', 'total': 18650000.0, 'pos': 8250000.0, 'web': 10400000.0},
        ],
        'ventas_por_medio': [
          {'medio': 'Wompi Bancolombia', 'total': 10400000.0, 'porcentaje': 55.8},
          {'medio': 'Tarjeta POS Mostrador', 'total': 5150000.0, 'porcentaje': 27.6},
          {'medio': 'Efectivo Boutique', 'total': 3100000.0, 'porcentaje': 16.6},
        ],
        'produccion_por_mes': [
          {'mes': 'Jun', 'planificadas': 80, 'completadas': 75},
          {'mes': 'Jul', 'planificadas': 95, 'completadas': 90},
          {'mes': 'Ago', 'planificadas': 110, 'completadas': 104},
          {'mes': 'Sep', 'planificadas': 120, 'completadas': 115},
          {'mes': 'Oct', 'planificadas': 135, 'completadas': 128},
          {'mes': 'Nov', 'planificadas': 140, 'completadas': 132},
        ],
        'ordenes_por_estado': {
          'corte': 2,
          'confeccion': 2,
          'ensamble': 1,
        },
        'inventario': {
          'alertas_por_nivel': {
            'critico': 2,
            'bajo': 4,
            'optimo': 28,
          },
          'menor_stock': [
            {'id_producto': 1, 'prenda': 'Vestido Midi Terracotta L', 'sku': 'VMD-TER-L', 'stock': 0},
            {'id_producto': 2, 'prenda': 'Blusa Sartorial Lino M', 'sku': 'BLS-JAD-M', 'stock': 2},
          ],
          'materias_bajo_minimo': 1,
          'movimientos_mes': 74,
        },
      };
    } else if (path.contains('/inventario')) {
      responseData = [
        {
          'id_variante': 101,
          'id_producto': 1,
          'nombre_prenda': 'Vestido Midi Terracotta Mineral',
          'talla': 'S',
          'color': 'Terracotta',
          'sku': 'VMD-TER-S',
          'stock': 8,
          'imagen_url': '',
        },
        {
          'id_variante': 102,
          'id_producto': 1,
          'nombre_prenda': 'Vestido Midi Terracotta Mineral',
          'talla': 'M',
          'color': 'Terracotta',
          'sku': 'VMD-TER-M',
          'stock': 3,
          'imagen_url': '',
        },
        {
          'id_variante': 103,
          'id_producto': 1,
          'nombre_prenda': 'Vestido Midi Terracotta Mineral',
          'talla': 'L',
          'color': 'Terracotta',
          'sku': 'VMD-TER-L',
          'stock': 0,
          'imagen_url': '',
        },
      ];
    } else if (path.contains('/ventas')) {
      responseData = [
        {
          'id': 201,
          'numero_ticket': 'FS-POS-0201',
          'fecha': '11/11/2026 10:20',
          'total': 245000.0,
          'subtotal': 245000.0,
          'medio_pago': 'efectivo',
          'estado': 'completada',
          'cliente_nombre': 'Camila Restrepo',
          'detalles': [
            {'nombre_prenda': 'Vestido Midi Terracotta Mineral', 'talla': 'S', 'cantidad': 1, 'subtotal': 245000.0}
          ]
        },
        {
          'id': 200,
          'numero_ticket': 'FS-POS-0200',
          'fecha': '11/11/2026 09:40',
          'total': 185000.0,
          'subtotal': 185000.0,
          'medio_pago': 'tarjeta',
          'estado': 'completada',
          'cliente_nombre': 'Cliente Ocasional',
          'detalles': [
            {'nombre_prenda': 'Blusa Sartorial Lino Jade', 'talla': 'S', 'cantidad': 1, 'subtotal': 185000.0}
          ]
        }
      ];
    } else if (path.contains('/pedidos')) {
      responseData = [
        {
          'id': 1084,
          'referencia': 'FS-2026-1084',
          'estado': 'Pagado',
          'total': 430000.0,
          'subtotal': 415000.0,
          'envio': 15000.0,
          'fecha': '11/11/2026 09:15',
          'fecha_pedido': '2026-11-11 09:15:00',
          'cliente_nombre': 'Valentina Morales',
          'cliente_correo': 'valentina.morales@correo.co',
          'telefono': '3157894512',
          'direccion': 'Carrera 7 # 120-40',
          'ciudad': 'Bogotá',
          'departamento': 'Cundinamarca',
          'metodo_pago': 'WOMPI',
          'empresa_transportadora': 'Coordinadora',
          'numero_guia': 'GUIA-88912401',
          'factura_id': 504,
          'detalles': [
            {'id': 1, 'producto_nombre': 'Vestido Midi Terracotta', 'talla': 'S', 'cantidad': 1, 'precio_unitario': 245000.0, 'subtotal': 245000.0}
          ]
        }
      ];
    } else if (path.contains('/usuarios')) {
      responseData = [
        {
          'id': 1,
          'name': 'Administrador General',
          'email': 'admin@fashionstyle.com',
          'telefono': '3001234567',
          'direccion': 'Calle 10 # 40-20',
          'ciudad': 'Bogotá',
          'roles': ['administrador'],
          'activo': true,
        },
        {
          'id': 2,
          'name': 'Elena Sastre',
          'email': 'elena@fashionstyle.com',
          'telefono': '3129876543',
          'direccion': 'Carrera 15 # 85-30',
          'ciudad': 'Medellín',
          'roles': ['empleado'],
          'activo': true,
        },
        {
          'id': 3,
          'name': 'Valentina Morales',
          'email': 'valentina.morales@correo.co',
          'telefono': '3157894512',
          'direccion': 'Carrera 7 # 120-40',
          'ciudad': 'Bogotá',
          'roles': ['cliente'],
          'activo': true,
        }
      ];
    } else if (path.contains('/auditorias') || path.contains('/auditoria')) {
      responseData = [
        {
          'id': 951,
          'usuario': 'Administrador General',
          'accion': 'ACTUALIZAR_PRECIO_PRENDA',
          'recurso': 'prenda:1',
          'detalles': 'Cambio de precio de venta a \$245.000 COP',
          'ip': '190.145.22.84',
          'created_at': '2026-11-11 09:30:15',
        },
        {
          'id': 950,
          'usuario': 'Elena Sastre',
          'accion': 'REGISTRAR_VENTA_POS',
          'recurso': 'venta:201',
          'detalles': 'Venta mostrador ticket #FS-POS-0201 por \$245.000',
          'ip': '190.145.22.84',
          'created_at': '2026-11-11 10:20:00',
        }
      ];
    } else if (path.contains('/pagos')) {
      responseData = [
        {
          'id': 301,
          'referencia': 'FS-2026-1084',
          'metodo': 'WOMPI',
          'monto': 430000.0,
          'estado': 'aprobado',
          'fecha': '11/11/2026 09:16',
          'transaccion_id': 'WOMPI-TX-99881',
        }
      ];
    } else if (path.contains('/ordenes-produccion')) {
      responseData = [
        {
          'id': 501,
          'numero_orden': 'OP-2026-0501',
          'prenda': 'Vestido Midi Terracotta',
          'fase': 'Corte',
          'estado': 'en_proceso',
          'cantidad_planificada': 20,
          'cantidad_completada': 14,
          'fecha_inicio': '08/11/2026',
          'fecha_estimada': '15/11/2026',
        }
      ];
    } else if (path.contains('/terminos')) {
      responseData = {
        'titulo': 'Términos y Condiciones del Atelier FashionStyle',
        'contenido': 'Bienvenido a FashionStyle Atelier. Al utilizar nuestra aplicación móvil oficial y realizar compras, aceptas las políticas de confección artesanal, envíos asegurados a nivel nacional y garantías de sastrería.',
        'updated_at': '2026-11-11',
      };
    } else {
      responseData = {'status': 'ok', 'data': []};
    }

    final jsonString = jsonEncode(responseData);
    final utf8Bytes = utf8.encode(jsonString);

    return ResponseBody(
      Stream.value(Uint8List.fromList(utf8Bytes)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
