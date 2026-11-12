import 'package:fashion_style_mobile/data/models/cart/cart_item.dart';
import 'package:fashion_style_mobile/data/models/dashboard/dashboard_models.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';

// Categorías
const mockCategories = [
  Category(idCategoria: 1, nombre: 'Vestidos & Enterizos', descripcion: 'Prendas exclusivas de alta costura atelier', activo: true),
  Category(idCategoria: 2, nombre: 'Blusas & Camisas', descripcion: 'Sastrería contemporánea en lino y seda', activo: true),
  Category(idCategoria: 3, nombre: 'Pantalones & Faldas', descripcion: 'Cortes arquitectónicos y siluetas fluidas', activo: true),
  Category(idCategoria: 4, nombre: 'Chaquetas & Abrigos', descripcion: 'Prendas exteriores estructuradas', activo: true),
];

// Colecciones
const mockCatalogs = [
  Catalog(idCatalogo: 1, nombre: 'Colección Neo-Atelier 2026', descripcion: 'Líneas minerales y acentos terracota', activo: true),
  Catalog(idCatalogo: 2, nombre: 'Atelier Esenciales', descripcion: 'Piezas atemporales para el día a día', activo: true),
];

// Promociones
final mockPromotions = [
  Promotion.fromJson({
    'id': 1,
    'nombre': 'Atelier Bienvenida -15%',
    'descripcion': '15% de descuento en vestidos y sastrería de temporada',
    'tipo': 'porcentaje',
    'valor': 15.0,
    'activa': true,
  }),
];

