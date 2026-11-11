// @source-mirror: src/views/admin/VistaPanelControl.vue, src/views/admin/VistaInventario.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _cargando = true;
  String? _error;

  List<_VarianteInventario> _todasLasVariantes = [];

  // Pestaña Kardex
  List<Map<String, dynamic>> _movimientos = [];
  Map<String, dynamic> _resumenKardex = {
    'total_movimientos': 0,
    'entradas': 0,
    'salidas': 0,
    'ajustes': 0,
    'anulados': 0,
  };
  final String _filtroTipoKardex = '';
  String _busquedaKardex = '';

  // Filtros Existencias
  String _busquedaExistencias = '';
  String _filtroDisponibilidad = 'todos'; // 'todos' | 'en_stock' | 'bajo_stock' | 'agotados'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatosInventario();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosInventario() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final prods = await ProductService.instance.obtenerProductos();

      // Aplanar variantes para existencias
      final listaVariantes = <_VarianteInventario>[];
      for (final p in prods) {
        for (final v in p.variantes) {
          listaVariantes.add(_VarianteInventario(
            varianteId: v.idVariante,
            productoId: p.idProducto,
            nombrePrenda: p.nombre,
            talla: v.talla,
            sku: v.sku,
            precioVenta: v.precioVenta,
            stock: v.stock,
            imagenUrl: p.primeraImagenUrl,
            color: p.original['color']?.toString() ?? 'Estándar',
          ));
        }
      }

      // Cargar movimientos de Kardex
      Map<String, dynamic> resumen = {};
      List<Map<String, dynamic>> movs = [];
      try {
        final res = await ApiClient.instance.dio.get('/inventarios');
        final data = ApiResponseParser.extractData(res);
        if (data is Map<String, dynamic>) {
          resumen = data['resumen'] is Map<String, dynamic> ? data['resumen'] : {};
          final listaRaw = data['movimientos'] ?? data['data'];
          if (listaRaw is List) {
            movs = listaRaw.whereType<Map<String, dynamic>>().toList();
          }
        } else if (data is List) {
          movs = data.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _todasLasVariantes = listaVariantes;
          _movimientos = movs;
          _resumenKardex = {
            'total_movimientos': resumen['total_movimientos'] ?? movs.length,
            'entradas': resumen['entradas'] ?? movs.where((m) => m['tipo_movimiento'] == 'entrada').length,
            'salidas': resumen['salidas'] ?? movs.where((m) => m['tipo_movimiento'] == 'salida').length,
            'ajustes': resumen['ajustes'] ?? movs.where((m) => m['tipo_movimiento'] == 'ajuste').length,
            'anulados': resumen['anulados'] ?? movs.where((m) => m['estado'] == 'anulado').length,
          };
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.obtenerMensajeError(e, 'No se pudieron cargar los datos del inventario.');
          _cargando = false;
        });
      }
    }
  }

  void _abrirModalRegistrarMovimiento([_VarianteInventario? varianteInicial]) {
    _VarianteInventario? seleccionada = varianteInicial ?? (_todasLasVariantes.isNotEmpty ? _todasLasVariantes.first : null);
    String tipo = 'entrada';
    final TextEditingController cantCtrl = TextEditingController(text: '1');
    final TextEditingController conceptoCtrl = TextEditingController();
    final TextEditingController obsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Registrar Movimiento de Kárdex',
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                    ),
                    const SizedBox(height: 16),

                    // Selector de prenda y variante
                    DropdownButtonFormField<_VarianteInventario>(
                      initialValue: seleccionada,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Prenda y Talla', border: OutlineInputBorder()),
                      items: _todasLasVariantes.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            '${v.nombrePrenda} (${v.talla}) · Stock: ${v.stock}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => seleccionada = val),
                    ),
                    const SizedBox(height: 12),

                    // Tipo de movimiento
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: const InputDecoration(labelText: 'Tipo de movimiento', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'entrada', child: Text('Entrada (+) - Abastecimiento/Producción')),
                        DropdownMenuItem(value: 'salida', child: Text('Salida (-) - Venta externa/Avería')),
                        DropdownMenuItem(value: 'ajuste', child: Text('Ajuste (=) - Corrección por conteo')),
                      ],
                      onChanged: (val) => setModalState(() => tipo = val ?? 'entrada'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: cantCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad de unidades *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: conceptoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Concepto *',
                        hintText: 'Ej. Recepción taller, Conteo físico...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: obsCtrl,
                      decoration: const InputDecoration(labelText: 'Observaciones (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.negroElegante,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (seleccionada == null || cantCtrl.text.isEmpty || conceptoCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor completa los campos requeridos')),
                          );
                          return;
                        }

                        final cant = int.tryParse(cantCtrl.text) ?? 0;
                        if (cant <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        try {
                          await ApiClient.instance.dio.post('/inventarios', data: {
                            'variante_id': seleccionada!.varianteId,
                            'tipo_movimiento': tipo,
                            'concepto': conceptoCtrl.text.trim(),
                            'observaciones': obsCtrl.text.trim(),
                            'cantidad': cant,
                          });
                          _cargarDatosInventario();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Movimiento de inventario guardado con éxito')),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible registrar el movimiento de inventario.')),
                              backgroundColor: FashionColors.peligro,
                            ),
                          );
                        }
                      },
                      child: const Text('Guardar Movimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _exportarKardexCsv() {
    if (_movimientos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay movimientos de kárdex para exportar')),
      );
      return;
    }

    final buffer = StringBuffer('ID,Fecha,Tipo,Concepto,Prenda,Talla,Cantidad,Observaciones\n');
    for (final m in _movimientos) {
      final id = m['id_movimiento'] ?? m['id'] ?? '';
      final fecha = m['created_at'] ?? m['fecha'] ?? '';
      final tipo = m['tipo_movimiento'] ?? '';
      final concepto = (m['concepto'] ?? '').toString().replaceAll(',', ';');
      final prenda = (m['producto']?['nombre'] ?? m['prenda'] ?? '').toString().replaceAll(',', ';');
      final talla = m['variante']?['talla'] ?? m['talla'] ?? '';
      final cant = m['cantidad'] ?? 0;
      final obs = (m['observaciones'] ?? '').toString().replaceAll(',', ';');
      buffer.writeln('$id,$fecha,$tipo,$concepto,$prenda,$talla,$cant,$obs');
    }

    Share.share(buffer.toString(), subject: 'Kardex_Inventario_FashionStyle.csv');
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/inventario',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: FashionColors.inkPrimary,
              unselectedLabelColor: FashionColors.inkSecondary,
              indicatorColor: FashionColors.brandAccent,
              labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.shelves, size: 18), text: 'Existencias'),
                Tab(icon: Icon(Icons.history, size: 18), text: 'Kárdex'),
                Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'Alertas'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
                : _error != null
                    ? Center(child: Text(_error!))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _construirPestanaExistencias(),
                          _construirPestanaKardex(),
                          _construirPestanaAlertas(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // 1. EXISTENCIAS EN BODEGA
  Widget _construirPestanaExistencias() {
    List<_VarianteInventario> filtradas = List.from(_todasLasVariantes);

    if (_busquedaExistencias.trim().isNotEmpty) {
      final q = _busquedaExistencias.trim().toLowerCase();
      filtradas = filtradas.where((v) {
        return v.nombrePrenda.toLowerCase().contains(q) ||
            v.sku.toLowerCase().contains(q) ||
            v.talla.toLowerCase().contains(q) ||
            v.color.toLowerCase().contains(q);
      }).toList();
    }

    if (_filtroDisponibilidad == 'en_stock') {
      filtradas = filtradas.where((v) => v.stock > 5).toList();
    } else if (_filtroDisponibilidad == 'bajo_stock') {
      filtradas = filtradas.where((v) => v.stock >= 1 && v.stock <= 5).toList();
    } else if (_filtroDisponibilidad == 'agotados') {
      filtradas = filtradas.where((v) => v.stock <= 0).toList();
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar por prenda, SKU, talla o color...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _busquedaExistencias = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chipDisponibilidad('todos', 'Todos (${_todasLasVariantes.length})'),
                    _chipDisponibilidad('en_stock', 'En stock (>5)'),
                    _chipDisponibilidad('bajo_stock', 'Bajo stock (1-5)'),
                    _chipDisponibilidad('agotados', 'Agotados (0)'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtradas.isEmpty
              ? const Center(
                  child: AtelierEmptyStateIllustration(
                    type: AtelierEmptyStateType.emptySearch,
                    title: 'Sin existencias coincidentes',
                    subtitle: 'No hay prendas que coincidan con los filtros aplicados.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final v = filtradas[index];
                    final colorStock = v.stock <= 0
                        ? FashionColors.statusDanger
                        : (v.stock <= 5 ? FashionColors.statusWarning : FashionColors.statusSuccess);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: FashionColors.borderSubtle),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 64,
                            child: v.imagenUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: v.imagenUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(color: FashionColors.surfaceMuted, child: const Icon(Icons.checkroom, color: FashionColors.inkPrimary)),
                                  )
                                : Container(color: FashionColors.surfaceMuted, child: const Icon(Icons.checkroom, color: FashionColors.inkPrimary)),
                          ),
                        ),
                        title: Text(v.nombrePrenda, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
                        subtitle: Text(
                          'Talla: ${v.talla} · Color: ${v.color}\nSKU: ${v.sku}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: FashionColors.inkSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorStock.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colorStock.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${v.stock} uds',
                                style: GoogleFonts.jetBrainsMono(color: colorStock, fontWeight: FontWeight.w700, fontSize: 11.5),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20, color: FashionColors.inkPrimary),
                              tooltip: 'Ajustar stock',
                              onPressed: () => _abrirModalRegistrarMovimiento(v),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chipDisponibilidad(String val, String label) {
    final sel = _filtroDisponibilidad == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : FashionColors.textoOscuro)),
        selected: sel,
        selectedColor: FashionColors.negroElegante,
        onSelected: (_) => setState(() => _filtroDisponibilidad = val),
      ),
    );
  }

  // 2. KÁRDEX Y MOVIMIENTOS
  Widget _construirPestanaKardex() {
    List<Map<String, dynamic>> filtrados = List.from(_movimientos);

    if (_filtroTipoKardex.isNotEmpty) {
      filtrados = filtrados.where((m) => m['tipo_movimiento'] == _filtroTipoKardex).toList();
    }

    if (_busquedaKardex.trim().isNotEmpty) {
      final q = _busquedaKardex.trim().toLowerCase();
      filtrados = filtrados.where((m) {
        final conc = (m['concepto'] ?? '').toString().toLowerCase();
        final pren = (m['producto']?['nombre'] ?? m['prenda'] ?? '').toString().toLowerCase();
        return conc.contains(q) || pren.contains(q);
      }).toList();
    }

    return Column(
      children: [
        // TARJETAS DE RESUMEN
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  _tarjetaStat('Movimientos', '${_resumenKardex['total_movimientos']}', const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _tarjetaStat('Entradas (+)', '${_resumenKardex['entradas']}', FashionColors.verdeExito),
                  const SizedBox(width: 8),
                  _tarjetaStat('Salidas (-)', '${_resumenKardex['salidas']}', FashionColors.peligro),
                  const SizedBox(width: 8),
                  _tarjetaStat('Ajustes (=)', '${_resumenKardex['ajustes']}', const Color(0xFFD97706)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Filtrar por concepto o prenda...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _busquedaKardex = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Exportar CSV',
                    onPressed: _exportarKardexCsv,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: FashionColors.rosaCorporativo),
                    tooltip: 'Nuevo Movimiento',
                    onPressed: () => _abrirModalRegistrarMovimiento(),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(child: Text('No hay movimientos registrados en el kárdex'))
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final m = filtrados[index];
                    final tipo = m['tipo_movimiento']?.toString() ?? 'ajuste';
                    final esEntrada = tipo == 'entrada';
                    final colorTipo = esEntrada
                        ? FashionColors.verdeExito
                        : (tipo == 'salida' ? FashionColors.peligro : const Color(0xFFD97706));

                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: FashionColors.grisBorde),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorTipo.withValues(alpha: 0.12),
                          child: Icon(
                            esEntrada ? Icons.arrow_downward : (tipo == 'salida' ? Icons.arrow_upward : Icons.tune),
                            color: colorTipo,
                            size: 18,
                          ),
                        ),
                        title: Text(m['concepto']?.toString() ?? 'Movimiento', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          '${m['created_at'] ?? m['fecha'] ?? ''} · ${m['producto']?['nombre'] ?? m['prenda'] ?? 'Prenda'}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          '${esEntrada ? '+' : (tipo == 'salida' ? '-' : '')}${m['cantidad']} uds',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorTipo, fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _tarjetaStat(String label, String valor, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(color: col.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(valor, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: FashionColors.textoMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // 3. ALERTAS DE STOCK BAJO O AGOTADO
  Widget _construirPestanaAlertas() {
    final enAlerta = _todasLasVariantes.where((v) => v.stock <= 5).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    if (enAlerta.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, size: 48, color: FashionColors.verdeExito),
              SizedBox(height: 12),
              Text('¡Inventario en orden!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('No hay prendas con stock crítico o agotado actualmente.', style: TextStyle(color: FashionColors.textoMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
      itemCount: enAlerta.length,
      itemBuilder: (context, index) {
        final v = enAlerta[index];
        final agotado = v.stock <= 0;

        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: agotado ? FashionColors.peligro.withValues(alpha: 0.4) : FashionColors.aviso.withValues(alpha: 0.4)),
          ),
          child: ListTile(
            leading: Icon(
              agotado ? Icons.cancel_outlined : Icons.warning_amber_rounded,
              color: agotado ? FashionColors.peligro : FashionColors.aviso,
              size: 28,
            ),
            title: Text(v.nombrePrenda, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Talla: ${v.talla} · SKU: ${v.sku}', style: const TextStyle(fontSize: 11)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.negroElegante,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => _abrirModalRegistrarMovimiento(v),
              child: Text(agotado ? 'Agotado (Reabastecer)' : 'Quedan ${v.stock} (Reabastecer)', style: const TextStyle(fontSize: 11)),
            ),
          ),
        );
      },
    );
  }
}

class _VarianteInventario {
  final int varianteId;
  final int productoId;
  final String nombrePrenda;
  final String talla;
  final String sku;
  final double precioVenta;
  final int stock;
  final String imagenUrl;
  final String color;

  const _VarianteInventario({
    required this.varianteId,
    required this.productoId,
    required this.nombrePrenda,
    required this.talla,
    required this.sku,
    required this.precioVenta,
    required this.stock,
    required this.imagenUrl,
    required this.color,
  });
}
