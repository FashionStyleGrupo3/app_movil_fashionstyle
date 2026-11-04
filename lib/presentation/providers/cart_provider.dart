// @source-mirror: src/stores/carrito.js
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_response_parser.dart';
import '../../core/utils/image_url_resolver.dart';
import '../../data/models/product_models.dart';

class CartItem {
  final int productoId;
  final String nombre;
  final String imagen;
  final int varianteId;
  final String talla;
  final String sku;
  final double precio;
  final double precioOriginal;
  final int stockMaximo;
  final int cantidad;
  final int? categoriaId;
  final int? catalogoId;

  const CartItem({
    required this.productoId,
    required this.nombre,
    required this.imagen,
    required this.varianteId,
    required this.talla,
    required this.sku,
    required this.precio,
    required this.precioOriginal,
    required this.stockMaximo,
    required this.cantidad,
    this.categoriaId,
    this.catalogoId,
  });

  factory CartItem.fromJson(Map<String, dynamic> map) {
    return CartItem(
      productoId: JsonParser.toInt(map['productoId'] ?? map['producto_id']),
      nombre: JsonParser.toStr(map['nombre']),
      imagen: JsonParser.toStr(map['imagen']),
      varianteId: JsonParser.toInt(map['varianteId'] ?? map['variante_id']),
      talla: JsonParser.toStr(map['talla']),
      sku: JsonParser.toStr(map['sku']),
      precio: JsonParser.toDouble(map['precio']),
      precioOriginal: JsonParser.toDouble(map['precioOriginal'] ?? map['precio_original'], JsonParser.toDouble(map['precio'])),
      stockMaximo: JsonParser.toInt(map['stockMaximo'] ?? map['stock_maximo']),
      cantidad: JsonParser.toInt(map['cantidad'], 1),
      categoriaId: map['categoriaId'] != null ? JsonParser.toInt(map['categoriaId']) : null,
      catalogoId: map['catalogoId'] != null ? JsonParser.toInt(map['catalogoId']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'imagen': imagen,
      'varianteId': varianteId,
      'talla': talla,
      'sku': sku,
      'precio': precio,
      'precioOriginal': precioOriginal,
      'stockMaximo': stockMaximo,
      'cantidad': cantidad,
      'categoriaId': categoriaId,
      'catalogoId': catalogoId,
    };
  }

  CartItem copyWith({
    int? cantidad,
    double? precio,
    double? precioOriginal,
    int? stockMaximo,
  }) {
    return CartItem(
      productoId: productoId,
      nombre: nombre,
      imagen: imagen,
      varianteId: varianteId,
      talla: talla,
      sku: sku,
      precio: precio ?? this.precio,
      precioOriginal: precioOriginal ?? this.precioOriginal,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      cantidad: cantidad ?? this.cantidad,
      categoriaId: categoriaId,
      catalogoId: catalogoId,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final bool cajonAbierto;

  const CartState({
    this.items = const [],
    this.cajonAbierto = false,
  });

  int get totalPrendas => items.fold(0, (acc, i) => acc + i.cantidad);

  double get totalMonto => items.fold(0.0, (acc, i) => acc + (i.precio * i.cantidad));

  List<String> get categoriasEnCarrito {
    final Set<String> set = {};
    for (final item in items) {
      if (item.categoriaId != null) set.add(item.categoriaId.toString());
      if (item.catalogoId != null) set.add('cat-${item.catalogoId}');
    }
    return set.toList();
  }

  List<int> get idsEnCarrito => items.map((i) => i.productoId).toSet().toList();

  CartState copyWith({
    List<CartItem>? items,
    bool? cajonAbierto,
  }) {
    return CartState(
      items: items ?? this.items,
      cajonAbierto: cajonAbierto ?? this.cajonAbierto,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState()) {
    inicializarDesdeStorage();
  }

  static const String _claveStorage = 'fs_carrito';

  Future<void> inicializarDesdeStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_claveStorage);
      if (guardado != null && guardado.isNotEmpty && guardado != 'undefined') {
        final decoded = jsonDecode(guardado);
        if (decoded is List) {
          final items = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => CartItem.fromJson(e))
              .toList();
          state = state.copyWith(items: items);
        }
      }
    } catch (_) {}
  }

