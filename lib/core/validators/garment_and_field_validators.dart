// @source-mirror: src/utils/validacionCampos.js, src/utils/validacionPrenda.js

class FieldPatterns {
  static final Map<String, RegExp> patrones = {
    'persona': RegExp(r"[^\p{L}\p{M} .'-]", unicode: true),
    'comercial': RegExp(r"[^\p{L}\p{M}\p{N} %&.,'’/()-]", unicode: true),
    'identificacion': RegExp(r"[^\p{L}\p{M}\p{N}.-]", unicode: true),
    'cuenta': RegExp(r'[^A-Z0-9-]', caseSensitive: false),
    'codigo': RegExp(r'[^A-Z0-9_-]', caseSensitive: false),
    'abreviatura': RegExp(r"[^\p{L}\p{M}\p{N}%./-]", unicode: true),
    'direccion': RegExp(r"[^\p{L}\p{M}\p{N} #.,/-]", unicode: true),
    'numerico': RegExp(r'\D'),
    'texto': RegExp(r"[^\p{L}\p{M}\p{N} .,;:!?¡¿'’“”()/#-]", unicode: true),
  };

  static final Map<String, RegExp> patronesPrenda = {
    'nombre': RegExp(r'[^\p{L}\p{M}\p{N} ]', unicode: true),
    'color': RegExp(r'[^\p{L}\p{M} ]', unicode: true),
    'descripcion': RegExp(r"[^\p{L}\p{M}\p{N} .,;:!?¡¿'’“”()\- \n\r]", unicode: true),
    'talla': RegExp(r'[^\p{L}\p{M} ]', unicode: true),
    'sku': RegExp(r'[^A-Z0-9_-]'),
    'opcion': RegExp(r'[^\p{L}\p{M}\p{N} ]', unicode: true),
  };

  static const Map<String, int> limitesCampo = {
    'nombre': 60,
    'color': 30,
    'descripcion': 500,
    'talla': 20,
    'sku': 24,
    'opcion': 40,
  };
}

String filtrarCampo(String? valor, String tipo, int limite) {
  final texto = valor ?? '';
  if (tipo == 'codigo') {
    final limpio = texto.toUpperCase().replaceAll(FieldPatterns.patrones['codigo']!, '');
    return limpio.length > limite ? limpio.substring(0, limite) : limpio;
  }

  if (tipo == 'telefono') {
    final sinEspacios = texto.trimLeft();
    final prefijo = sinEspacios.startsWith('+') ? '+' : '';
    final digitos = sinEspacios.replaceAll(RegExp(r'\D'), '');
    final recortado = digitos.length > 15 ? digitos.substring(0, 15) : digitos;
    final combinado = '$prefijo$recortado';
    return combinado.length > limite ? combinado.substring(0, limite) : combinado;
  }

  final patron = FieldPatterns.patrones[tipo];
  if (patron == null) {
    return texto.length > limite ? texto.substring(0, limite) : texto;
  }

  final limpio = texto.replaceAll(patron, '');
  return limpio.length > limite ? limpio.substring(0, limite) : limpio;
}

bool validarCorreo(String? valor) {
  final correo = (valor ?? '').trim();
  if (correo.isEmpty || correo.length > 254) return false;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo);
}

String filtrarNumero(String? valor, {int maxEnteros = 9, int maxDecimales = 0}) {
  final texto = (valor ?? '').replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
  final punto = texto.indexOf('.');
  final enteroPart = punto < 0 ? texto : texto.substring(0, punto);
  final entero = enteroPart.length > maxEnteros ? enteroPart.substring(0, maxEnteros) : enteroPart;

  if (punto < 0 || maxDecimales == 0) return entero;

  final decimalPart = texto.substring(punto + 1).replaceAll('.', '');
  final decimales = decimalPart.length > maxDecimales
      ? decimalPart.substring(0, maxDecimales)
      : decimalPart;

  return '$entero.$decimales';
}

