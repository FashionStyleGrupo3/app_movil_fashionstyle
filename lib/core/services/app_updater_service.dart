import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const int kAppBuildNumber = 3;
const String kAppVersion = '1.1.1';

class AppUpdaterService {
  static final AppUpdaterService _instance = AppUpdaterService._internal();
  static AppUpdaterService get instance => _instance;

  AppUpdaterService._internal();

  static const String versionCheckUrl =
      'https://raw.githubusercontent.com/FashionStyleGrupo3/app_movil_fashionstyle/main/instalador/version.json';
  static const MethodChannel _installerChannel = MethodChannel('fashionstyle/apk_installer');

  bool _verificando = false;
  bool _dialogoAbierto = false;
  DateTime? _ultimaVerificacion;

  /// Verifica automáticamente si existe una nueva versión en GitHub sin botones manuales.
  Future<void> verificarActualizacionAutomatica(BuildContext context) async {
    if (_verificando || _dialogoAbierto) return;

    // Throttle checks to once every 2 minutes unless resumed
    final ahora = DateTime.now();
    if (_ultimaVerificacion != null && ahora.difference(_ultimaVerificacion!).inMinutes < 2) {
      return;
    }

    _verificando = true;
    _ultimaVerificacion = ahora;

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ),
      );

      final url = '$versionCheckUrl?t=${ahora.millisecondsSinceEpoch}';
      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : (response.data is String ? Map<String, dynamic>.from(response.data as Map) : null);

        if (data == null) return;

        final remoteBuildNumber = int.tryParse(data['buildNumber']?.toString() ?? '0') ?? 0;
        final remoteVersion = data['version']?.toString() ?? '1.1.0';
        final apkUrl = data['apkUrl']?.toString();
        final notas = data['notes']?.toString() ?? 'Mejoras y correcciones generales.';

        if (remoteBuildNumber > kAppBuildNumber && apkUrl != null && apkUrl.isNotEmpty) {
          if (context.mounted && !_dialogoAbierto) {
            _mostrarModalActualizacion(
              context,
              version: remoteVersion,
              buildNumber: remoteBuildNumber,
              apkUrl: apkUrl,
              notas: notas,
            );
          }
        }
      }
    } catch (e) {
      // Falla silenciosa si no hay internet o GitHub no responde
      debugPrint('[AppUpdaterService] Verificación silenciosa omitida: $e');
    } finally {
      _verificando = false;
    }
  }

  void _mostrarModalActualizacion(
    BuildContext context, {
    required String version,
    required int buildNumber,
    required String apkUrl,
    required String notas,
  }) {
    _dialogoAbierto = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _DialogoDescargaActualizacion(
          version: version,
          buildNumber: buildNumber,
          apkUrl: apkUrl,
          notas: notas,
          onCerrar: () {
            _dialogoAbierto = false;
          },
        );
      },
    ).then((_) {
      _dialogoAbierto = false;
    });
  }

  /// Descarga el APK y lanza el instalador nativo de Android
  static Future<void> instalarApk(String filePath) async {
    try {
      await _installerChannel.invokeMethod('installApk', {'filePath': filePath});
    } on PlatformException catch (e) {
      debugPrint('[AppUpdaterService] Error al invocar instalador de paquetes: ${e.message}');
    }
  }
}

class _DialogoDescargaActualizacion extends StatefulWidget {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String notas;
  final VoidCallback onCerrar;

  const _DialogoDescargaActualizacion({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.notas,
    required this.onCerrar,
  });

  @override
  State<_DialogoDescargaActualizacion> createState() => _DialogoDescargaActualizacionState();
}

class _DialogoDescargaActualizacionState extends State<_DialogoDescargaActualizacion> {
  bool _descargando = false;
  double _progreso = 0.0;
  String _estadoTexto = '';
  String? _error;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    // Iniciar descarga automáticamente al aparecer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iniciarDescargaEInstalacion();
    });
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    widget.onCerrar();
    super.dispose();
  }

  Future<void> _iniciarDescargaEInstalacion() async {
    setState(() {
      _descargando = true;
      _progreso = 0.0;
      _estadoTexto = 'Preparando descarga...';
      _error = null;
    });

    _cancelToken = CancelToken();

    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/fashionstyle-v${widget.version}.apk';
      final file = File(targetPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      final dio = Dio();
      await dio.download(
        widget.apkUrl,
        targetPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (recibidos, totales) {
          if (totales > 0) {
            final p = recibidos / totales;
            final mbRecibidos = (recibidos / (1024 * 1024)).toStringAsFixed(1);
            final mbTotales = (totales / (1024 * 1024)).toStringAsFixed(1);
            setState(() {
              _progreso = p;
              _estadoTexto = 'Descargando actualización: $mbRecibidos MB de $mbTotales MB (${(p * 100).toInt()}%)';
            });
          } else {
            final mbRecibidos = (recibidos / (1024 * 1024)).toStringAsFixed(1);
            setState(() {
              _estadoTexto = 'Descargando actualización: $mbRecibidos MB...';
            });
          }
        },
      );

      setState(() {
        _estadoTexto = 'Abriendo instalador de Android...';
        _progreso = 1.0;
      });

      await AppUpdaterService.instalarApk(targetPath);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _descargando = false;
          _error = 'No se pudo completar la descarga: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.system_update_rounded, color: Color(0xFF111111)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Actualización v${widget.version}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.notas,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 18),
            if (_descargando) ...[
              LinearProgressIndicator(
                value: _progreso > 0 ? _progreso : null,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF111111),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              Text(
                _estadoTexto,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_descargando)
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text('Más tarde', style: TextStyle(color: Colors.grey)),
          ),
        if (!_descargando)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
            ),
            onPressed: _iniciarDescargaEInstalacion,
            child: const Text('Reintentar'),
          ),
      ],
    );
  }
}
