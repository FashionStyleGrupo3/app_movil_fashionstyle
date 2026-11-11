// @source-mirror: src/services/tiempoReal.js, src/composables/useRecargaAutomatica.js
import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/change_bus.dart';

class ReverbService {
  static final ReverbService _instance = ReverbService._internal();
  static ReverbService get instance => _instance;

  ReverbService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _socketId;
  AppLifecycleListener? _lifecycleListener;
  bool _conectando = false;
  Timer? _reintentadorTimer;

  static const String appKey = String.fromEnvironment('REVERB_APP_KEY', defaultValue: 'k4nfvk20k6kwtiw5nbpe');
  static const String host = String.fromEnvironment('REVERB_HOST', defaultValue: 'fashionstyle.api.adsocidm.com');
  static const String port = String.fromEnvironment('REVERB_PORT', defaultValue: '443');
  static const String scheme = String.fromEnvironment('REVERB_SCHEME', defaultValue: 'https');

  String? get socketId => _socketId;

  void iniciarTiempoReal() {
    // Configurar listener para cuando la aplicación móvil pasa de segundo a primer plano
    _lifecycleListener ??= AppLifecycleListener(
      onResume: () {
        ChangeBus.instance.emitirCambio('app_resumed');
        if (_channel == null && appKey.isNotEmpty) {
          _conectarWebSocket();
        }
      },
    );

    if (appKey.isEmpty) {
      debugPrint('[ReverbService] Sin REVERB_APP_KEY: sincronización basada en ciclo de vida y ChangeBus.');
      return;
    }

    _conectarWebSocket();
  }

  void _conectarWebSocket() {
    if (_conectando || _channel != null) return;
    _conectando = true;

    try {
      final wsScheme = scheme == 'https' ? 'wss' : 'ws';
      final uri = Uri.parse(
        '$wsScheme://$host:$port/app/$appKey?protocol=7&client=js&version=8.4.0-reverb&flash=false',
      );

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (mensaje) {
          _procesarMensaje(mensaje);
        },
        onError: (err) {
          debugPrint('[ReverbService] Error en WebSocket Reverb: $err');
          _desconectarYReintentar();
        },
        onDone: () {
          debugPrint('[ReverbService] Conexión WebSocket cerrada.');
          _desconectarYReintentar();
        },
      );
      _conectando = false;
    } catch (e) {
      debugPrint('[ReverbService] No se pudo inicializar WebSocket: $e');
      _desconectarYReintentar();
    }
  }

  void _procesarMensaje(dynamic mensajeRaw) {
    try {
      final texto = mensajeRaw is String ? mensajeRaw : utf8.decode(mensajeRaw as List<int>);
      final map = jsonDecode(texto);
      if (map is! Map<String, dynamic>) return;

      final evento = map['event']?.toString() ?? '';
      final dataRaw = map['data'];
      Map<String, dynamic> data = {};
      if (dataRaw is String) {
        try {
          final decoded = jsonDecode(dataRaw);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (_) {}
      } else if (dataRaw is Map<String, dynamic>) {
        data = dataRaw;
      }

      if (evento == 'pusher:connection_established') {
        _socketId = data['socket_id']?.toString();
        if (_socketId != null && _socketId!.isNotEmpty) {
          ApiClient.instance.socketIdProvider = () => _socketId;
        }

        // Suscribirse al canal oficial de cambios del backend Laravel
        final suscripcion = jsonEncode({
          'event': 'pusher:subscribe',
          'data': {'channel': 'cambios'},
        });
        _channel?.sink.add(suscripcion);
      } else if (evento == 'pusher:ping') {
        _channel?.sink.add(jsonEncode({'event': 'pusher:pong', 'data': {}}));
      } else if (evento == '.datos.actualizados' || evento == 'datos.actualizados') {
        ChangeBus.instance.recibirCambioRemoto({
          'recurso': data['recurso']?.toString() ?? '',
          'ruta': data['ruta']?.toString() ?? data['recurso']?.toString() ?? '',
          'fecha': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (_) {}
  }

  void _desconectarYReintentar() {
    _conectando = false;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _socketId = null;

    _reintentadorTimer?.cancel();
    _reintentadorTimer = Timer(const Duration(seconds: 8), () {
      if (appKey.isNotEmpty) {
        _conectarWebSocket();
      }
    });
  }

  void dispose() {
    _reintentadorTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _lifecycleListener?.dispose();
    _channel = null;
  }
}