Map<String, dynamic> normalizarDatosEntrega(Map<String, dynamic> datos) {
  final resultado = Map<String, dynamic>.from(datos);
  resultado['nombre'] = filtrarCampo(datos['nombre']?.toString(), 'persona', 100).trim();
  resultado['telefono'] = filtrarCampo(datos['telefono']?.toString(), 'telefono', 20).trim();
  resultado['ciudad'] = filtrarCampo(datos['ciudad']?.toString(), 'persona', 80).trim();
  resultado['departamento'] =
      filtrarCampo(datos['departamento']?.toString(), 'persona', 80).trim();
  resultado['direccion'] = filtrarCampo(datos['direccion']?.toString(), 'direccion', 180).trim();
  return resultado;
}

String validarDatosEntrega(Map<String, dynamic> datos) {
  final normalizados = normalizarDatosEntrega(datos);
  final nombre = normalizados['nombre']?.toString() ?? '';
  final telefono = normalizados['telefono']?.toString() ?? '';
  final ciudad = normalizados['ciudad']?.toString() ?? '';
  final direccion = normalizados['direccion']?.toString() ?? '';

  if (!RegExp(r'[\p{L}\p{M}]', unicode: true).hasMatch(nombre)) {
    return 'Escribe el nombre de quien recibe el pedido.';
  }
  if (!RegExp(r'^\+?\d{7,15}$').hasMatch(telefono)) {
    return 'El teléfono debe tener entre 7 y 15 dígitos.';
  }
  if (!RegExp(r'[\p{L}\p{M}]', unicode: true).hasMatch(ciudad)) {
    return 'Escribe una ciudad válida.';
  }
  if (!RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(direccion)) {
    return 'Escribe una dirección válida.';
  }
  return '';
}

String filtrarNumerico(
  dynamic valor, {
  int maxEnteros = 10,
  int maxDecimales = 0,
  bool permitirNegativo = false,
}) {
  if (valor == null || valor == '') return '';
  var texto = valor.toString().replaceAll(',', '.');

  if (permitirNegativo && texto.trim().startsWith('-')) {
    texto = '-${texto.replaceAll('-', '').replaceAll(RegExp(r'[^\d.]'), '')}';
  } else {
    texto = texto.replaceAll(RegExp(r'[^\d.]'), '');
  }

  final esNegativo = texto.startsWith('-');
  final sinSigno = esNegativo ? texto.substring(1) : texto;
  final punto = sinSigno.indexOf('.');

  var entero = punto < 0 ? sinSigno : sinSigno.substring(0, punto);
  if (entero.isEmpty) entero = '0';
  if (entero.length > maxEnteros) {
    entero = entero.substring(0, maxEnteros);
  }

  if (punto < 0 || maxDecimales == 0) {
    final resultado = '${esNegativo ? '-' : ''}$entero';
    return resultado == '-' ? '' : resultado;
  }

  final decimalesRaw = sinSigno.substring(punto + 1).replaceAll('.', '');
  final decimales = decimalesRaw.length > maxDecimales
      ? decimalesRaw.substring(0, maxDecimales)
      : decimalesRaw;

  return '${esNegativo ? '-' : ''}$entero.$decimales';
}

String filtrarAlfanumerico(dynamic valor, [int limite = 50]) {
  if (valor == null) return '';
  final limpio = valor.toString().replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  return limpio.length > limite ? limpio.substring(0, limite) : limpio;
}

String filtrarIdentificacion(dynamic valor, [int limite = 20]) {
  if (valor == null) return '';
  final limpio = valor.toString().replaceAll(RegExp(r'[^A-Za-z0-9.-]'), '');
  return limpio.length > limite ? limpio.substring(0, limite) : limpio;
}

