// @source-mirror: src/services/usuarioServicio.js, src/services/seguridadServicio.js, src/utils/auditoriaTexto.js
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';
import '../../core/utils/currency_formatter.dart';

// --- SERVICIO DE USUARIOS Y CUENTA (UserService) ---

class UserService {
  static final UserService _instance = UserService._internal();
  static UserService get instance => _instance;

  UserService._internal();

  Future<Map<String, dynamic>> obtenerPerfilActual() async {
    final response = await ApiClient.instance.dio.get('/me');
    final datos = ApiResponseParser.extractData(response);
    if (datos is Map<String, dynamic>) {
      final user = datos['user'] ?? datos['usuario'];
      if (user is Map<String, dynamic>) return user;
      return datos;
    }
    return {};
  }

  Future<Map<String, dynamic>> actualizarPerfil(Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.put('/me', data: datos);
    final cuerpo = ApiResponseParser.extractData(response);
    if (cuerpo is Map<String, dynamic>) {
      final user = cuerpo['user'] ?? cuerpo['usuario'];
      if (user is Map<String, dynamic>) return user;
      return cuerpo;
    }
    return {};
  }

  Future<Map<String, dynamic>> actualizarContrasena({
    required String passwordActual,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await ApiClient.instance.dio.put(
      '/me/password',
      data: {
        'password_actual': passwordActual,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> solicitarCambioCorreo(String correoNuevo) async {
    final response = await ApiClient.instance.dio.post(
      '/me/email-change/request',
      data: {'correo_nuevo': correoNuevo},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> confirmarCambioCorreo(String codigo) async {
    final response = await ApiClient.instance.dio.post(
      '/me/email-change/confirm',
      data: {'codigo': codigo},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> subirFotoPerfil(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'foto': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await ApiClient.instance.dio.post(
      '/me/foto',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    final cuerpo = ApiResponseParser.extractData(response);
    if (cuerpo is Map<String, dynamic>) {
      final user = cuerpo['user'] ?? cuerpo['usuario'];
      if (user is Map<String, dynamic>) return user;
      return cuerpo;
    }
    return {};
  }

  Future<Map<String, dynamic>> usarFotoDeGoogle(String credential) async {
    final response = await ApiClient.instance.dio.post(
      '/me/foto/google',
      data: {'credential': credential},
    );
    final cuerpo = ApiResponseParser.extractData(response);
    if (cuerpo is Map<String, dynamic>) {
      final user = cuerpo['user'] ?? cuerpo['usuario'];
      if (user is Map<String, dynamic>) return user;
      return cuerpo;
    }
    return {};
  }

  Future<Map<String, dynamic>> quitarFotoPerfil() async {
    final response = await ApiClient.instance.dio.delete('/me/foto');
    final cuerpo = ApiResponseParser.extractData(response);
    if (cuerpo is Map<String, dynamic>) {
      final user = cuerpo['user'] ?? cuerpo['usuario'];
      if (user is Map<String, dynamic>) return user;
      return cuerpo;
    }
    return {};
  }
}

// --- SERVICIO DE SEGURIDAD Y CLIENTES (SecurityService) ---

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  static SecurityService get instance => _instance;

  SecurityService._internal();

  List<Map<String, dynamic>> _extraerLista(dynamic respuesta) {
    final datos = ApiResponseParser.extractData(respuesta);
    if (datos is List) {
      return datos.whereType<Map<String, dynamic>>().toList();
    }
    if (datos is Map<String, dynamic> && datos['data'] is List) {
      return (datos['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    final response = await ApiClient.instance.dio.get('/clientes');
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> actualizarCliente(int id, Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.put('/clientes/$id', data: datos);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final response = await ApiClient.instance.dio.get('/usuarios');
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> crearUsuario(Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.post('/usuarios', data: datos);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> actualizarUsuario(int id, Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.put('/usuarios/$id', data: datos);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> asignarRolUsuario(int id, String rol) async {
    final response = await ApiClient.instance.dio.post(
      '/usuarios/$id/asignar-rol',
      data: {'rol': rol},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<PaginatedResponse<Map<String, dynamic>>> obtenerAuditorias([
    Map<String, dynamic>? filtros,
  ]) async {
    final response = await ApiClient.instance.dio.get(
      '/auditorias',
      queryParameters: filtros,
    );
    return ApiResponseParser.extractPaginated<Map<String, dynamic>>(
      response,
      (map) => map,
    );
  }
}

// --- FORMATEADOR DE BITÁCORA (AuditTextFormatter) ---

class AuditModelInfo {
  final String clave;
  final String nombre;
  final String articulo;
  final String plural;

  const AuditModelInfo({
    required this.clave,
    required this.nombre,
    required this.articulo,
    required this.plural,
  });
}

class AuditActionInfo {
  final String etiqueta;
  final String verbo;

  const AuditActionInfo({
    required this.etiqueta,
    required this.verbo,
  });
}

class AuditFieldChange {
  final String campo;
  final String etiqueta;
  final String antes;
  final String nuevo;
  final dynamic nuevoCrudo;

  const AuditFieldChange({
    required this.campo,
    required this.etiqueta,
    required this.antes,
    required this.nuevo,
    this.nuevoCrudo,
  });
}

class AuditFieldData {
  final String campo;
  final String etiqueta;
  final String valor;

  const AuditFieldData({
    required this.campo,
    required this.etiqueta,
    required this.valor,
  });
}

class AuditDescription {
  final AuditModelInfo modelo;
  final AuditActionInfo accion;
  final String actor;
  final String verbo;
  final String sujeto;
  final List<AuditFieldChange> cambios;
  final List<AuditFieldData> datos;
  final bool soloInterno;

  const AuditDescription({
    required this.modelo,
    required this.accion,
    required this.actor,
    required this.verbo,
    required this.sujeto,
    required this.cambios,
    required this.datos,
    required this.soloInterno,
  });

  String get titulo {
    if (soloInterno) {
      return '$actor actualizó campos internos de $sujeto';
    }
    final accionStr = verbo.isNotEmpty ? verbo : accion.etiqueta;
    return '$actor $accionStr $sujeto'.trim();
  }

  @override
  String toString() => titulo;
}

class AuditTextFormatter {
  static String formatearUsuario(dynamic userRaw) {
    if (userRaw == null) return 'Sistema';
    if (userRaw is String) {
      final s = userRaw.trim();
      return s.isNotEmpty ? s : 'Sistema';
    }
    if (userRaw is Map) {
      final nombre = userRaw['nombre'] ?? userRaw['name'] ?? userRaw['usuario'];
      final correo = userRaw['correo'] ?? userRaw['email'];
      if (nombre != null && correo != null && nombre.toString().isNotEmpty && correo.toString().isNotEmpty) {
        return '${nombre.toString().trim()} (${correo.toString().trim()})';
      }
      if (nombre != null && nombre.toString().isNotEmpty) return nombre.toString().trim();
      if (correo != null && correo.toString().isNotEmpty) return correo.toString().trim();
      final id = userRaw['id_usuario'] ?? userRaw['id'];
      if (id != null) return 'Usuario #$id';
      return 'Sistema';
    }
    return userRaw.toString();
  }

  static const Map<String, Map<String, String>> modelos = {
    'Producto': {'nombre': 'producto', 'articulo': 'el', 'plural': 'Productos'},
    'Venta': {'nombre': 'venta', 'articulo': 'la', 'plural': 'Ventas'},
    'Inventario': {'nombre': 'movimiento de inventario', 'articulo': 'el', 'plural': 'Inventario'},
    'User': {'nombre': 'usuario', 'articulo': 'el', 'plural': 'Usuarios'},
  };

  static const Map<String, String> modeloGenerico = {
    'nombre': 'registro',
    'articulo': 'el',
    'plural': 'Registros',
  };

  static const Map<String, Map<String, String>> acciones = {
    'created': {'etiqueta': 'Creado', 'verbo': 'creó'},
    'updated': {'etiqueta': 'Modificado', 'verbo': 'modificó'},
    'deleted': {'etiqueta': 'Eliminado', 'verbo': 'eliminó'},
  };

  static const Map<String, String> etiquetas = {
    'codigo': 'Código',
    'nombre': 'Nombre',
    'descripcion': 'Descripción',
    'color': 'Color',
    'categoria_id': 'Categoría',
    'catalogo_id': 'Colección',
    'precio_venta': 'Precio de venta',
    'activo': 'Activo',
    'publicado': 'Publicado en la tienda',
    'numero_comprobante': 'N.º de comprobante',
    'pedido_id': 'Pedido',
    'usuario_id': 'Responsable',
    'cliente_nombre': 'Cliente',
    'categoria': 'Categoría',
    'notas': 'Notas',
    'fecha_venta': 'Fecha de venta',
    'monto_total': 'Total',
    'medio_pago': 'Medio de pago',
    'estado': 'Estado',
    'cancelada': 'Cancelada',
    'producto_id': 'Producto',
    'variante_id': 'Variante',
    'tipo_movimiento': 'Tipo de movimiento',
    'concepto': 'Concepto',
    'observaciones': 'Observaciones',
    'cantidad': 'Cantidad',
    'fecha_registro': 'Fecha de registro',
    'diferencia': 'Diferencia de stock',
    'correo': 'Correo',
    'correo_pendiente': 'Correo pendiente de confirmar',
    'telefono': 'Teléfono',
    'direccion': 'Dirección',
    'ciudad': 'Ciudad',
    'email_verified_at': 'Correo verificado el',
    'terminos_version': 'Versión de términos',
    'terminos_aceptados_at': 'Términos aceptados el',
    'foto_perfil': 'Foto de perfil',
  };

  static const Set<String> ocultos = {
    'id',
    'created_at',
    'updated_at',
    'deleted_at',
    'remember_token',
    'google_id',
    'codigo_verificacion',
    'codigo_verificacion_enviado_at',
    'codigo_cambio_correo',
    'codigo_cambio_correo_enviado_at',
  };

  static const Set<String> booleanos = {'activo', 'publicado', 'cancelada'};
  static const Set<String> dinero = {'precio_venta', 'monto_total', 'precio', 'costo', 'valor'};

  static AuditModelInfo infoModelo(dynamic modelo) {
    final clase = modelo?.toString().split(r'\').last ?? '';
    final def = modelos[clase] ?? modeloGenerico;
    return AuditModelInfo(
      clave: clase,
      nombre: def['nombre'] ?? clase.toLowerCase(),
      articulo: def['articulo'] ?? 'el',
      plural: def['plural'] ?? 'Registros',
    );
  }

  static String etiquetaCampo(String campo) {
    if (etiquetas.containsKey(campo)) return etiquetas[campo]!;
    final limpio = campo.replaceAll(RegExp(r'_id$'), '').replaceAll('_', ' ');
    return limpio.isEmpty ? campo : limpio[0].toUpperCase() + limpio.substring(1);
  }

  static bool esCampoVisible(String campo) {
    return !ocultos.contains(campo) && !campo.startsWith('id_') && !campo.startsWith('password');
  }

  static String formatearFecha(dynamic valor, [bool conHora = true]) {
    if (valor == null) return '';
    final fecha = DateTime.tryParse(valor.toString());
    if (fecha == null) return valor.toString();

    final formato = conHora
        ? DateFormat("d 'de' MMMM 'de' y, h:mm a", 'es_CO')
        : DateFormat("d 'de' MMMM 'de' y", 'es_CO');
    try {
      return formato.format(fecha);
    } catch (_) {
      return conHora
          ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
          : '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  static String formatearValor(String campo, dynamic valor) {
    if (valor == null || valor == '') return '—';

    if (booleanos.contains(campo)) {
      final b = JsonParser.toBool(valor);
      return b ? 'Sí' : 'No';
    }

    if (dinero.contains(campo)) {
      final n = double.tryParse(valor.toString());
      if (n != null) return CurrencyFormatter.formatearCOP(n);
    }

    if (campo == 'foto_perfil') return 'Imagen cargada';
    if (campo.endsWith('_id')) return '#$valor';
    if (campo.endsWith('_at') || campo.startsWith('fecha_')) return formatearFecha(valor);

    if (valor is Map) {
      return valor.values.map((e) => e?.toString() ?? '').join(', ');
    }

    final texto = valor.toString();
    final corto = texto.length > 90 ? '${texto.substring(0, 90)}…' : texto;
    if (corto.isNotEmpty && RegExp(r'^[a-záéíóúüñÁÉÍÓÚÜÑ]', unicode: true).hasMatch(corto)) {
      return corto[0].toUpperCase() + corto.substring(1);
    }
    return corto;
  }

  static String? _nombreDelRegistro(Map<String, dynamic> datos) {
    final candidato = datos['nombre'] ??
        datos['numero_comprobante'] ??
        datos['concepto'] ??
        datos['cliente_nombre'] ??
        datos['correo'];
    return candidato?.toString();
  }

  static String? _verboEspecial(Map<String, dynamic> item, List<AuditFieldChange> cambios) {
    if (item['accion']?.toString() != 'updated' || cambios.isEmpty) return null;

    final Map<String, AuditFieldChange> porCampo = {
      for (final c in cambios) c.campo: c,
    };

    if (cambios.length == 1 && porCampo.containsKey('activo')) {
      final activo = JsonParser.toBool(porCampo['activo']!.nuevoCrudo);
      return activo ? 'activó' : 'desactivó';
    }
    if (porCampo.containsKey('cancelada') && JsonParser.toBool(porCampo['cancelada']!.nuevoCrudo)) {
      return 'canceló';
    }
    if (porCampo.containsKey('estado') &&
        porCampo['estado']!.nuevoCrudo?.toString().toLowerCase() == 'anulado') {
      return 'anuló';
    }

    return null;
  }

  static AuditDescription describirAuditoria(Map<String, dynamic> item) {
    final modelo = infoModelo(item['modelo']);
    final accionRaw = item['accion']?.toString() ?? 'updated';
    final accionDef = acciones[accionRaw] ?? {'etiqueta': accionRaw, 'verbo': 'registró'};
    final accion = AuditActionInfo(
      etiqueta: accionDef['etiqueta']!,
      verbo: accionDef['verbo']!,
    );

    final Map<String, dynamic> antes = item['datos_anteriores'] is Map<String, dynamic>
        ? item['datos_anteriores'] as Map<String, dynamic>
        : {};
    final Map<String, dynamic> nuevos = item['datos_nuevos'] is Map<String, dynamic>
        ? item['datos_nuevos'] as Map<String, dynamic>
        : {};

    final Map<String, dynamic> referencia = {...antes, ...nuevos};
    final nombre = _nombreDelRegistro(referencia);

    List<AuditFieldChange> cambios = [];
    List<AuditFieldData> datos = [];

    if (accionRaw == 'updated') {
      final Set<String> todosCampos = {...antes.keys, ...nuevos.keys};
      final camposVisibles = todosCampos.where(esCampoVisible).toList();

      for (final campo in camposVisibles) {
        final antesFmt = formatearValor(campo, antes[campo]);
        final nuevoFmt = formatearValor(campo, nuevos[campo]);
        if (antesFmt != nuevoFmt) {
          cambios.add(
            AuditFieldChange(
              campo: campo,
              etiqueta: etiquetaCampo(campo),
              antes: antesFmt,
              nuevo: nuevoFmt,
              nuevoCrudo: nuevos[campo],
            ),
          );
        }
      }
    } else {
      final origen = accionRaw == 'deleted' ? antes : nuevos;
      for (final campo in origen.keys.where(esCampoVisible)) {
        final val = origen[campo];
        if (val != null && val != '') {
          datos.add(
            AuditFieldData(
              campo: campo,
              etiqueta: etiquetaCampo(campo),
              valor: formatearValor(campo, val),
            ),
          );
        }
      }
    }

    final bool soloInterno = accionRaw == 'updated' && cambios.isEmpty;
    final userMap = item['usuario'] is Map ? item['usuario'] as Map : null;
    final actor = JsonParser.toStr(userMap?['nombre'], 'El sistema');
    final verbo = _verboEspecial(item, cambios) ?? accion.verbo;
    final modeloId = item['modelo_id'];
    final sujeto = nombre ?? (modeloId != null ? '#$modeloId' : '');

    return AuditDescription(
      modelo: modelo,
      accion: accion,
      actor: actor,
      verbo: verbo,
      sujeto: sujeto,
      cambios: cambios,
      datos: datos,
      soloInterno: soloInterno,
    );
  }

  static String tiempoRelativo(dynamic valor) {
    if (valor == null) return 'Sin fecha';
    final fecha = DateTime.tryParse(valor.toString());
    if (fecha == null) return 'Sin fecha';

    final segundos = ((DateTime.now().millisecondsSinceEpoch - fecha.millisecondsSinceEpoch) / 1000).round();
    if (segundos < 45) return 'hace unos segundos';
    if (segundos < 3600) return 'hace ${(segundos / 60).round()} min';
    if (segundos < 86400) return 'hace ${(segundos / 3600).round()} h';

    return '${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  static String etiquetaDia(dynamic valor) {
    if (valor == null) return 'Sin fecha';
    final fecha = DateTime.tryParse(valor.toString());
    if (fecha == null) return 'Sin fecha';

    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final inicioFecha = DateTime(fecha.year, fecha.month, fecha.day);

    final dias = inicioHoy.difference(inicioFecha).inDays;
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Ayer';

    try {
      final texto = DateFormat("EEEE, d 'de' MMMM 'de' y", 'es_CO').format(fecha);
      return texto.isNotEmpty ? texto[0].toUpperCase() + texto.substring(1) : texto;
    } catch (_) {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
