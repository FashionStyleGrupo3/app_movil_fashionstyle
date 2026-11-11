// @source-mirror: src/services/productoServicio.js, src/services/clasificacionServicio.js
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/price_info.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';

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
