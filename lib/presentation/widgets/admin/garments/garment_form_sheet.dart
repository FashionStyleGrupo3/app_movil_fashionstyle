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
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre de la prenda es obligatorio')));
      return;
    }

    if (_variantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes registrar al menos una talla para la prenda')));
      return;
    }

    for (int i = 0; i < _variantes.length; i++) {
      final v = _variantes[i];
      final talla = v['talla']?.toString().trim() ?? '';
      final precio = double.tryParse(v['precio']?.toString() ?? v['precio_venta']?.toString() ?? '') ?? 0;
      if (talla.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La talla en la fila #${i + 1} es obligatoria')),
        );
        return;
      }
      if (precio <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El precio de venta en la fila #${i + 1} debe ser mayor a 0')),
        );
        return;
      }
    }

    setState(() => _guardando = true);
    try {
      final color = _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : 'Estándar';

      if (widget.prenda == null) {
        // --- 1. CREACIÓN ---
        final variantesPayload = _variantes.map((v) {
          final talla = v['talla']?.toString().trim() ?? 'U';
          final sku = (v['sku'] != null && v['sku'].toString().trim().isNotEmpty)
              ? v['sku'].toString().trim()
              : '${nombre.replaceAll(RegExp(r'\s+'), '-').toUpperCase()}-$talla-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
          final precio = double.tryParse(v['precio']?.toString() ?? v['precio_venta']?.toString() ?? '0') ?? 0.0;
          return {
            'talla': talla,
            'sku': sku,
            'precio_venta': precio,
          };
        }).toList();

        final payload = {
          'nombre': nombre,
          'descripcion': _descCtrl.text.trim(),
          'color': color,
          'activo': true,
          'publicado': true,
          'categoria_id': _categoriaId,
          'catalogo_id': _catalogoId,
          'variantes': variantesPayload,
        };

        final resp = await ApiClient.instance.dio.post('/productos', data: payload);
        final dataRes = ApiResponseParser.extractData(resp);
        final idProducto = dataRes is Map<String, dynamic> ? (dataRes['id_producto'] ?? dataRes['id']) : null;

        if (idProducto != null) {
          // Ajuste de stock inicial en inventarios
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
                    'tipo_movimiento': 'ENTRADA',
                    'cantidad': cant,
                    'motivo': 'Stock inicial al registrar prenda',
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
        for (final v in _variantes) {
          final varId = v['id_variante'];
          final talla = v['talla']?.toString().trim() ?? 'U';
          final sku = (v['sku'] != null && v['sku'].toString().trim().isNotEmpty)
              ? v['sku'].toString().trim()
              : '${nombre.replaceAll(RegExp(r'\s+'), '-').toUpperCase()}-$talla-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
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
                  'tipo_movimiento': 'ENTRADA',
                  'cantidad': cant,
                  'motivo': 'Stock inicial de nueva variante',
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible guardar la prenda. Verifica los datos ingresados.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
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
            const SizedBox(height: 16),

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
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imagenesEliminadas.add(img.idImagen);
                                        _imagenesExistentes.remove(img);
                                      });
                                    },
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
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imagenesNuevas.removeAt(idx);
                                      });
                                    },
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
