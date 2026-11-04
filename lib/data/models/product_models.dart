// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import '../../core/network/api_response_parser.dart';
import '../../core/utils/image_url_resolver.dart';

class ProductImage {
  final int idImagen;
  final String ruta;
  final bool esPrincipal;
  final String urlResuelta;

  const ProductImage({
    required this.idImagen,
    required this.ruta,
    required this.esPrincipal,
    required this.urlResuelta,
  });

  factory ProductImage.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id_imagen'] ?? map['id']);
    final ruta = JsonParser.toStr(map['ruta'] ?? map['url'] ?? map['imagen']);
    final esPrincipal = JsonParser.toBool(map['es_principal']);
    final urlResuelta = ImageUrlResolver.resolve(map);

    return ProductImage(
      idImagen: id,
      ruta: ruta,
      esPrincipal: esPrincipal,
      urlResuelta: urlResuelta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_imagen': idImagen,
      'ruta': ruta,
      'es_principal': esPrincipal,
      'url_resuelta': urlResuelta,
    };
  }
}

class ProductVariant {
  final int idVariante;
  final String talla;
  final String sku;
  final double precioVenta;
  final double precioOriginal;
  final int stock;

  const ProductVariant({
    required this.idVariante,
    required this.talla,
    required this.sku,
    required this.precioVenta,
    required this.precioOriginal,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id_variante'] ?? map['id']);
    final talla = JsonParser.toStr(map['talla']);
    final sku = JsonParser.toStr(map['sku']);
    final precioVenta = JsonParser.toDouble(map['precio_venta'] ?? map['precio']);
    final precioOriginal = JsonParser.toDouble(
      map['precio_original'] ?? map['precio_venta'] ?? map['precio'],
      precioVenta,
    );
    final stock = JsonParser.toInt(map['stock']);

    return ProductVariant(
      idVariante: id,
      talla: talla,
      sku: sku,
      precioVenta: precioVenta,
      precioOriginal: precioOriginal,
      stock: stock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_variante': idVariante,
      'talla': talla,
      'sku': sku,
      'precio_venta': precioVenta,
      'precio_original': precioOriginal,
      'stock': stock,
    };
  }
}

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

class PriceInfo {
  final double precioOriginal;
  final double precioFinal;
  final double ahorro;
  final int porcentaje;
  final Promotion? promocion;

  const PriceInfo({
    required this.precioOriginal,
    required this.precioFinal,
    required this.ahorro,
    required this.porcentaje,
    this.promocion,
  });

  bool get tieneDescuento => ahorro > 0;
}

class Product {
  final int idProducto;
  final String nombre;
  final String descripcion;
  final String color;
  final bool activo;
  final int? categoriaId;
  final int? catalogoId;
  final Category? categoria;
  final Catalog? catalogo;
  final List<ProductImage> imagenes;
  final List<ProductVariant> variantes;
  final double? precioFinalBackend;
  final Map<String, dynamic> original;

  const Product({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.activo,
    this.categoriaId,
    this.catalogoId,
    this.categoria,
    this.catalogo,
    required this.imagenes,
    required this.variantes,
    this.precioFinalBackend,
    required this.original,
  });

  factory Product.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id_producto'] ?? map['id']);
    final nombre = JsonParser.toStr(map['nombre']);
    final descripcion = JsonParser.toStr(map['descripcion']);
    final color = JsonParser.toStr(map['color']);
    final activo = map['activo'] == null ? true : JsonParser.toBool(map['activo']);

    final catMap = map['categoria'] is Map<String, dynamic> ? map['categoria'] as Map<String, dynamic> : null;
    final rawCatId = map['id_categoria'] ?? map['categoria_id'] ?? catMap?['id_categoria'] ?? catMap?['id'];
    final categoriaId = rawCatId != null ? JsonParser.toInt(rawCatId) : null;

    final colMap = map['catalogo'] is Map<String, dynamic> ? map['catalogo'] as Map<String, dynamic> : null;
    final rawColId = map['id_catalogo'] ?? map['catalogo_id'] ?? colMap?['id_catalogo'] ?? colMap?['id'];
    final catalogoId = rawColId != null ? JsonParser.toInt(rawColId) : null;

    final categoria = catMap != null ? Category.fromJson(catMap) : null;
    final catalogo = colMap != null ? Catalog.fromJson(colMap) : null;

    final List<ProductImage> imagenes = [];
    final rawImgs = map['imagenes'] ?? map['fotos'];
    if (rawImgs is List) {
      for (final img in rawImgs) {
        if (img is Map<String, dynamic>) {
          imagenes.add(ProductImage.fromJson(img));
        }
      }
    }

    final List<ProductVariant> variantes = [];
    final rawVars = map['variantes'] ?? map['tallas'];
    if (rawVars is List) {
      for (final v in rawVars) {
        if (v is Map<String, dynamic>) {
          variantes.add(ProductVariant.fromJson(v));
        }
      }
    }

    final rawPrecioFinal = map['precio_final'] ?? map['precio_con_descuento'];
    final precioFinalBackend = rawPrecioFinal != null ? JsonParser.toDouble(rawPrecioFinal) : null;

    return Product(
      idProducto: id,
      nombre: nombre,
      descripcion: descripcion,
      color: color,
      activo: activo,
      categoriaId: categoriaId != null && categoriaId > 0 ? categoriaId : null,
      catalogoId: catalogoId != null && catalogoId > 0 ? catalogoId : null,
      categoria: categoria,
      catalogo: catalogo,
      imagenes: imagenes,
      variantes: variantes,
      precioFinalBackend: precioFinalBackend,
      original: map,
    );
  }

  String get primeraImagenUrl {
    if (imagenes.isEmpty) {
      final fallbackImg = original['imagen'] ?? original['foto'] ?? original['url'];
      return fallbackImg != null ? ImageUrlResolver.resolve(fallbackImg) : '';
    }
    final principal = imagenes.firstWhere(
      (img) => img.esPrincipal,
      orElse: () => imagenes.first,
    );
    return principal.urlResuelta;
  }

  double get precioMinimo {
    if (variantes.isEmpty) {
      return JsonParser.toDouble(original['precio_venta'] ?? original['precio_base'] ?? original['precio']);
    }
    double min = variantes.first.precioVenta;
    for (final v in variantes) {
      if (v.precioVenta < min && v.precioVenta > 0) {
        min = v.precioVenta;
      }
    }
    return min;
  }

  int get stockTotal {
    int total = 0;
    for (final v in variantes) {
      total += v.stock;
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'activo': activo,
      'id_categoria': categoriaId,
      'id_catalogo': catalogoId,
      'categoria': categoria?.toJson(),
      'catalogo': catalogo?.toJson(),
      'imagenes': imagenes.map((e) => e.toJson()).toList(),
      'variantes': variantes.map((e) => e.toJson()).toList(),
      if (precioFinalBackend != null) 'precio_final': precioFinalBackend,
    };
  }
}
