// @source-mirror: src/services/usuarioServicio.js, src/services/seguridadServicio.js, src/utils/auditoriaTexto.js

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
