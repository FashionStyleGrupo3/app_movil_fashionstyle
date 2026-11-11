// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:fashion_style_mobile/core/network/api_client.dart';

String mensajeError(dynamic error, [String defecto = 'Ocurrió un error inesperado.']) {
  return ApiClient.obtenerMensajeError(error, defecto);
}

// --- SERVICIO DE PRODUCCIÓN ---