// Productos
final List<Product> mockProducts = [
  Product.fromJson({
    'id': 1,
    'id_producto': 1,
    'nombre': 'Vestido Midi Terracotta Mineral',
    'descripcion': 'Vestido midi con drapeado sartorial, confeccionado en lino belga con tinte mineral natural.',
    'color': 'Terracotta',
    'activo': true,
    'publicado': true,
    'categoria_id': 1,
    'catalogo_id': 1,
    'precio_final': 245000.0,
    'imagenes': [
      {'id_imagen': 1, 'url': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800', 'es_principal': true}
    ],
    'variantes': [
      {'id_variante': 101, 'talla': 'S', 'sku': 'VMD-TER-S', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 8},
      {'id_variante': 102, 'talla': 'M', 'sku': 'VMD-TER-M', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 4},
      {'id_variante': 103, 'talla': 'L', 'sku': 'VMD-TER-L', 'precio_venta': 245000.0, 'precio_original': 285000.0, 'stock': 0},
    ],
  }),
  Product.fromJson({
    'id': 2,
    'id_producto': 2,
    'nombre': 'Blusa Sartorial Lino Jade',
    'descripcion': 'Blusa de corte asimétrico con pespulles artesanales y botonadura oculta.',
    'color': 'Jade',
    'activo': true,
    'publicado': true,
    'categoria_id': 2,
    'catalogo_id': 1,
    'precio_final': 185000.0,
    'imagenes': [
      {'id_imagen': 2, 'url': 'https://images.unsplash.com/photo-1551803091-e20673f15770?w=800', 'es_principal': true}
    ],
    'variantes': [
      {'id_variante': 201, 'talla': 'XS', 'sku': 'BLS-JAD-XS', 'precio_venta': 185000.0, 'precio_original': 185000.0, 'stock': 12},
      {'id_variante': 202, 'talla': 'S', 'sku': 'BLS-JAD-S', 'precio_venta': 185000.0, 'precio_original': 185000.0, 'stock': 6},
    ],
  }),
  Product.fromJson({
    'id': 3,
    'id_producto': 3,
    'nombre': 'Pantalón Palazzio Crepé Carbón',
    'descripcion': 'Pantalón palazzo tiro alto con pretina arquitectónica y caída suave en crepé pesado.',
    'color': 'Carbón',
    'activo': true,
    'publicado': true,
    'categoria_id': 3,
    'catalogo_id': 2,
    'precio_final': 210000.0,
    'imagenes': [
      {'id_imagen': 3, 'url': 'https://images.unsplash.com/photo-1509551388413-e18d0ac5d495?w=800', 'es_principal': true}
    ],
    'variantes': [
      {'id_variante': 301, 'talla': '6', 'sku': 'PAL-CRB-06', 'precio_venta': 210000.0, 'precio_original': 210000.0, 'stock': 5},
    ],
  }),
  Product.fromJson({
    'id': 4,
    'id_producto': 4,
    'nombre': 'Blazer Estructurado Ocre Taller',
    'descripcion': 'Saco sastre forrado en seda con solapas en punta y hombreras definidas.',
    'color': 'Ocre',
    'activo': true,
    'publicado': true,
    'categoria_id': 4,
    'catalogo_id': 1,
    'precio_final': 340000.0,
    'imagenes': [
      {'id_imagen': 4, 'url': 'https://images.unsplash.com/photo-1584273143981-41c073dfe8f8?w=800', 'es_principal': true}
    ],
    'variantes': [
      {'id_variante': 401, 'talla': 'M', 'sku': 'BLZ-OCR-M', 'precio_venta': 340000.0, 'precio_original': 340000.0, 'stock': 3},
    ],
  }),
];

// Ítems de carrito
const mockCartItems = [
  CartItem(
    productoId: 1,
    nombre: 'Vestido Midi Terracotta Mineral',
    imagen: '',
    varianteId: 101,
    talla: 'S',
    sku: 'VMD-TER-S',
    precio: 245000.0,
    precioOriginal: 285000.0,
    stockMaximo: 8,
    cantidad: 1,
    categoriaId: 1,
    catalogoId: 1,
  ),
  CartItem(
    productoId: 2,
    nombre: 'Blusa Sartorial Lino Jade',
    imagen: '',
    varianteId: 202,
    talla: 'S',
    sku: 'BLS-JAD-S',
    precio: 185000.0,
    precioOriginal: 185000.0,
    stockMaximo: 6,
    cantidad: 2,
    categoriaId: 2,
    catalogoId: 1,
  ),
];

// Pedidos
final List<OrderModel> mockOrders = [
  OrderModel.fromJson({
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
    'direccion': 'Carrera 7 # 120-40 Apto 502',
    'ciudad': 'Bogotá',
    'departamento': 'Cundinamarca',
    'metodo_pago': 'WOMPI',
    'notas': 'Entregar en portería principal.',
    'empresa_transportadora': 'Coordinadora',
    'numero_guia': 'GUIA-88912401',
    'factura_id': 504,
    'detalles': [
      {
        'id': 1,
        'variante_id': 101,
        'nombre_producto': 'Vestido Midi Terracotta Mineral',
        'talla': 'S',
        'sku': 'VMD-TER-S',
        'cantidad': 1,
        'precio_unitario': 245000.0,
        'subtotal': 245000.0,
      },
      {
        'id': 2,
        'variante_id': 202,
        'nombre_producto': 'Blusa Sartorial Lino Jade',
        'talla': 'S',
        'sku': 'BLS-JAD-S',
        'cantidad': 1,
        'precio_unitario': 185000.0,
        'subtotal': 185000.0,
      },
    ],
  }),
  OrderModel.fromJson({
    'id': 1083,
    'referencia': 'FS-2026-1083',
    'estado': 'Pendiente_Pago',
    'total': 210000.0,
    'subtotal': 195000.0,
    'envio': 15000.0,
    'fecha': '10/11/2026 16:40',
    'fecha_pedido': '2026-11-10 16:40:00',
    'cliente_nombre': 'Mateo Cárdenas',
    'cliente_correo': 'mateo.c@estilo.com',
    'telefono': '3006541289',
    'direccion': 'Calle 45 # 22-15',
    'ciudad': 'Medellín',
    'departamento': 'Antioquia',
    'metodo_pago': 'WOMPI',
    'notas': '',
    'empresa_transportadora': '',
    'numero_guia': '',
    'detalles': [],
  }),
];

// Dashboard Data
const mockDashboardData = DashboardData(
  kpis: DashboardKpis(
    ventasHoy: 1280000.0,
    ventasMes: 18650000.0,
    transaccionesMes: 48,
    pedidosPendientes: 3,
    ordenesActivas: 5,
    stockTotal: 142,
    alertasPendientes: 2,
  ),
  ventasPorMes: [
    VentasPorMesItem(mes: 'Jun', pos: 5200000.0, web: 7200000.0, cantidad: 35),
    VentasPorMesItem(mes: 'Jul', pos: 6100000.0, web: 8000000.0, cantidad: 40),
    VentasPorMesItem(mes: 'Ago', pos: 6900000.0, web: 8900000.0, cantidad: 45),
    VentasPorMesItem(mes: 'Sep', pos: 7100000.0, web: 9400000.0, cantidad: 48),
    VentasPorMesItem(mes: 'Oct', pos: 7800000.0, web: 10100000.0, cantidad: 52),
    VentasPorMesItem(mes: 'Nov', pos: 8250000.0, web: 10400000.0, cantidad: 55),
  ],
  ventasPorMedio: [
    VentasPorMedioItem(medio: 'Wompi Bancolombia', monto: 10400000.0),
    VentasPorMedioItem(medio: 'Tarjeta POS Mostrador', monto: 5150000.0),
    VentasPorMedioItem(medio: 'Efectivo Boutique', monto: 3100000.0),
  ],
  produccionPorMes: [
    ProduccionPorMesItem(mes: 'Jun', planificadas: 80, completadas: 75),
    ProduccionPorMesItem(mes: 'Jul', planificadas: 95, completadas: 90),
    ProduccionPorMesItem(mes: 'Ago', planificadas: 110, completadas: 104),
    ProduccionPorMesItem(mes: 'Sep', planificadas: 120, completadas: 115),
    ProduccionPorMesItem(mes: 'Oct', planificadas: 135, completadas: 128),
    ProduccionPorMesItem(mes: 'Nov', planificadas: 140, completadas: 132),
  ],
  ordenesPorEstado: {
    'corte': 2,
    'confeccion': 2,
    'ensamble': 1,
  },
  inventario: InventarioDashboardData(
    alertasPorNivel: {
      'critico': 2,
      'bajo': 4,
      'optimo': 28,
    },
    menorStock: [
      InventarioMenorStockItem(producto: 'Vestido Midi Terracotta', talla: 'L', stock: 0),
      InventarioMenorStockItem(producto: 'Blusa Sartorial Lino', talla: 'M', stock: 2),
      InventarioMenorStockItem(producto: 'Blazer Estructurado Ocre', talla: 'M', stock: 3),
    ],
    materiasBajoMinimo: 1,
    movimientosMes: 74,
  ),
  meses: 6,
);