  Future<void> _sincronizarStorage(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMaps = items.map((i) => i.toJson()).toList();
      await prefs.setString(_claveStorage, jsonEncode(listMaps));
    } catch (_) {}
  }

  void abrirCajon() {
    state = state.copyWith(cajonAbierto: true);
  }

  void cerrarCajon() {
    state = state.copyWith(cajonAbierto: false);
  }

  void agregarPrenda(Product producto, ProductVariant variante, [int cantidad = 1]) {
    final vId = variante.idVariante;
    final pId = producto.idProducto;
    final precio = variante.precioVenta > 0 ? variante.precioVenta : producto.precioMinimo;
    final precioOriginal = variante.precioOriginal > 0 ? variante.precioOriginal : precio;
    final stock = variante.stock;

    final urlImagen = producto.primeraImagenUrl.isNotEmpty
        ? producto.primeraImagenUrl
        : ImageUrlResolver.resolve(producto.original['imagen']);

    final index = state.items.indexWhere((i) => i.varianteId == vId);
    List<CartItem> nuevosItems = List.from(state.items);

    if (index != -1) {
      final itemActual = nuevosItems[index];
      final maxStock = stock > 0 ? stock : 999999;
      final nuevaCantidad = (itemActual.cantidad + cantidad).clamp(1, maxStock);
      nuevosItems[index] = itemActual.copyWith(cantidad: nuevaCantidad);
    } else {
      final cant = stock > 0 ? cantidad.clamp(1, stock) : cantidad;
      nuevosItems.add(
        CartItem(
          productoId: pId,
          nombre: producto.nombre,
          imagen: urlImagen,
          varianteId: vId,
          talla: variante.talla,
          sku: variante.sku,
          precio: precio,
          precioOriginal: precioOriginal,
          stockMaximo: stock,
          cantidad: cant,
          categoriaId: producto.categoriaId,
          catalogoId: producto.catalogoId,
        ),
      );
    }

    state = state.copyWith(items: nuevosItems, cajonAbierto: true);
    _sincronizarStorage(nuevosItems);
  }

  void actualizarCantidad(int varianteId, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      eliminarPrenda(varianteId);
      return;
    }

    final index = state.items.indexWhere((i) => i.varianteId == varianteId);
    if (index == -1) return;

    final nuevos = List<CartItem>.from(state.items);
    final item = nuevos[index];
    final cantidadAjustada = item.stockMaximo > 0 ? nuevaCantidad.clamp(1, item.stockMaximo) : nuevaCantidad;

    nuevos[index] = item.copyWith(cantidad: cantidadAjustada);
    state = state.copyWith(items: nuevos);
    _sincronizarStorage(nuevos);
  }

  void eliminarPrenda(int varianteId) {
    final filtrados = state.items.where((i) => i.varianteId != varianteId).toList();
    state = state.copyWith(items: filtrados);
    _sincronizarStorage(filtrados);
  }

  void actualizarPrecios(List<Map<String, dynamic>> cambios) {
    bool huboCambio = false;
    final nuevos = state.items.map((item) {
      final cambio = cambios.firstWhere(
        (c) => JsonParser.toInt(c['varianteId']) == item.varianteId,
        orElse: () => const {},
      );

      if (cambio.isNotEmpty) {
        final nuevoPrecio = JsonParser.toDouble(cambio['precio'], item.precio);
        final nuevoPrecioOriginal = JsonParser.toDouble(cambio['precioOriginal'], item.precioOriginal);
        if (nuevoPrecio != item.precio || nuevoPrecioOriginal != item.precioOriginal) {
          huboCambio = true;
          return item.copyWith(
            precio: nuevoPrecio,
            precioOriginal: nuevoPrecioOriginal,
          );
        }
      }
      return item;
    }).toList();

    if (huboCambio) {
      state = state.copyWith(items: nuevos);
      _sincronizarStorage(nuevos);
    }
  }

  void vaciarCarrito() {
    state = state.copyWith(items: const []);
    _sincronizarStorage(const []);
  }

  void limpiarCarrito() => vaciarCarrito();

  void actualizarStockDisponible(List<ProductVariant> variantes) {
    final Map<int, int> stockPorVariante = {
      for (final v in variantes) v.idVariante: v.stock < 0 ? 0 : v.stock,
    };

    bool cambios = false;
    final nuevos = state.items.map((item) {
      if (stockPorVariante.containsKey(item.varianteId)) {
        final nuevoStock = stockPorVariante[item.varianteId]!;
        if (item.stockMaximo != nuevoStock) {
          cambios = true;
          final cantAjustada = nuevoStock > 0 ? item.cantidad.clamp(1, nuevoStock) : item.cantidad;
          return item.copyWith(
            stockMaximo: nuevoStock,
            cantidad: cantAjustada,
          );
        }
      }
      return item;
    }).toList();

    if (cambios) {
      state = state.copyWith(items: nuevos);
      _sincronizarStorage(nuevos);
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
