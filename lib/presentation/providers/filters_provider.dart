// @source-mirror: src/stores/filtros.js
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FiltersState {
  final int? categoriaId;
  final int? catalogoId;
  final String busqueda;
  final String orden;

  const FiltersState({
    this.categoriaId,
    this.catalogoId,
    this.busqueda = '',
    this.orden = 'recientes',
  });

  FiltersState copyWith({
    int? categoriaId,
    int? catalogoId,
    String? busqueda,
    String? orden,
    bool limpiarCategoria = false,
    bool limpiarCatalogo = false,
  }) {
    return FiltersState(
      categoriaId: limpiarCategoria ? null : (categoriaId ?? this.categoriaId),
      catalogoId: limpiarCatalogo ? null : (catalogoId ?? this.catalogoId),
      busqueda: busqueda ?? this.busqueda,
      orden: orden ?? this.orden,
    );
  }
}

class FiltersNotifier extends StateNotifier<FiltersState> {
  FiltersNotifier() : super(const FiltersState());

  void establecerCategoria(int? id) {
    if (id == null) {
      state = state.copyWith(limpiarCategoria: true);
    } else {
      state = state.copyWith(categoriaId: id);
    }
  }

  void establecerCatalogo(int? id) {
    if (id == null) {
      state = state.copyWith(limpiarCatalogo: true);
    } else {
      state = state.copyWith(catalogoId: id);
    }
  }

  void establecerBusqueda(String texto) {
    state = state.copyWith(busqueda: texto);
  }

  void establecerOrden(String nuevoOrden) {
    state = state.copyWith(orden: nuevoOrden);
  }

  void limpiarFiltros() {
    state = const FiltersState(
      categoriaId: null,
      catalogoId: null,
      busqueda: '',
      orden: 'recientes',
    );
  }
}

final filtersProvider = StateNotifierProvider<FiltersNotifier, FiltersState>((ref) {
  return FiltersNotifier();
});