String filtrarCampoPrenda(String campo, String? valor) {
  final texto = valor ?? '';
  if (campo == 'sku') {
    final skuLimpio = texto
        .toUpperCase()
        .replaceAll(FieldPatterns.patronesPrenda['sku']!, '');
    final limite = FieldPatterns.limitesCampo['sku']!;
    return skuLimpio.length > limite ? skuLimpio.substring(0, limite) : skuLimpio;
  }

  final patron = FieldPatterns.patronesPrenda[campo];
  final limite = FieldPatterns.limitesCampo[campo];
  if (patron == null || limite == null) return texto;

  final limpio = texto.replaceAll(patron, '');
  return limpio.length > limite ? limpio.substring(0, limite) : limpio;
}

bool validarCampoPrenda(String campo, String? valor) {
  final texto = (valor ?? '').trim();
  final limite = FieldPatterns.limitesCampo[campo];
  if (limite == null || texto.isEmpty || texto.length > limite) return false;
  return filtrarCampoPrenda(campo, texto) == texto;
}

String filtrarPrecio(String? valor) {
  final texto = (valor ?? '').replaceAll(RegExp(r'[^\d.]'), '');
  final punto = texto.indexOf('.');
  if (punto == -1) {
    return texto.length > 9 ? texto.substring(0, 9) : texto;
  }
  final enteroPart = texto.substring(0, punto);
  final entero = enteroPart.length > 9 ? enteroPart.substring(0, 9) : enteroPart;
  final decPart = texto.substring(punto + 1).replaceAll('.', '');
  final decimales = decPart.length > 2 ? decPart.substring(0, 2) : decPart;
  return '$entero.$decimales';
}

bool validarPrecio(dynamic valor) {
  if (valor == null) return false;
  final texto = valor.toString().trim();
  if (!RegExp(r'^\d{1,9}(?:\.\d{1,2})?$').hasMatch(texto)) return false;
  final numVal = double.tryParse(texto);
  return numVal != null && numVal.isFinite;
}

String filtrarStock(String? valor) {
  final texto = (valor ?? '').replaceAll(RegExp(r'\D'), '');
  return texto.length > 9 ? texto.substring(0, 9) : texto;
}

bool validarStock(dynamic valor) {
  if (valor == null) return false;
  final texto = valor.toString().trim();
  if (!RegExp(r'^\d{1,9}$').hasMatch(texto)) return false;
  final numVal = int.tryParse(texto);
  return numVal != null && numVal >= 0;
}

bool validarArchivoImagen({required String mimeType, required int sizeInBytes}) {
  const permitidos = {'image/jpeg', 'image/png', 'image/webp'};
  return permitidos.contains(mimeType.toLowerCase()) &&
      sizeInBytes > 0 &&
      sizeInBytes <= 4 * 1024 * 1024;
}

String filtrarEntero(dynamic valor, [int maxDigitos = 9]) {
  if (valor == null || valor == '') return '';
  final limpio = valor.toString().replaceAll(RegExp(r'\D'), '');
  return limpio.length > maxDigitos ? limpio.substring(0, maxDigitos) : limpio;
}

String filtrarDecimal(dynamic valor, {int maxEnteros = 9, int maxDecimales = 2}) {
  if (valor == null || valor == '') return '';
  final texto = valor.toString().replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
  final punto = texto.indexOf('.');
  if (punto == -1) {
    return texto.length > maxEnteros ? texto.substring(0, maxEnteros) : texto;
  }
  final enteroPart = texto.substring(0, punto);
  final enteroTrunc = enteroPart.length > maxEnteros ? enteroPart.substring(0, maxEnteros) : enteroPart;
  final entero = enteroTrunc.isEmpty ? '0' : enteroTrunc;
  final decPart = texto.substring(punto + 1).replaceAll('.', '');
  final decimales = decPart.length > maxDecimales ? decPart.substring(0, maxDecimales) : decPart;
  return decimales.isNotEmpty ? '$entero.$decimales' : entero;
}
