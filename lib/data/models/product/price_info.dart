// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import 'package:fashion_style_mobile/data/models/product/promotion.dart';

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
