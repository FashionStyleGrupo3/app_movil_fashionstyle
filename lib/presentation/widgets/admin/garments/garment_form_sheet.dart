// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';

// Modal de Creación / Edición de Prenda
class ModalFormularioPrenda extends StatefulWidget {
  final Product? prenda;
  final List<Category> categorias;
  final List<Catalog> catalogos;
  final VoidCallback onGuardado;

  const ModalFormularioPrenda({
    super.key,
    this.prenda,
    required this.categorias,
    required this.catalogos,
    required this.onGuardado,
  });

  @override
  State<ModalFormularioPrenda> createState() => _ModalFormularioPrendaState();
}

class _ModalFormularioPrendaState extends State<ModalFormularioPrenda> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _colorCtrl = TextEditingController();

  int? _categoriaId;
  int? _catalogoId;
  bool _guardando = false;
  String? _errorMensaje;
  List<Map<String, dynamic>> _variantes = [];
  late List<Category> _categoriasLocales;
  late List<Catalog> _catalogosLocales;

  // Manejo de Imágenes
  final List<XFile> _imagenesNuevas = [];
  List<ProductImage> _imagenesExistentes = [];
  final List<int> _imagenesEliminadas = [];

  @override
  void initState() {
    super.initState();
    _categoriasLocales = List.from(widget.categorias);
    _catalogosLocales = List.from(widget.catalogos);

    if (widget.prenda != null) {
      final p = widget.prenda!;
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion;
      _colorCtrl.text = p.original['color']?.toString() ?? 'Estándar';
      _categoriaId = p.categoria?.idCategoria;
      _catalogoId = p.catalogo?.idCatalogo;
      _imagenesExistentes = List.from(p.imagenes);
      _variantes = p.variantes.map((v) => {
        'id_variante': v.idVariante,
        'talla': v.talla,
        'sku': v.sku,
        'precio': v.precioVenta,
        'stock': v.stock,
      }).toList();
      if (_variantes.isEmpty) {
        _variantes = [
          {'talla': '', 'sku': '', 'precio': null, 'stock': 0},
        ];
      }
    } else {
      // Inicia con campos vacíos sin valores quemados (S 50000.0, M 50000.0)
      _variantes = [
        {'talla': '', 'sku': '', 'precio': null, 'stock': 0},
      ];
    }
  }

  Future<void> _seleccionarImagenesGaleria() async {
    try {
      final picker = ImagePicker();
      final seleccionadas = await picker.pickMultiImage(maxWidth: 1200, imageQuality: 85);
      if (seleccionadas.isNotEmpty) {
        setState(() {
          _imagenesNuevas.addAll(seleccionadas);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible seleccionar imágenes: $e')),
        );
      }
    }
  }

  Future<void> _tomarFotoCamara() async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 85);
      if (foto != null) {
        setState(() {
          _imagenesNuevas.add(foto);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible capturar la foto: $e')),
        );
      }
    }
  }

  Future<void> _crearCategoriaModal() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de categoría', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.brandAccent),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Crear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      try {
        final resp = await ApiClient.instance.dio.post('/categorias', data: {'nombre': res});
        final data = ApiResponseParser.extractData(resp);
        final nueva = Category.fromJson(data is Map<String, dynamic> ? data : {'id': DateTime.now().millisecondsSinceEpoch, 'nombre': res, 'activo': true});
        setState(() {
          _categoriasLocales.add(nueva);
          _categoriaId = nueva.idCategoria;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Categoría "$res" creada con éxito')));
      } catch (_) {
        final nueva = Category(idCategoria: DateTime.now().millisecondsSinceEpoch, nombre: res, descripcion: '', activo: true);
        setState(() {
          _categoriasLocales.add(nueva);
          _categoriaId = nueva.idCategoria;
        });
      }
    }
  }

  Future<void> _crearColeccionModal() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Colección'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de colección', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.brandAccent),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Crear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      try {
        final resp = await ApiClient.instance.dio.post('/catalogos', data: {'nombre': res});
        final data = ApiResponseParser.extractData(resp);
        final nuevo = Catalog.fromJson(data is Map<String, dynamic> ? data : {'id': DateTime.now().millisecondsSinceEpoch, 'nombre': res, 'activo': true});
        setState(() {
          _catalogosLocales.add(nuevo);
          _catalogoId = nuevo.idCatalogo;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Colección "$res" creada con éxito')));
      } catch (_) {
        final nuevo = Catalog(idCatalogo: DateTime.now().millisecondsSinceEpoch, nombre: res, descripcion: '', activo: true);
        setState(() {
          _catalogosLocales.add(nuevo);
          _catalogoId = nuevo.idCatalogo;
        });
      }
    }
  }

  void _agregarVariante() {
    setState(() {
      _variantes.add({'talla': '', 'sku': '', 'precio': null, 'stock': 0});
    });
  }

  Future<void> _guardarPrenda() async {
    setState(() => _errorMensaje = null);
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _errorMensaje = 'El nombre de la prenda es obligatorio.');
      return;
    }

    if (_variantes.isEmpty) {
      setState(() => _errorMensaje = 'Debes registrar al menos una talla para la prenda.');
      return;
    }

    final tallasVistas = <String>{};
    for (int i = 0; i < _variantes.length; i++) {
      final v = _variantes[i];
      final talla = v['talla']?.toString().trim() ?? '';
      final precioStr = v['precio']?.toString() ?? v['precio_venta']?.toString() ?? '';
      final precio = double.tryParse(precioStr) ?? 0.0;

      if (talla.isEmpty) {
        setState(() => _errorMensaje = 'La talla en la fila #${i + 1} es obligatoria.');
        return;
      }

      final tallaNorm = talla.toLowerCase();
      if (tallasVistas.contains(tallaNorm)) {
        setState(() => _errorMensaje = 'La talla "$talla" está repetida en varias filas. Cada variante debe tener una talla única.');
        return;
      }
      tallasVistas.add(tallaNorm);

      if (precio <= 0) {
        setState(() => _errorMensaje = 'El precio de venta para la talla "$talla" debe ser mayor a 0.');
        return;
      }

      if (precio > 99999999) {
        setState(() => _errorMensaje = 'El precio para la talla "$talla" excede el límite máximo permitido (\$99.999.999 COP).');
        return;
      }
    }

    setState(() => _guardando = true);
    try {
      final color = _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : 'Estándar';

      if (widget.prenda == null) {
        // --- 1. CREACIÓN ---
        final codigoAuto = 'FS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        final nombreSlug = nombre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

        final variantesPayload = _variantes.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          final talla = v['talla']?.toString().trim() ?? 'U';
          final sku = (v['sku'] != null && v['sku'].toString().trim().isNotEmpty)
              ? v['sku'].toString().trim()
              : 'FS-$nombreSlug-$talla-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}-$i';
          final precio = double.tryParse(v['precio']?.toString() ?? v['precio_venta']?.toString() ?? '0') ?? 0.0;
          return {
            'talla': talla,
            'sku': sku,
            'precio_venta': precio,
          };
        }).toList();

        final payload = {
          'codigo': codigoAuto,
          'nombre': nombre,
          'descripcion': _descCtrl.text.trim(),
          'color': color,
          'activo': true,
          'publicado': true,
          if (_categoriaId != null) 'categoria_id': _categoriaId,
          if (_catalogoId != null) 'catalogo_id': _catalogoId,
          'variantes': variantesPayload,
        };

        final resp = await ApiClient.instance.dio.post('/productos', data: payload);
        final dataRes = ApiResponseParser.extractData(resp);
        final idProducto = dataRes is Map<String, dynamic> ? (dataRes['id_producto'] ?? dataRes['id']) : null;

        if (idProducto != null) {
          // Ajuste de stock inicial en inventarios (lowercase tipo_movimiento y concepto requerido)
          final varsCreadas = (dataRes is Map && dataRes['variantes'] is List) ? dataRes['variantes'] as List : [];
          for (int i = 0; i < _variantes.length; i++) {
            final cant = int.tryParse(_variantes[i]['stock']?.toString() ?? '0') ?? 0;
            if (cant > 0 && i < varsCreadas.length) {
              final varId = varsCreadas[i]['id_variante'] ?? varsCreadas[i]['id'];
              if (varId != null) {
                try {
                  await ApiClient.instance.dio.post('/inventarios', data: {
                    'producto_id': idProducto,
                    'variante_id': varId,
                    'tipo_movimiento': 'entrada',
                    'concepto': 'Stock inicial al registrar prenda',
                    'cantidad': cant,
                  });
                } catch (_) {}
              }
            }
          }

          // Subida de imágenes nuevas
          for (int i = 0; i < _imagenesNuevas.length; i++) {
            final img = _imagenesNuevas[i];
            try {
              final formData = FormData.fromMap({
                'imagen': await MultipartFile.fromFile(img.path, filename: img.name),
                'es_principal': i == 0 ? 1 : 0,
                'orden': i,
              });
              await ApiClient.instance.dio.post(
                '/productos/$idProducto/imagenes',
                data: formData,
                options: Options(headers: {'Content-Type': 'multipart/form-data'}),
              );
            } catch (_) {}
          }
        }
      } else {
        // --- 2. EDICIÓN ---
        final idProducto = widget.prenda!.idProducto;

        // Actualizar datos base del producto con PATCH
        await ApiClient.instance.dio.patch('/productos/$idProducto', data: {
          'nombre': nombre,
          'descripcion': _descCtrl.text.trim(),
          'color': color,
          'categoria_id': _categoriaId,
          'catalogo_id': _catalogoId,
          'publicado': widget.prenda?.publicado ?? true,
        });

        // Actualizar o crear variantes
        final nombreSlug = nombre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
        for (int i = 0; i < _variantes.length; i++) {
          final v = _variantes[i];
          final varId = v['id_variante'];
          final talla = v['talla']?.toString().trim() ?? 'U';
          final sku = (v['sku'] != null && v['sku'].toString().trim().isNotEmpty)
              ? v['sku'].toString().trim()
              : 'FS-$nombreSlug-$talla-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}-$i';
          final precio = double.tryParse(v['precio']?.toString() ?? v['precio_venta']?.toString() ?? '0') ?? 0.0;
          final cant = int.tryParse(v['stock']?.toString() ?? '0') ?? 0;

          if (varId != null) {
            try {
              await ApiClient.instance.dio.put('/productos/variantes/$varId', data: {
                'talla': talla,
                'sku': sku,
                'precio_venta': precio,
              });
            } catch (_) {}
          } else {
            try {
              final resVar = await ApiClient.instance.dio.post('/productos/$idProducto/variantes', data: {
                'talla': talla,
                'sku': sku,
                'precio_venta': precio,
              });
              final dataV = ApiResponseParser.extractData(resVar);
              final newVarId = dataV is Map ? (dataV['id_variante'] ?? dataV['id']) : null;
              if (newVarId != null && cant > 0) {
                await ApiClient.instance.dio.post('/inventarios', data: {
                  'producto_id': idProducto,
                  'variante_id': newVarId,
                  'tipo_movimiento': 'entrada',
                  'concepto': 'Stock inicial de nueva variante',
                  'cantidad': cant,
                });
              }
            } catch (_) {}
          }
        }

        // Eliminar imágenes marcadas
        for (final imgId in _imagenesEliminadas) {
          try {
            await ApiClient.instance.dio.delete('/productos/imagenes/$imgId');
          } catch (_) {}
        }

        // Subir imágenes nuevas
        for (int i = 0; i < _imagenesNuevas.length; i++) {
          final img = _imagenesNuevas[i];
          try {
            final formData = FormData.fromMap({
              'imagen': await MultipartFile.fromFile(img.path, filename: img.name),
              'es_principal': (_imagenesExistentes.isEmpty && i == 0) ? 1 : 0,
              'orden': _imagenesExistentes.length + i,
            });
            await ApiClient.instance.dio.post(
              '/productos/$idProducto/imagenes',
              data: formData,
              options: Options(headers: {'Content-Type': 'multipart/form-data'}),
            );
          } catch (_) {}
        }
      }

      widget.onGuardado();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMensaje = ApiClient.obtenerMensajeError(e, 'No fue posible guardar la prenda. Verifica los datos ingresados.');
        });
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: FashionColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.prenda != null ? 'Editar Prenda' : 'Nueva Prenda de Catálogo',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
            ),
            const SizedBox(height: 12),
            if (_errorMensaje != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: FashionColors.statusDanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FashionColors.statusDanger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: FashionColors.statusDanger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMensaje!,
                        style: const TextStyle(color: FashionColors.statusDanger, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMensaje = null),
                      child: const Icon(Icons.close, color: FashionColors.statusDanger, size: 16),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),

            // SECCIÓN DE FOTOGRAFÍAS / IMÁGENES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Imágenes de la Prenda',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13, color: FashionColors.inkPrimary),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: _seleccionarImagenesGaleria,
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: const Text('Galería', style: TextStyle(fontSize: 11)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: _tomarFotoCamara,
                      icon: const Icon(Icons.photo_camera_outlined, size: 16),
                      label: const Text('Cámara', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 90,
              child: (_imagenesExistentes.isEmpty && _imagenesNuevas.isEmpty)
                  ? Container(
                      decoration: BoxDecoration(
                        color: FashionColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FashionColors.borderSubtle),
                      ),
                      child: Center(
                        child: Text(
                          'No hay imágenes seleccionadas. Agrega fotos desde galería o cámara.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                        ),
                      ),
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._imagenesExistentes.map((img) {
                          return Container(
                            width: 72,
                            height: 90,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FashionColors.borderSubtle),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: ImageUrlResolver.resolve(img.ruta),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, size: 24),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _imagenesEliminadas.add(img.idImagen);
                                        _imagenesExistentes.remove(img);
                                      });
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.topRight,
                                      padding: const EdgeInsets.all(4),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        ..._imagenesNuevas.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final xFile = entry.value;
                          return Container(
                            width: 72,
                            height: 90,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FashionColors.brandAccent, width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(xFile.path),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _imagenesNuevas.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.topRight,
                                      padding: const EdgeInsets.all(4),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de la prenda *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción detallada', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _colorCtrl,
              decoration: const InputDecoration(labelText: 'Color / Gama de tono', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: _categoriaId,
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                      ..._categoriasLocales.map((c) => DropdownMenuItem(value: c.idCategoria, child: Text(c.nombre, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _categoriaId = v),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '+ Categoría',
                  icon: const Icon(Icons.add_circle_outline, color: FashionColors.brandAccent, size: 26),
                  onPressed: _crearCategoriaModal,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: _catalogoId,
                    decoration: const InputDecoration(labelText: 'Colección / Catálogo', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin colección')),
                      ..._catalogosLocales.map((c) => DropdownMenuItem(value: c.idCatalogo, child: Text(c.nombre, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _catalogoId = v),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '+ Colección',
                  icon: const Icon(Icons.add_circle_outline, color: FashionColors.brandAccent, size: 26),
                  onPressed: _crearColeccionModal,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TALLAS Y VARIANTES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Tallas y Precios *',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14, color: FashionColors.inkPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _agregarVariante,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar talla'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Tallas sugeridas: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.inkMuted)),
                  ...['XS', 'S', 'M', 'L', 'XL', 'Única'].map((t) => ActionChip(
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.zero,
                    label: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        final existeVacia = _variantes.indexWhere((v) => (v['talla']?.toString().trim() ?? '').isEmpty);
                        if (existeVacia != -1) {
                          _variantes[existeVacia]['talla'] = t;
                        } else {
                          _variantes.add({'talla': t, 'sku': '', 'precio': null, 'stock': 0});
                        }
                      });
                    },
                  )),
                ],
              ),
            ),
            ..._variantes.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(color: FashionColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      child: TextFormField(
                        initialValue: item['talla']?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Talla',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => item['talla'] = val,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextFormField(
                        initialValue: item['precio']?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio venta',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final numVal = double.tryParse(val);
                          item['precio'] = numVal;
                          item['precio_venta'] = numVal;
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 58,
                      child: TextFormField(
                        initialValue: item['stock']?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => item['stock'] = int.tryParse(val) ?? 0,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18, color: FashionColors.peligro),
                      onPressed: () {
                        if (_variantes.length > 1) {
                          setState(() => _variantes.removeAt(idx));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Debe existir al menos una talla')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.brandAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _guardando ? null : _guardarPrenda,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.prenda != null ? 'Actualizar Prenda' : 'Crear Prenda', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
