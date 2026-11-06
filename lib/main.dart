// @source-mirror: src/main.js, src/App.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/change_bus.dart';
import 'core/realtime/reverb_service.dart';
import 'core/router/app_router.dart';
import 'core/services/app_updater_service.dart';
import 'core/theme/fashion_theme.dart';
import 'presentation/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ReverbService.instance.iniciarTiempoReal();
  runApp(
    const ProviderScope(
      child: FashionStyleApp(),
    ),
  );
}

class FashionStyleApp extends ConsumerStatefulWidget {
  const FashionStyleApp({super.key});

  @override
  ConsumerState<FashionStyleApp> createState() => _FashionStyleAppState();
}

class _FashionStyleAppState extends ConsumerState<FashionStyleApp> {
  AppLifecycleListener? _lifecycleListener;
  Timer? _sessionRefreshTimer;
  StreamSubscription? _changeBusSub;

  @override
  void initState() {
    super.initState();

    // 1. Verificación automática de actualización en lanzamiento (sin botones manuales en UI)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        AppUpdaterService.instance.verificarActualizacionAutomatica(ctx);
      }
      ref.read(authProvider.notifier).refrescarSesion();
    });

    // 2. Escuchar ciclo de vida de la app (onResume) para verificar actualizaciones y rol en vivo
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          AppUpdaterService.instance.verificarActualizacionAutomatica(ctx);
        }
        ref.read(authProvider.notifier).refrescarSesion();
      },
    );

    // 3. Sincronización automática de roles en vivo (ChangeBus 'usuarios' y Reverb)
    _changeBusSub = ChangeBus.instance.stream.listen((evento) {
      if (evento.recurso == 'usuarios' || evento.ruta.contains('usuario') || evento.recurso == 'roles') {
        ref.read(authProvider.notifier).refrescarSesion();
      }
    });

    // 4. Sondeo periódico de sesión cada 30 segundos (paridad estricta con Web PR #64)
    _sessionRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(authProvider.notifier).refrescarSesion();
    });
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _sessionRefreshTimer?.cancel();
    _changeBusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Fashion Style',
      debugShowCheckedModeBanner: false,
      theme: FashionTheme.lightTheme,
      routerConfig: router,
    );
  }
}
