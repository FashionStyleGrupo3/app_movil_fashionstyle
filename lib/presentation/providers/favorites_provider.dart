// @source-mirror: src/stores/favoritos.js
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_style_mobile/data/services/favorites_service.dart';
class FavoritesState {
  final List<int> ids;
  final bool soloFavoritos;

  const FavoritesState({
    this.ids = const [],
    this.soloFavoritos = false,
  });

  int get total => ids.length;

  bool esFavorito(int id) => ids.contains(id);

  FavoritesState copyWith({
    List<int>? ids,
    bool? soloFavoritos,
  }) {
    return FavoritesState(
      ids: ids ?? this.ids,
      soloFavoritos: soloFavoritos ?? this.soloFavoritos,
    );
  }
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState()) {
    inicializarDesdeStorage();
  }

  static const String _claveStorage = 'favoritos';

  Future<void> inicializarDesdeStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_claveStorage);
      if (guardado != null && guardado.isNotEmpty && guardado != 'undefined') {
        final decoded = jsonDecode(guardado);
        if (decoded is List) {
          final ids = decoded.map((e) => int.tryParse(e.toString())).whereType<int>().toList();
          state = state.copyWith(ids: ids);
        }
      }
    } catch (_) {}
  }

  Future<void> _sincronizarStorage(List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveStorage, jsonEncode(ids));
    } catch (_) {}
  }

  void setSoloFavoritos(bool valor) {
    state = state.copyWith(soloFavoritos: valor);
  }

  Future<void> alternar(int id, {required bool estaAutenticado}) async {
    final eraFavorito = state.esFavorito(id);
    final anteriores = List<int>.from(state.ids);
    final nuevos = eraFavorito
        ? state.ids.where((x) => x != id).toList()
        : [...state.ids, id];

    state = state.copyWith(ids: nuevos);
    _sincronizarStorage(nuevos);

    if (!estaAutenticado) return;

    try {
      if (eraFavorito) {
        await FavoritesService.instance.quitarFavoritoApi(id);
      } else {
        await FavoritesService.instance.agregarFavoritoApi(id);
      }
    } catch (_) {
      state = state.copyWith(ids: anteriores);
      _sincronizarStorage(anteriores);
    }
  }

  Future<void> cargarDesdeServidor({required bool estaAutenticado}) async {
    if (!estaAutenticado) return;
    try {
      final sincronizados = await FavoritesService.instance.sincronizarFavoritosApi(state.ids);
      state = state.copyWith(ids: sincronizados);
      _sincronizarStorage(sincronizados);
    } catch (_) {}
  }

  void limpiar() {
    state = const FavoritesState();
    _sincronizarStorage(const []);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier();
});
