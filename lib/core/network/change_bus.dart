// @source-mirror: src/utils/busCambios.js
import 'dart:async';

class DataChangeEvent {
  final String recurso;
  final String ruta;
  final int fecha;

  const DataChangeEvent({
    required this.recurso,
    required this.ruta,
    required this.fecha,
  });

  factory DataChangeEvent.fromMap(Map<String, dynamic> map) {
    return DataChangeEvent(
      recurso: map['recurso']?.toString() ?? '',
      ruta: map['ruta']?.toString() ?? '',
      fecha: map['fecha'] is int
          ? map['fecha'] as int
          : int.tryParse(map['fecha']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recurso': recurso,
      'ruta': ruta,
      'fecha': fecha,
    };
  }

  @override
  String toString() => 'DataChangeEvent(recurso: $recurso, ruta: $ruta, fecha: $fecha)';
}

const Set<String> rutasIgnoradas = {
  'login',
  'logout',
  'register',
  'auth',
  'forgot-password',
  'reset-password',
  'verify-email',
  'resend-verification',
};

class ChangeBus {
  static final ChangeBus instance = ChangeBus._internal();

  ChangeBus._internal();

  final StreamController<DataChangeEvent> _controller =
      StreamController<DataChangeEvent>.broadcast();

  Stream<DataChangeEvent> get stream => _controller.stream;

  static String normalizarRuta(String url, [String baseUrl = '']) {
    var ruta = url.trim();
    if (baseUrl.isNotEmpty && ruta.startsWith(baseUrl)) {
      ruta = ruta.substring(baseUrl.length);
    }
    ruta = ruta.replaceFirst(RegExp(r'^https?://[^/]+', caseSensitive: false), '');
    ruta = ruta.split('?')[0].split('#')[0];
    ruta = ruta.replaceFirst(RegExp(r'^/?api/'), '/');
    return ruta.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  void emitirCambio(String ruta) {
    final limpia = normalizarRuta(ruta);
    if (limpia.isEmpty) return;

    final recurso = limpia.split('/')[0];
    if (rutasIgnoradas.contains(recurso)) return;

    final evento = DataChangeEvent(
      recurso: recurso,
      ruta: limpia,
      fecha: DateTime.now().millisecondsSinceEpoch,
    );

    if (!_controller.isClosed) {
      _controller.add(evento);
    }
  }

  void recibirCambioRemoto(Map<String, dynamic> cambio) {
    final recurso = cambio['recurso']?.toString() ?? '';
    if (recurso.isEmpty || rutasIgnoradas.contains(recurso)) return;

    final evento = DataChangeEvent.fromMap(cambio);
    if (!_controller.isClosed) {
      _controller.add(evento);
    }
  }

  void dispose() {
    _controller.close();
  }
}
