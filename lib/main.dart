// @source-mirror: src/main.js, src/App.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/app.dart';
import 'package:fashion_style_mobile/core/network/change_bus.dart';
import 'package:fashion_style_mobile/core/realtime/reverb_service.dart';
import 'package:fashion_style_mobile/presentation/screens/common/placeholder_screen.dart';
import 'package:fashion_style_mobile/core/router/route_screens.dart';
import 'package:fashion_style_mobile/core/router/app_router.dart';
import 'package:fashion_style_mobile/core/router/auth_router_listenable.dart';
import 'package:fashion_style_mobile/core/config/app_version.dart';
import 'package:fashion_style_mobile/data/services/app_updater_service.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ReverbService.instance.iniciarTiempoReal();
  runApp(
    const ProviderScope(
      child: FashionStyleApp(),
    ),
  );
}
