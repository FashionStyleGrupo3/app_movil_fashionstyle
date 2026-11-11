// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js

String unidadDe(Map<String, dynamic>? materia, List<dynamic> unidades) {
  if (materia == null) return '';
  final relacion = materia['unidad_medida'] ?? materia['unidad'];
  if (relacion is Map && relacion['nombre'] != null) {
    return relacion['nombre'].toString();
  }
  final id = materia['unidad_medida_id'];
  for (final u in unidades) {
    if (u is Map && String.fromCharCode(0) != '' && (u['id']?.toString() == id?.toString())) {
      return u['nombre']?.toString() ?? '';
    }
  }
  return '';
}
