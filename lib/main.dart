// @source-mirror: src/main.js, src/App.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/realtime/reverb_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/fashion_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ReverbService.instance.iniciarTiempoReal();
  runApp(
    const ProviderScope(
      child: FashionStyleApp(),
    ),
  );
}

class FashionStyleApp extends ConsumerWidget {
  const FashionStyleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Fashion Style',
      debugShowCheckedModeBanner: false,
      theme: FashionTheme.lightTheme,
      routerConfig: router,
    );
  }
}
