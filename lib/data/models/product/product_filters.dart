// @source-mirror: src/services/productoServicio.js, src/services/clasificacionServicio.js

class ProductFilters {
  final int? categoriaId;
  final int? catalogoId;
  final String? busqueda;
  final bool? activo;
  final bool? publicado;
  final bool esPersonal;

  const ProductFilters({
    this.categoriaId,
    this.catalogoId,
    this.busqueda,
    this.activo,
    this.publicado,
    this.esPersonal = false,
  });
}
