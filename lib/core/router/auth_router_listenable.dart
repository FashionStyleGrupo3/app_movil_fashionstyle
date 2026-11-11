// @source-mirror: src/router/index.js
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';

class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        final antesAuth = previous?.estaAutenticado;
        final ahoraAuth = next.estaAutenticado;
        final antesPersonal = previous?.esPersonal;
        final ahoraPersonal = next.esPersonal;

        // Solo notificar al router si realmente cambió el acceso o autenticación
        if (antesAuth != ahoraAuth || antesPersonal != ahoraPersonal) {
          notifyListeners();
        }
      },
    );
  }
}

final authRouterListenableProvider = Provider<AuthRouterListenable>((ref) {
  return AuthRouterListenable(ref);
});
