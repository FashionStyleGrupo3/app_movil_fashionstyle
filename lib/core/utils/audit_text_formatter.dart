// @source-mirror: src/services/usuarioServicio.js, src/services/seguridadServicio.js, src/utils/auditoriaTexto.js
import 'dart:convert';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/audit/audit_models.dart';
import 'package:intl/intl.dart';

class AuditTextFormatter {
  static const List<String> _mesesCortos = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  static const List<String> _mesesLargos = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];

  static const List<String> _diasSemana = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  static String formatearUsuario(dynamic userRaw) {
    if (userRaw == null) return 'Sistema';
    if (userRaw is String) {
      final s = userRaw.trim();
      return s.isNotEmpty ? s : 'Sistema';
    }
    if (userRaw is Map) {
      final nombre = userRaw['nombre'] ?? userRaw['name'] ?? userRaw['usuario'];
      final correo = userRaw['correo'] ?? userRaw['email'];
      if (nombre != null && correo != null && nombre.toString().trim().isNotEmpty && correo.toString().trim().isNotEmpty) {
        return '${nombre.toString().trim()} (${correo.toString().trim()})';
      }
      if (nombre != null && nombre.toString().trim().isNotEmpty) return nombre.toString().trim();
      if (correo != null && correo.toString().trim().isNotEmpty) return correo.toString().trim();
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
    'Pedido': {'nombre': 'pedido', 'articulo': 'el', 'plural': 'Pedidos'},
    'Factura': {'nombre': 'factura', 'articulo': 'la', 'plural': 'Facturas'},
    'Cliente': {'nombre': 'cliente', 'articulo': 'el', 'plural': 'Clientes'},
    'OrdenProduccion': {'nombre': 'orden de producción', 'articulo': 'la', 'plural': 'Producción'},
    'FormulaProduccion': {'nombre': 'fórmula de producción', 'articulo': 'la', 'plural': 'Fórmulas'},
    'MateriaPrima': {'nombre': 'materia prima', 'articulo': 'la', 'plural': 'Materias Primas'},
    'Promocion': {'nombre': 'promoción', 'articulo': 'la', 'plural': 'Promociones'},
    'Categoria': {'nombre': 'categoría', 'articulo': 'la', 'plural': 'Categorías'},
    'Catalogo': {'nombre': 'colección', 'articulo': 'la', 'plural': 'Colecciones'},
    'ConfiguracionAlertaStock': {'nombre': 'alerta de stock', 'articulo': 'la', 'plural': 'Alertas de Stock'},
    'Proveedor': {'nombre': 'proveedor', 'articulo': 'el', 'plural': 'Proveedores'},
    'Pago': {'nombre': 'pago', 'articulo': 'el', 'plural': 'Pagos'},
  };

  static const Map<String, String> modeloGenerico = {
    'nombre': 'registro',
    'articulo': 'el',
    'plural': 'Registros',
  };

  static const Map<String, Map<String, String>> acciones = {
    'created': {'etiqueta': 'Creación', 'verbo': 'creó'},
    'creacion': {'etiqueta': 'Creación', 'verbo': 'creó'},
    'updated': {'etiqueta': 'Actualización', 'verbo': 'modificó'},
    'actualizacion': {'etiqueta': 'Actualización', 'verbo': 'modificó'},
    'deleted': {'etiqueta': 'Eliminación', 'verbo': 'eliminó'},
    'eliminacion': {'etiqueta': 'Eliminación', 'verbo': 'eliminó'},
    'inicio_sesion': {'etiqueta': 'Inicio de Sesión', 'verbo': 'inició sesión'},
    'login': {'etiqueta': 'Inicio de Sesión', 'verbo': 'inició sesión'},
    'anulado': {'etiqueta': 'Anulación', 'verbo': 'anuló'},
    'cancelado': {'etiqueta': 'Cancelación', 'verbo': 'canceló'},
    'estado': {'etiqueta': 'Cambio de Estado', 'verbo': 'cambió estado de'},
  };

  static const Map<String, String> etiquetas = {
    'codigo': 'Código',
    'nombre': 'Nombre',
    'descripcion': 'Descripción',
    'color': 'Color',
    'talla': 'Talla',
    'categoria_id': 'Categoría',
    'catalogo_id': 'Colección',
    'precio_venta': 'Precio de venta',
    'precio': 'Precio',
    'costo': 'Costo',
    'valor': 'Valor',
    'activo': 'Activo',
    'publicado': 'Publicado en tienda',
    'numero_comprobante': 'N.º comprobante',
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
    'via': 'Método de acceso',
    'ultimo_acceso': 'Último acceso',
    'stock_minimo': 'Stock mínimo',
    'descuento': 'Descuento',
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
    final limpio = campo.replaceAll(RegExp(r'_id$'), '').replaceAll('_', ' ').trim();
    if (limpio.isEmpty) return campo;
    return limpio[0].toUpperCase() + (limpio.length > 1 ? limpio.substring(1) : '');
  }

  static bool esCampoVisible(String campo) {
    return !ocultos.contains(campo) && !campo.startsWith('id_') && !campo.startsWith('password');
  }

  static String formatearFecha(dynamic valor, [bool conHora = true]) {
    if (valor == null) return '';
    final fecha = DateTime.tryParse(valor.toString());
    if (fecha == null) return valor.toString();

    try {
      final formato = conHora
          ? DateFormat("d 'de' MMMM 'de' y, h:mm a", 'es_CO')
          : DateFormat("d 'de' MMMM 'de' y", 'es_CO');
      return formato.format(fecha);
    } catch (_) {
      final mes = _mesesCortos[fecha.month - 1];
      if (!conHora) return '${fecha.day} de $mes de ${fecha.year}';
      final hora = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
      final ampm = fecha.hour >= 12 ? 'p.m.' : 'a.m.';
      final minStr = fecha.minute.toString().padLeft(2, '0');
      return '${fecha.day} de $mes de ${fecha.year}, $hora:$minStr $ampm';
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
    if (campo.endsWith('_at') || campo.startsWith('fecha_') || campo == 'ultimo_acceso') {
      return formatearFecha(valor);
    }

    if (valor is Map) {
      if (valor.isEmpty) return '—';
      return valor.entries
          .map((e) => '${etiquetaCampo(e.key.toString())}: ${formatearValor(e.key.toString(), e.value)}')
          .join(', ');
    }

    if (valor is List) {
      if (valor.isEmpty) return '—';
      return valor.map((e) => formatearValor(campo, e)).join(', ');
    }

    if (valor is String) {
      final s = valor.trim();
      if ((s.startsWith('{') && s.endsWith('}')) || (s.startsWith('[') && s.endsWith(']'))) {
        try {
          final decoded = jsonDecode(s);
          return formatearValor(campo, decoded);
        } catch (_) {}
      }
    }

    final texto = valor.toString();
    final corto = texto.length > 90 ? '${texto.substring(0, 90)}…' : texto;
    if (corto.isNotEmpty && RegExp(r'^[a-záéíóúüñÁÉÍÓÚÜÑ]', unicode: true).hasMatch(corto)) {
      return corto[0].toUpperCase() + (corto.length > 1 ? corto.substring(1) : '');
    }
    return corto;
  }

  static Map<String, dynamic> extraerMapaSeguro(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    if (raw is String) {
      final s = raw.trim();
      if (s.startsWith('{') && s.endsWith('}')) {
        try {
          final dec = jsonDecode(s);
          if (dec is Map) {
            return dec.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {}
      }
    }
    return {};
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
    final accion = item['accion']?.toString().toLowerCase() ?? '';
    if (accion != 'updated' || cambios.isEmpty) return null;

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
    final accionNorm = accionRaw.toLowerCase().replaceAll(' ', '_');
    final accionDef = acciones[accionNorm] ?? acciones[accionRaw] ?? {'etiqueta': accionRaw, 'verbo': 'registró'};
    final accion = AuditActionInfo(
      etiqueta: accionDef['etiqueta'] ?? accionRaw,
      verbo: accionDef['verbo'] ?? 'registró',
    );

    final Map<String, dynamic> antes = extraerMapaSeguro(item['datos_anteriores']);
    final Map<String, dynamic> nuevos = extraerMapaSeguro(item['datos_nuevos']);

    final Map<String, dynamic> referencia = {...antes, ...nuevos};
    final nombre = _nombreDelRegistro(referencia);

    List<AuditFieldChange> cambios = [];
    List<AuditFieldData> datos = [];

    if (accionNorm == 'updated' || accionNorm == 'actualizacion') {
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
      final origen = (accionNorm == 'deleted' || accionNorm == 'eliminacion') ? antes : nuevos;
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

    final bool soloInterno = (accionNorm == 'updated' || accionNorm == 'actualizacion') && cambios.isEmpty;
    final userMap = item['usuario'] is Map ? item['usuario'] as Map : null;
    final actor = JsonParser.toStr(userMap?['nombre'], 'El sistema');
    final verbo = _verboEspecial(item, cambios) ?? accion.verbo;
    final modeloId = item['modelo_id'];
    final sujeto = nombre != null && nombre.isNotEmpty
        ? (nombre.startsWith('#') ? nombre : '«$nombre»')
        : (modeloId != null ? '#$modeloId' : '');

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
      return texto.isNotEmpty ? (texto[0].toUpperCase() + (texto.length > 1 ? texto.substring(1) : '')) : texto;
    } catch (_) {
      final diaSemana = _diasSemana[fecha.weekday - 1];
      final mes = _mesesLargos[fecha.month - 1];
      return '$diaSemana, ${fecha.day} de $mes de ${fecha.year}';
    }
  }
}
