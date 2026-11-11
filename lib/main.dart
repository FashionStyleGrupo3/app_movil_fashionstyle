// @source-mirror: src/main.js, src/App.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/app.dart';
import 'package:fashion_style_mobile/core/realtime/reverb_service.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ReverbService.instance.iniciarTiempoReal();
  runApp(
    const ProviderScope(
      child: FashionStyleApp(),
    ),
  );
}
