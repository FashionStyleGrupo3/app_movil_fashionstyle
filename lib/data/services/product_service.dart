// @source-mirror: src/services/productoServicio.js, src/services/clasificacionServicio.js
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';
import '../models/product_models.dart';

class ProductFilters {
  final int? categoriaId;
  final int? catalogoId;
  final String? busqueda;
  final bool? activo;
  final bool? publicado;
  final bool esPersonal;

  const ProductFilters({
    this.categoriaId,
    this.catalogoId,
    this.busqueda,
    this.activo,
    this.publicado,
    this.esPersonal = false,
  });
}

class ProductService {
  static final ProductService _instance = ProductService._internal();
  static ProductService get instance => _instance;

  ProductService._internal();

  Future<List<Product>> obtenerProductos([ProductFilters? filtros]) async {
    final params = <String, dynamic>{};
    if (filtros?.categoriaId != null) params['categoria_id'] = filtros!.categoriaId;
    if (filtros?.catalogoId != null) params['catalogo_id'] = filtros!.catalogoId;
    if (filtros?.busqueda != null && filtros!.busqueda!.trim().isNotEmpty) {
      params['q'] = filtros.busqueda!.trim();
    }
    if (filtros?.activo != null) params['activo'] = filtros!.activo;
    if (filtros?.publicado != null) params['publicado'] = filtros!.publicado;

    final response = await ApiClient.instance.dio.get('/productos', queryParameters: params);
    final rawData = ApiResponseParser.extractData(response);

    List<Product> productos = [];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          productos.add(Product.fromJson(item));
        }
      }
    }

    // 1. Filtro de seguridad: Activo (a menos que se soliciten explícitamente inactivos)
    if (filtros?.activo == null || filtros!.activo == true) {
      productos = productos.where((p) => p.activo).toList();
    }

    // 1b. Filtro de seguridad: Publicado (el público y clientes solo ven los publicados)
    final esPersonal = filtros?.esPersonal ?? false;
    if (!esPersonal && (filtros?.publicado == null || filtros!.publicado == true)) {
      productos = productos.where((p) => p.publicado).toList();
    }

    // 2. Filtro de seguridad en cliente: Categoría
    if (filtros?.categoriaId != null) {
      final catId = filtros!.categoriaId!;
      productos = productos.where((p) => p.categoriaId == catId).toList();
    }

    // 3. Filtro de seguridad en cliente: Catálogo o colección
    if (filtros?.catalogoId != null) {
      final colId = filtros!.catalogoId!;
      productos = productos.where((p) => p.catalogoId == colId).toList();
    }

    // 4. Filtro de seguridad en cliente: Búsqueda textual
    if (filtros?.busqueda != null && filtros!.busqueda!.trim().isNotEmpty) {
      final termino = filtros.busqueda!.trim().toLowerCase();
      productos = productos.where((p) {
        final nombre = p.nombre.toLowerCase();
        final desc = p.descripcion.toLowerCase();
        final cat = (p.categoria?.nombre ?? '').toLowerCase();
        final col = (p.catalogo?.nombre ?? '').toLowerCase();
        return nombre.contains(termino) ||
            desc.contains(termino) ||
            cat.contains(termino) ||
            col.contains(termino);
      }).toList();
    }

    return productos;
  }

  Future<Product?> obtenerProducto(int id) async {
    final response = await ApiClient.instance.dio.get('/productos/$id');
    final data = ApiResponseParser.extractData(response);
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data);
    }
    return null;
  }

  Future<Product> togglePublicado(int id) async {
    final response = await ApiClient.instance.dio.patch('/productos/$id/toggle-publicado');
    final data = ApiResponseParser.extractData(response);
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data);
    }
    final actual = await obtenerProducto(id);
    if (actual != null) return actual;
    throw StateError('No se pudo alternar el estado de publicación');
  }

  Future<Product> toggleActivo(int id) async {
    final response = await ApiClient.instance.dio.patch('/productos/$id/toggle-activo');
    final data = ApiResponseParser.extractData(response);
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data);
    }
    final actual = await obtenerProducto(id);
    if (actual != null) return actual;
    throw StateError('No se pudo alternar el estado activo');
  }

  Future<List<Category>> obtenerCategorias() async {
    try {
      final response = await ApiClient.instance.dio.get('/categorias');
      final data = ApiResponseParser.extractData(response);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => Category.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Catalog>> obtenerCatalogos() async {
    try {
      final response = await ApiClient.instance.dio.get('/catalogos');
      final data = ApiResponseParser.extractData(response);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => Catalog.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
