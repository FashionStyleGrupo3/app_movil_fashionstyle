// @source-mirror: src/composables/useFormatoMoneda.js
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _copFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );

  static String formatearCOP(num? valor) {
    if (valor == null || valor.isNaN) {
      return r'$ 0';
    }
    return _copFormatter.format(valor).replaceAll('\u00A0', ' ');
  }
}
