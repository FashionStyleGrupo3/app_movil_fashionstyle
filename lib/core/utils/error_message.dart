// @source-mirror: src/services/Produccionservicio.js, src/services/calculadoraApi.js
import 'package:fashion_style_mobile/core/network/api_client.dart';

String mensajeError(
  dynamic error, [
  String defecto = 'No se pudo completar la operación. Por favor intenta nuevamente.',
]) {
  return ApiClient.obtenerMensajeError(error, defecto);
}

String sanitizarMensajeError(
  dynamic error, [
  String defecto = 'No se pudo completar la operación. Por favor intenta nuevamente.',
]) {
  return ApiClient.obtenerMensajeError(error, defecto);
}
