// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/price_info.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';

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
