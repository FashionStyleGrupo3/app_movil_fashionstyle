// @source-mirror: src/views/admin/VistaProduccion.vue, src/components/produccion/CalculadoraProduccion.vue, src/components/produccion/GestorOrdenesProduccion.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/network/change_bus.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/production/calculator_dataset.dart';
import 'package:fashion_style_mobile/data/models/production/production_formula_model.dart';
import 'package:fashion_style_mobile/data/services/production_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminProductionScreen extends ConsumerStatefulWidget {
  const AdminProductionScreen({super.key});

  @override
  ConsumerState<AdminProductionScreen> createState() => _AdminProductionScreenState();
}

class _AdminProductionScreenState extends ConsumerState<AdminProductionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<DataChangeEvent>? _busSub;

  bool _cargando = true;
  CalculatorDataset? _calculadoraData;
  List<Map<String, dynamic>> _materias = [];
  List<Map<String, dynamic>> _formulas = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _ordenes = [];
  List<Map<String, dynamic>> _unidadesMedida = [];

  // Fórmulas por prenda state
  int? _productoFormulaSeleccionadoId;

  // Órdenes filter & search state
  String _filtroEstadoOrden = '';
  final TextEditingController _busquedaOrdenCtrl = TextEditingController();

  // Simulador state
  ProductionFormulaModel? _formulaSeleccionada;
  int _cantidadProducir = 50;
  double _costoManoObra = 35000;
  double _precioVenta = 85000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _cargarTodo();

    _busSub = ChangeBus.instance.stream.listen((evento) {
      if (evento.recurso == 'produccion' || evento.recurso == 'inventarios') {
        _cargarTodo(silencioso: true);
      }
    });
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _busquedaOrdenCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    CalculatorDataset? calcData;
    List<Map<String, dynamic>> materias = [];
    List<Map<String, dynamic>> formulas = [];
    List<Map<String, dynamic>> proveedores = [];
    List<Map<String, dynamic>> ordenes = [];
    List<Map<String, dynamic>> unidades = [];

    await Future.wait([
      ProductionService.instance.cargarDatosCalculadora().then((v) => calcData = v).catchError((_) => calcData = CalculatorDataset(formulas: [], materiasPrimas: [])),
      ProductionService.instance.listarMateriasPrimas().then((v) => materias = v).catchError((_) => materias = <Map<String, dynamic>>[]),
      ProductionService.instance.listarFormulas().then((v) => formulas = v).catchError((_) => formulas = <Map<String, dynamic>>[]),
      ProductionService.instance.listarProveedores().then((v) => proveedores = v).catchError((_) => proveedores = <Map<String, dynamic>>[]),
      ProductionService.instance.listarOrdenesProduccion().then((v) => ordenes = v).catchError((_) => ordenes = <Map<String, dynamic>>[]),
      ProductionService.instance.listarUnidadesMedida().then((v) => unidades = v).catchError((_) => unidades = <Map<String, dynamic>>[]),
    ]);

    if (mounted) {
      setState(() {
        _calculadoraData = calcData;
        _materias = materias;
        _formulas = formulas;
        _proveedores = proveedores;
        _ordenes = ordenes;
        _unidadesMedida = unidades;
        if (calcData != null && calcData!.formulas.isNotEmpty) {
          _formulaSeleccionada ??= calcData!.formulas.first;
          _productoFormulaSeleccionadoId ??= calcData!.formulas.first.productoId;
        }
        _cargando = false;
      });
    }
  }

  double _extraerCostoOrden(Map<String, dynamic> o) {
    final costoTotal = JsonParser.toDouble(o['costo_total']);
    if (costoTotal > 0) return costoTotal;
    final costoEstimado = JsonParser.toDouble(o['costo_estimado'] ?? o['costo_total_estimado']);
    if (costoEstimado > 0) return costoEstimado;
    final cantidad = JsonParser.toInt(o['cantidad'], 1);
    final manoObra = JsonParser.toDouble(o['costo_mano_obra']);
    if (manoObra > 0) return manoObra * cantidad;
    return 0;
  }

  String _nombrePrendaOrden(Map<String, dynamic> o) {
    final formula = o['formula'];
    if (formula is Map<String, dynamic>) {
      final producto = formula['producto'];
      if (producto is Map<String, dynamic> && producto['nombre'] != null) {
        return producto['nombre'].toString();
      }
      if (formula['nombre'] != null) {
        return formula['nombre'].toString();
      }
    }
    return 'Prenda #${o['id_orden'] ?? o['id']}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/produccion',
      child: Column(
        children: [
          Container(
            color: FashionColors.surfaceCard,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FashionColors.borderSubtle, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: FashionColors.inkPrimary,
              unselectedLabelColor: FashionColors.inkSecondary,
              indicatorColor: FashionColors.inkPrimary,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.calculate_outlined, size: 16), text: 'Simulador Costos'),
                Tab(icon: Icon(Icons.layers_outlined, size: 16), text: 'Materias Primas'),
                Tab(icon: Icon(Icons.format_list_bulleted, size: 16), text: 'Fórmulas'),
                Tab(icon: Icon(Icons.store_mall_directory_outlined, size: 16), text: 'Proveedores'),
                Tab(icon: Icon(Icons.assignment_outlined, size: 16), text: 'Órdenes'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.inkPrimary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _construirSimulador(),
                      _construirMateriasPrimas(),
                      _construirFormulas(),
                      _construirProveedores(),
                      _construirOrdenes(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. SIMULADOR Y CALCULADORA DE COSTOS
  // ==========================================
  Widget _construirSimulador() {
    if (_calculadoraData == null || _calculadoraData!.formulas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calculate_outlined, size: 48, color: FashionColors.inkSecondary),
              const SizedBox(height: 12),
              Text(
                'No hay fórmulas configuradas para simular costos.',
                style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: FashionColors.inkPrimary, foregroundColor: Colors.white),
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Crear Primera Fórmula'),
              ),
            ],
          ),
        ),
      );
    }

    final f = _formulaSeleccionada ?? _calculadoraData!.formulas.first;

    // Costo insumos por prenda
    double costoInsumosUnidad = 0;
    bool factible = true;
    final List<String> faltantes = [];

    for (final c in f.consumos) {
      final insumo = _calculadoraData!.buscarMateriaPorId(c.materiaPrimaId);
      final costoUnitario = insumo?.costoUnitario ?? c.insumoCosto;
      final stockActual = insumo?.stockActual ?? c.insumoStock;
      final requeridoTotal = c.cantidad * _cantidadProducir;

      costoInsumosUnidad += (c.cantidad * costoUnitario);
      if (requeridoTotal > stockActual) {
        factible = false;
        faltantes.add('${insumo?.nombre ?? c.insumoNombre} (Req: $requeridoTotal, Stock: $stockActual)');
      }
    }

    final costoTotalUnidad = costoInsumosUnidad + _costoManoObra;
    final costoLoteTotal = costoTotalUnidad * _cantidadProducir;
    final ingresoTotal = _precioVenta * _cantidadProducir;
    final utilidadNeta = ingresoTotal - costoLoteTotal;
    final margenPorcentaje = ingresoTotal > 0 ? ((utilidadNeta / ingresoTotal) * 100) : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        DropdownButtonFormField<ProductionFormulaModel>(
          initialValue: f,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Fórmula de prenda', border: OutlineInputBorder()),
          items: _calculadoraData!.formulas.map((form) => DropdownMenuItem(value: form, child: Text(form.nombre, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _formulaSeleccionada = val;
                if (val.precioVenta > 0) _precioVenta = val.precioVenta;
                if (val.manoObraSugerida > 0) _costoManoObra = val.manoObraSugerida;
              });
            }
          },
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '$_cantidadProducir',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad a confeccionar', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _cantidadProducir = int.tryParse(v) ?? 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '$_costoManoObra',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mano de obra / ud', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _costoManoObra = double.tryParse(v) ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: '$_precioVenta',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Precio de venta al público (COP)', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _precioVenta = double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 16),

        // Factibilidad en bodega
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: factible ? FashionColors.verdeExito.withValues(alpha: 0.08) : FashionColors.aviso.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: factible ? FashionColors.verdeExito.withValues(alpha: 0.3) : FashionColors.aviso.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(factible ? Icons.check_circle : Icons.warning_amber_rounded, color: factible ? FashionColors.verdeExito : FashionColors.aviso, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      factible ? 'Factibilidad en Bodega: Insumos completos' : 'Faltan insumos para este volumen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: factible ? FashionColors.verdeExito : FashionColors.aviso),
                    ),
                  ),
                ],
              ),
              if (!factible) ...[
                const SizedBox(height: 4),
                ...faltantes.map((fal) => Text('• $fal', style: const TextStyle(fontSize: 11, color: FashionColors.textoOscuro))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Desglose de Costos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FashionColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FashionColors.borderSubtle),
          ),
          child: Column(
            children: [
              _filaSimulador('Costo insumos (unidad):', CurrencyFormatter.formatearCOP(costoInsumosUnidad)),
              _filaSimulador('Mano de obra (unidad):', CurrencyFormatter.formatearCOP(_costoManoObra)),
              _filaSimulador('Costo total unitario:', CurrencyFormatter.formatearCOP(costoTotalUnidad), negrita: true),
              const Divider(color: FashionColors.borderSubtle),
              _filaSimulador('Costo total del lote:', CurrencyFormatter.formatearCOP(costoLoteTotal)),
              _filaSimulador('Ingreso proyectado:', CurrencyFormatter.formatearCOP(ingresoTotal)),
              _filaSimulador('Utilidad bruta estimada:', CurrencyFormatter.formatearCOP(utilidadNeta), col: FashionColors.verdeExito, negrita: true),
              _filaSimulador('Margen sobre venta:', '${margenPorcentaje.toStringAsFixed(1)}%', negrita: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: FashionColors.inkPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () async {
            try {
              await ProductionService.instance.crearOrdenProduccion({
                'formula_id': f.idFormula > 0 ? f.idFormula : f.id,
                'cantidad': _cantidadProducir,
                'costo_mano_obra': _costoManoObra,
                'precio_venta': _precioVenta,
                'costo_total': costoLoteTotal,
                'estado': 'planificada',
              });
              ChangeBus.instance.notifyAll(['produccion', 'dashboard']);
              await _cargarTodo();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Orden de producción generada en estado Planificada')),
                );
                _tabController.animateTo(4);
              }
            } catch (e) {
              if (mounted) {
                _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No fue posible crear la orden de producción.'));
              }
            }
          },
          icon: const Icon(Icons.post_add),
          label: Text('Generar Orden de Producción', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _filaSimulador(String etq, String val, {bool negrita = false, Color? col}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etq, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary, fontWeight: negrita ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: negrita ? FontWeight.bold : FontWeight.w600, color: col ?? FashionColors.inkPrimary)),
        ],
      ),
    );
  }

  // ==========================================
  // 2. MATERIAS PRIMAS (CRUD)
  // ==========================================
  Widget _construirMateriasPrimas() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: FashionColors.canvasBackground,
            border: Border(bottom: BorderSide(color: FashionColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Text('${_materias.length} Insumos registrados', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkSecondary)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionColors.inkPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _abrirModalMateriaPrima(),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Nueva Materia Prima', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _materias.isEmpty
              ? RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 48),
                      Icon(Icons.layers_outlined, size: 48, color: FashionColors.inkSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Center(child: Text('No hay materias primas registradas', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 14))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                    itemCount: _materias.length,
                    itemBuilder: (context, index) {
                      final m = _materias[index];
                      final id = m['id_material'] ?? m['id'];
                      final stock = JsonParser.toInt(m['stock_actual'] ?? m['stock']);
                      final stockMin = JsonParser.toInt(m['stock_min']);
                      final bajoStock = stock <= stockMin;
                      final unidad = m['unidad'] ?? m['unidad_medida']?['abreviatura'] ?? 'un';

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: bajoStock ? FashionColors.aviso.withValues(alpha: 0.15) : const Color(0xFF2563EB).withValues(alpha: 0.15),
                            child: Icon(Icons.layers, color: bajoStock ? FashionColors.aviso : const Color(0xFF2563EB), size: 20),
                          ),
                          title: Text(
                            m['nombre']?.toString() ?? 'Insumo',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary),
                          ),
                          subtitle: Text(
                            'Cód: ${m['codigo'] ?? '-'} · Stock: $stock $unidad · Costo: ${CurrencyFormatter.formatearCOP(JsonParser.toDouble(m['costo_unitario']))}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: bajoStock ? FashionColors.aviso : FashionColors.inkSecondary),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (val) {
                              if (val == 'editar') {
                                _abrirModalMateriaPrima(m);
                              } else if (val == 'eliminar') {
                                _confirmarEliminarMateriaPrima(id, m['nombre']?.toString() ?? 'Insumo');
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'editar', child: Text('Editar Insumo')),
                              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: FashionColors.peligro))),
                            ],
                          ),
                          onTap: () => _abrirModalMateriaPrima(m),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _abrirModalMateriaPrima([Map<String, dynamic>? item]) {
    final esEdicion = item != null;
    final id = item?['id_material'] ?? item?['id'];
    final codigoCtrl = TextEditingController(text: item?['codigo']?.toString() ?? '');
    final nombreCtrl = TextEditingController(text: item?['nombre']?.toString() ?? '');
    final clasifCtrl = TextEditingController(text: item?['clasificacion']?.toString() ?? 'Tela');
    final stockCtrl = TextEditingController(text: (item?['stock'] ?? item?['stock_actual'] ?? '0').toString());
    final stockMinCtrl = TextEditingController(text: (item?['stock_min'] ?? '10').toString());
    final costoCtrl = TextEditingController(text: (item?['costo_unitario'] ?? '0').toString());

    int? unidadId = item?['unidad_medida_id'] ?? (item?['unidad_medida']?['id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: const BoxDecoration(
                color: FashionColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FashionColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      esEdicion ? 'Editar Materia Prima' : 'Nueva Materia Prima',
                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: codigoCtrl,
                      decoration: const InputDecoration(labelText: 'Código / Referencia *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre del Insumo *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: clasifCtrl,
                            decoration: const InputDecoration(labelText: 'Clasificación', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: unidadId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Unidad de Medida', border: OutlineInputBorder()),
                            items: _unidadesMedida.map((u) {
                              final uId = u['id'] ?? u['id_unidad'];
                              return DropdownMenuItem<int>(
                                value: uId is int ? uId : int.tryParse(uId.toString()),
                                child: Text('${u['nombre'] ?? u['abreviatura']} (${u['abreviatura'] ?? u['codigo'] ?? ''})', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (v) => setModalState(() => unidadId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stock Actual', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: stockMinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stock Mínimo', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: costoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Costo Unitario (COP) *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FashionColors.inkPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (codigoCtrl.text.trim().isEmpty || nombreCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Código y Nombre son obligatorios')));
                            return;
                          }
                          final payload = {
                            'codigo': codigoCtrl.text.trim(),
                            'nombre': nombreCtrl.text.trim(),
                            'clasificacion': clasifCtrl.text.trim(),
                            'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                            'stock_min': int.tryParse(stockMinCtrl.text.trim()) ?? 0,
                            'costo_unitario': double.tryParse(costoCtrl.text.trim()) ?? 0,
                            if (unidadId != null) 'unidad_medida_id': unidadId,
                            'activo': true,
                          };

                          try {
                            if (esEdicion) {
                              await ProductionService.instance.actualizarMateriaPrima(id, payload);
                            } else {
                              await ProductionService.instance.crearMateriaPrima(payload);
                            }
                            Navigator.pop(ctx);
                            ChangeBus.instance.notifyAll(['produccion', 'inventarios']);
                            _cargarTodo();
                          } catch (e) {
                            _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'Error al guardar materia prima.'));
                          }
                        },
                        child: Text(esEdicion ? 'Actualizar Materia Prima' : 'Guardar Materia Prima'),
                      ),
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

  Future<void> _confirmarEliminarMateriaPrima(int id, String nombre) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Materia Prima'),
        content: Text('¿Deseas eliminar "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (conf == true) {
      try {
        await ProductionService.instance.eliminarMateriaPrima(id);
        ChangeBus.instance.notifyAll(['produccion', 'inventarios']);
        _cargarTodo();
      } catch (e) {
        _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo eliminar la materia prima.'));
      }
    }
  }

  // ==========================================
  // 3. FÓRMULAS DE PRODUCCIÓN (PARIDAD WEB SCREENSHOT 3)
  // ==========================================
  Widget _construirFormulas() {
    // Buscar la fórmula del producto seleccionado
    Map<String, dynamic>? grupoSeleccionado;
    if (_productoFormulaSeleccionadoId != null) {
      for (final g in _formulas) {
        if (JsonParser.toInt(g['producto_id']) == _productoFormulaSeleccionadoId) {
          grupoSeleccionado = g;
          break;
        }
      }
    }

    final List consumos = (grupoSeleccionado?['consumos'] as List?) ?? [];

    // Calcular costo total de materiales por prenda
    double costoTotalMateriales = 0;
    final List<Map<String, dynamic>> insumosCalculados = [];

    for (final c in consumos) {
      final materiaId = JsonParser.toInt(c['materia_prima_id']);
      Map<String, dynamic>? materia;
      for (final m in _materias) {
        if (JsonParser.toInt(m['id_material'] ?? m['id']) == materiaId) {
          materia = m;
          break;
        }
      }

      final cantidad = JsonParser.toDouble(c['cantidad']);
      final desperdicio = JsonParser.toDouble(c['desperdicio_porcentaje']);
      final consumoReal = cantidad * (1 + (desperdicio / 100));
      final costoUnitario = JsonParser.toDouble(c['costo_unitario_estimado']) > 0
          ? JsonParser.toDouble(c['costo_unitario_estimado'])
          : JsonParser.toDouble(materia?['costo_unitario']);
      final costo = consumoReal * costoUnitario;
      costoTotalMateriales += costo;

      insumosCalculados.add({
        'id_formula': c['id_formula'] ?? c['id'],
        'materia_prima_id': materiaId,
        'nombre_materia': c['materia_prima']?['nombre'] ?? materia?['nombre'] ?? 'Insumo #$materiaId',
        'unidad': c['unidad'] ?? materia?['unidad'] ?? 'un',
        'cantidad': cantidad,
        'desperdicio': desperdicio,
        'consumo_real': consumoReal,
        'proveedor_nombre': c['proveedor']?['nombre'] ?? materia?['proveedor']?['nombre'] ?? '—',
        'proveedor_id': c['proveedor_id'],
        'costo_unitario': costoUnitario,
        'costo': costo,
        'raw': c,
      });
    }

    return Column(
      children: [
        // Selector de Prenda y Botón Agregar Insumo (Matching Web)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: FashionColors.surfaceCard,
            border: Border(bottom: BorderSide(color: FashionColors.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prenda', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: FashionColors.inkSecondary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _productoFormulaSeleccionadoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona una prenda...',
                      ),
                      items: (_calculadoraData?.formulas ?? []).map((f) {
                        return DropdownMenuItem<int>(
                          value: f.productoId,
                          child: Text(f.nombre, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _productoFormulaSeleccionadoId = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FashionColors.brandAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _productoFormulaSeleccionadoId == null ? null : () => _abrirModalInsumoFormula(),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('Agregar insumo', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Contenido: Lista de insumos o placeholder
        Expanded(
          child: _productoFormulaSeleccionadoId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_outlined, size: 48, color: FashionColors.inkSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'Elige una prenda para ver o armar su receta.',
                          style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : insumosCalculados.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.format_list_bulleted_outlined, size: 48, color: FashionColors.inkSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'Esta prenda no tiene insumos en su fórmula.',
                              style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: FashionColors.inkPrimary, foregroundColor: Colors.white),
                              onPressed: () => _abrirModalInsumoFormula(),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Agregar Primer Insumo'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarTodo,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                        children: [
                          ...insumosCalculados.map((ins) {
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: FashionColors.borderSubtle),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ins['nombre_materia'].toString(),
                                            style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.formatearCOP(ins['costo']),
                                          style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.brandAccent),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          'Cant: ${(ins['cantidad'] as double).toStringAsFixed(2)} ${ins['unidad']}',
                                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: FashionColors.inkSecondary),
                                        ),
                                        const Text(' · ', style: TextStyle(color: FashionColors.inkSecondary)),
                                        Text(
                                          'Desperdicio: ${(ins['desperdicio'] as double).toStringAsFixed(1)}%',
                                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: FashionColors.inkSecondary),
                                        ),
                                        const Text(' · ', style: TextStyle(color: FashionColors.inkSecondary)),
                                        Text(
                                          'Real: ${(ins['consumo_real'] as double).toStringAsFixed(4)}',
                                          style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.inkPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Proveedor: ${ins['proveedor_nombre']}',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: FashionColors.inkSecondary),
                                          tooltip: 'Editar insumo',
                                          onPressed: () => _abrirModalInsumoFormula(insumoEditar: ins),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: FashionColors.peligro),
                                          tooltip: 'Quitar insumo',
                                          onPressed: () => _quitarInsumoFormula(ins),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 8),

                          // Footer con costo total de materiales por prenda
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: FashionColors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Costo de materiales por prenda',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                                ),
                                Text(
                                  CurrencyFormatter.formatearCOP(costoTotalMateriales),
                                  style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w700, color: FashionColors.brandAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  // MODAL AGREGAR / EDITAR INSUMO DE LA FÓRMULA (PARIDAD WEB SCREENSHOT 3)
  void _abrirModalInsumoFormula({Map<String, dynamic>? insumoEditar}) {
    if (_productoFormulaSeleccionadoId == null) return;

    final esEdicion = insumoEditar != null;
    int? materiaPrimaId = esEdicion ? JsonParser.toInt(insumoEditar['materia_prima_id']) : null;
    int? proveedorId = esEdicion ? (insumoEditar['proveedor_id'] != null ? JsonParser.toInt(insumoEditar['proveedor_id']) : null) : null;
    final cantidadCtrl = TextEditingController(text: esEdicion ? '${insumoEditar['cantidad']}' : '1');
    double desperdicioPorcentaje = esEdicion ? JsonParser.toDouble(insumoEditar['desperdicio']) : 5.0;

    // Buscar grupo de consumos actuales de esta prenda para evitar insumos duplicados en creación
    final grupoActual = _formulas.firstWhere(
      (g) => JsonParser.toInt(g['producto_id']) == _productoFormulaSeleccionadoId,
      orElse: () => <String, dynamic>{},
    );
    final List consumosActuales = (grupoActual['consumos'] as List?) ?? [];
    final setIdsEnReceta = consumosActuales.map((c) => JsonParser.toInt(c['materia_prima_id'])).toSet();

    final materiasDisponibles = _materias.where((m) {
      final id = JsonParser.toInt(m['id_material'] ?? m['id']);
      if (esEdicion && id == materiaPrimaId) return true;
      return !setIdsEnReceta.contains(id);
    }).toList();

    if (!esEdicion && materiasDisponibles.isNotEmpty) {
      materiaPrimaId = JsonParser.toInt(materiasDisponibles.first['id_material'] ?? materiasDisponibles.first['id']);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Map<String, dynamic>? matElegida;
            for (final m in _materias) {
              if (JsonParser.toInt(m['id_material'] ?? m['id']) == materiaPrimaId) {
                matElegida = m;
                break;
              }
            }

            final cant = double.tryParse(cantidadCtrl.text.trim()) ?? 0;
            final consumoConDesperdicio = cant * (1 + (desperdicioPorcentaje / 100));
            final costoUnitario = JsonParser.toDouble(matElegida?['costo_unitario']);
            final costoEstimado = consumoConDesperdicio * costoUnitario;
            final unidad = matElegida?['unidad']?.toString() ?? 'un';

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: const BoxDecoration(
                color: FashionColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FashionColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          esEdicion ? 'Editar insumo de la fórmula' : 'Agregar insumo a la fórmula',
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: FashionColors.inkSecondary),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selector de Insumo
                    Text('Insumo *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: materiaPrimaId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                      items: materiasDisponibles.map((m) {
                        final id = JsonParser.toInt(m['id_material'] ?? m['id']);
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('${m['nombre']} (${m['unidad'] ?? "un"})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          materiaPrimaId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Fila Cantidad y Desperdicio
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cantidad por prenda ($unidad) *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: cantidadCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Desperdicio (%)', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: FashionColors.canvasBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: FashionColors.borderSubtle),
                                ),
                                child: Text(
                                  esEdicion ? '${desperdicioPorcentaje.toStringAsFixed(1)}% · automático' : 'Se asigna automáticamente',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selector de Proveedor (opcional)
                    Text('Proveedor (opcional)', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      value: proveedorId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Sin proveedor asignado')),
                        ..._proveedores.map((p) {
                          final id = JsonParser.toInt(p['id']);
                          return DropdownMenuItem<int?>(value: id, child: Text(p['nombre']?.toString() ?? 'Proveedor #$id'));
                        }),
                      ],
                      onChanged: (val) => setModalState(() => proveedorId = val),
                    ),
                    const SizedBox(height: 14),

                    // Live Preview Box (Matching Screenshot 3)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FashionColors.canvasBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FashionColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calculate_outlined, size: 16, color: FashionColors.slateAccent),
                              const SizedBox(width: 6),
                              Text('Cálculo Dinámico:', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: FashionColors.slateAccent)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkPrimary),
                              children: [
                                const TextSpan(text: 'Consumo real por prenda: '),
                                TextSpan(
                                  text: '${consumoConDesperdicio.toStringAsFixed(4)} $unidad',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const TextSpan(text: ' · Costo estimado: '),
                                TextSpan(
                                  text: CurrencyFormatter.formatearCOP(costoEstimado),
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: FashionColors.brandAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botones Cancelar / Guardar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.brandAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (materiaPrimaId == null || cant <= 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresa un insumo y una cantidad válida')));
                                return;
                              }

                              final payload = {
                                'producto_id': _productoFormulaSeleccionadoId,
                                'materia_prima_id': materiaPrimaId,
                                'cantidad': cant,
                                'unidad_medida_id': matElegida?['unidad_medida_id'] ?? matElegida?['unidad_medida']?['id'],
                                'costo_unitario_estimado': costoUnitario,
                                'proveedor_id': proveedorId,
                              };

                              try {
                                if (esEdicion) {
                                  final idFormula = JsonParser.toInt(insumoEditar['id_formula']);
                                  await ProductionService.instance.actualizarFormula(idFormula, payload);
                                } else {
                                  await ProductionService.instance.crearFormula(payload);
                                }
                                Navigator.pop(sheetCtx);
                                ChangeBus.instance.notifyAll(['produccion']);
                                _cargarTodo();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(esEdicion ? 'Insumo actualizado con éxito.' : 'Insumo agregado a la receta.')),
                                );
                              } catch (e) {
                                _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo guardar el insumo.'));
                              }
                            },
                            child: Text(
                              esEdicion ? 'Guardar cambios' : 'Agregar',
                              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _quitarInsumoFormula(Map<String, dynamic> ins) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar Insumo'),
        content: Text('¿Deseas quitar "${ins['nombre_materia']}" de la receta de esta prenda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, quitar'),
          ),
        ],
      ),
    );

    if (conf == true) {
      try {
        final idFormula = JsonParser.toInt(ins['id_formula']);
        await ProductionService.instance.eliminarFormula(idFormula);
        ChangeBus.instance.notifyAll(['produccion']);
        _cargarTodo();
      } catch (e) {
        _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo quitar el insumo.'));
      }
    }
  }

  // ==========================================
  // 4. PROVEEDORES (CRUD)
  // ==========================================
  Widget _construirProveedores() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: FashionColors.canvasBackground,
            border: Border(bottom: BorderSide(color: FashionColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Text('${_proveedores.length} Proveedores registrados', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkSecondary)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionColors.inkPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _abrirModalProveedor(),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Nuevo Proveedor', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _proveedores.isEmpty
              ? RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 48),
                      Icon(Icons.store_mall_directory_outlined, size: 48, color: FashionColors.inkSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Center(child: Text('No hay proveedores registrados', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 14))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                    itemCount: _proveedores.length,
                    itemBuilder: (context, index) {
                      final p = _proveedores[index];
                      final id = p['id'] ?? p['id_proveedor'];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
                            child: const Icon(Icons.store, color: Color(0xFF0D9488), size: 20),
                          ),
                          title: Text(p['nombre']?.toString() ?? 'Proveedor', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
                          subtitle: Text('Contacto: ${p['contacto'] ?? '-'} · Tel: ${p['telefono'] ?? '-'}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary)),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (val) {
                              if (val == 'editar') {
                                _abrirModalProveedor(p);
                              } else if (val == 'eliminar') {
                                _confirmarEliminarProveedor(id, p['nombre']?.toString() ?? 'Proveedor');
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'editar', child: Text('Editar Proveedor')),
                              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: FashionColors.peligro))),
                            ],
                          ),
                          onTap: () => _abrirModalProveedor(p),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _abrirModalProveedor([Map<String, dynamic>? item]) {
    final esEdicion = item != null;
    final id = item?['id'] ?? item?['id_proveedor'];
    final nombreCtrl = TextEditingController(text: item?['nombre']?.toString() ?? '');
    final contactoCtrl = TextEditingController(text: item?['contacto']?.toString() ?? '');
    final telCtrl = TextEditingController(text: item?['telefono']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: item?['email']?.toString() ?? '');
    final dirCtrl = TextEditingController(text: item?['direccion']?.toString() ?? '');
    final notasCtrl = TextEditingController(text: item?['notas']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 16,
          ),
          decoration: const BoxDecoration(
            color: FashionColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FashionColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Razón Social / Nombre *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactoCtrl,
                  decoration: const InputDecoration(labelText: 'Persona de Contacto', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: telCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dirCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección física', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notasCtrl,
                  decoration: const InputDecoration(labelText: 'Notas adicionales', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FashionColors.inkPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (nombreCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('El nombre es obligatorio')));
                        return;
                      }
                      final payload = {
                        'nombre': nombreCtrl.text.trim(),
                        'contacto': contactoCtrl.text.trim(),
                        'telefono': telCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'direccion': dirCtrl.text.trim(),
                        'notas': notasCtrl.text.trim(),
                        'activo': true,
                      };

                      try {
                        if (esEdicion) {
                          await ProductionService.instance.actualizarProveedor(id, payload);
                        } else {
                          await ProductionService.instance.crearProveedor(payload);
                        }
                        Navigator.pop(ctx);
                        _cargarTodo();
                      } catch (e) {
                        _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'Error al guardar proveedor.'));
                      }
                    },
                    child: Text(esEdicion ? 'Actualizar Proveedor' : 'Guardar Proveedor'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmarEliminarProveedor(int id, String nombre) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Proveedor'),
        content: Text('¿Deseas eliminar al proveedor "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (conf == true) {
      try {
        await ProductionService.instance.eliminarProveedor(id);
        _cargarTodo();
      } catch (e) {
        _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo eliminar el proveedor.'));
      }
    }
  }

  // ==========================================
  // 5. ÓRDENES DE PRODUCCIÓN (PARIDAD WEB SCREENSHOTS 1 & 2)
  // ==========================================
  Widget _construirOrdenes() {
    final busq = _busquedaOrdenCtrl.text.trim().toLowerCase();
    final ordenesFiltradas = _ordenes.where((o) {
      final estado = (o['estado']?.toString() ?? 'planificada').toLowerCase();
      if (_filtroEstadoOrden.isNotEmpty && estado != _filtroEstadoOrden) return false;
      if (busq.isNotEmpty) {
        final numStr = (o['numero']?.toString() ?? '').toLowerCase();
        final prendaStr = _nombrePrendaOrden(o).toLowerCase();
        final notasStr = (o['notas']?.toString() ?? '').toLowerCase();
        return numStr.contains(busq) || prendaStr.contains(busq) || notasStr.contains(busq);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Barra Superior: Búsqueda y Botón Nueva Orden
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: const BoxDecoration(
            color: FashionColors.surfaceCard,
            border: Border(bottom: BorderSide(color: FashionColors.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _busquedaOrdenCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar por número, prenda o notas...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.search, size: 18, color: FashionColors.inkSecondary),
                        suffixIcon: _busquedaOrdenCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _busquedaOrdenCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: FashionColors.canvasBackground,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.inkPrimary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FashionColors.inkPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _abrirModalNuevaOrden(),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('Nueva Orden', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Chips: Todos, Planificada, En proceso, Pausada, Completada, Cancelada
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChipEstadoOrden('Todos', ''),
                    const SizedBox(width: 6),
                    _buildChipEstadoOrden('Planificada', 'planificada'),
                    const SizedBox(width: 6),
                    _buildChipEstadoOrden('En proceso', 'en_proceso'),
                    const SizedBox(width: 6),
                    _buildChipEstadoOrden('Pausada', 'pausada'),
                    const SizedBox(width: 6),
                    _buildChipEstadoOrden('Completada', 'completada'),
                    const SizedBox(width: 6),
                    _buildChipEstadoOrden('Cancelada', 'cancelada'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de Órdenes
        Expanded(
          child: ordenesFiltradas.isEmpty
              ? RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 48),
                      Icon(Icons.assignment_outlined, size: 48, color: FashionColors.inkSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _ordenes.isEmpty
                              ? 'No hay órdenes de producción registradas'
                              : 'No hay órdenes que coincidan con los filtros',
                          style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                    itemCount: ordenesFiltradas.length,
                    itemBuilder: (context, index) {
                      final o = ordenesFiltradas[index];
                      final id = JsonParser.toInt(o['id_orden'] ?? o['id']);
                      final numero = o['numero']?.toString() ?? 'ORD-#$id';
                      final estado = (o['estado']?.toString() ?? 'planificada').toLowerCase();
                      final esCompletada = estado == 'completada';
                      final esCancelada = estado == 'cancelada' || estado == 'cancelado';
                      final nombrePrenda = _nombrePrendaOrden(o);
                      final costoReal = _extraerCostoOrden(o);
                      final cantidad = JsonParser.toInt(o['cantidad']);

                      Color badgeBg = const Color(0xFFF3F4F6);
                      Color badgeText = const Color(0xFF6B7280);
                      if (estado == 'planificada') {
                        badgeBg = const Color(0xFFFEF3C7);
                        badgeText = const Color(0xFFB45309);
                      } else if (estado == 'en_proceso') {
                        badgeBg = const Color(0xFFEFF6FF);
                        badgeText = const Color(0xFF1D4ED8);
                      } else if (estado == 'pausada') {
                        badgeBg = const Color(0xFFFFF7ED);
                        badgeText = const Color(0xFFC2410C);
                      } else if (esCompletada) {
                        badgeBg = const Color(0xFFECFDF5);
                        badgeText = const Color(0xFF047857);
                      }

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: FashionColors.borderSubtle),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    numero,
                                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      estado.toUpperCase(),
                                      style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700, color: badgeText),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    o['created_at'] != null ? o['created_at'].toString().split('T').first : '',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 10, color: FashionColors.inkSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                nombrePrenda,
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Lote: $cantidad prendas', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: FashionColors.inkSecondary)),
                                  const Text(' · ', style: TextStyle(color: FashionColors.inkSecondary)),
                                  Text(
                                    'Costo: ${CurrencyFormatter.formatearCOP(costoReal)}',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.inkPrimary),
                                  ),
                                ],
                              ),
                              if (o['notas'] != null && o['notas'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Notas: ${o['notas']}',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: FashionColors.inkSecondary),
                                ),
                              ],
                              const SizedBox(height: 10),

                              // Botones de acción del ciclo de vida
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Acciones para Planificada: Iniciar, Editar, Cancelar, Eliminar
                                  if (estado == 'planificada') ...[
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2563EB), size: 20),
                                      tooltip: 'Iniciar producción',
                                      onPressed: () => _cambiarEstadoOrden(id, 'en_proceso'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: FashionColors.inkSecondary, size: 18),
                                      tooltip: 'Editar orden',
                                      onPressed: () => _abrirModalEdicionOrden(o),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: FashionColors.peligro, size: 18),
                                      tooltip: 'Cancelar orden',
                                      onPressed: () => _abrirModalCancelacion2Pasos(o),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: FashionColors.peligro, size: 18),
                                      tooltip: 'Eliminar orden',
                                      onPressed: () => _eliminarOrden(id),
                                    ),
                                  ],

                                  // Acciones para En Proceso: Pausar, Completar, Editar, Cancelar, Eliminar
                                  if (estado == 'en_proceso') ...[
                                    IconButton(
                                      icon: const Icon(Icons.pause_rounded, color: Color(0xFFD97706), size: 20),
                                      tooltip: 'Pausar producción',
                                      onPressed: () => _cambiarEstadoOrden(id, 'pausada'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline_rounded, color: FashionColors.verdeExito, size: 20),
                                      tooltip: 'Completar orden',
                                      onPressed: () => _abrirModalCompletar(o),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: FashionColors.inkSecondary, size: 18),
                                      tooltip: 'Editar orden',
                                      onPressed: () => _abrirModalEdicionOrden(o),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: FashionColors.peligro, size: 18),
                                      tooltip: 'Cancelar orden',
                                      onPressed: () => _abrirModalCancelacion2Pasos(o),
                                    ),
                                  ],

                                  // Acciones para Pausada: Reanudar, Completar, Editar, Cancelar
                                  if (estado == 'pausada') ...[
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2563EB), size: 20),
                                      tooltip: 'Reanudar producción',
                                      onPressed: () => _cambiarEstadoOrden(id, 'en_proceso'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline_rounded, color: FashionColors.verdeExito, size: 20),
                                      tooltip: 'Completar orden',
                                      onPressed: () => _abrirModalCompletar(o),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: FashionColors.inkSecondary, size: 18),
                                      tooltip: 'Editar orden',
                                      onPressed: () => _abrirModalEdicionOrden(o),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: FashionColors.peligro, size: 18),
                                      tooltip: 'Cancelar orden',
                                      onPressed: () => _abrirModalCancelacion2Pasos(o),
                                    ),
                                  ],

                                  // Acciones para Cancelada: Eliminar
                                  if (esCancelada) ...[
                                    TextButton.icon(
                                      style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
                                      onPressed: () => _eliminarOrden(id),
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text('Eliminar', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChipEstadoOrden(String etiqueta, String valor) {
    final sel = _filtroEstadoOrden == valor;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _filtroEstadoOrden = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? FashionColors.brandAccent : FashionColors.canvasBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? FashionColors.brandAccent : FashionColors.borderSubtle),
        ),
        child: Text(
          etiqueta,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : FashionColors.inkSecondary,
          ),
        ),
      ),
    );
  }

  // MODAL COMPLETAR ORDEN (RF-059: DISTRIBUCIÓN POR TALLAS & DESCUENTO DE INSUMOS)
  Future<void> _abrirModalCompletar(Map<String, dynamic> orden) async {
    final id = orden['id_orden'] ?? orden['id'];
    final formula = orden['formula'];
    final productoId = formula is Map<String, dynamic>
        ? (formula['producto_id'] ?? formula['producto']?['id_producto'])
        : null;

    final cantidadLote = JsonParser.toInt(orden['cantidad'], 1);
    final numero = orden['numero']?.toString() ?? 'ORD-#$id';
    final nombrePrenda = _nombrePrendaOrden(orden);

    // Cargar variantes del producto para distribuir
    List<Map<String, dynamic>> variantes = [];
    if (productoId != null) {
      try {
        variantes = await ProductionService.instance.obtenerVariantesProducto(JsonParser.toInt(productoId));
      } catch (_) {}
    }

    if (!mounted) return;

    if (variantes.isEmpty || variantes.length == 1) {
      // Caso 1: Variante única o sin variantes
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Completar $numero'),
          content: Text(
            '¿Confirmas la finalización de la orden de producción por $cantidadLote unidades de "$nombrePrenda"?\n\nAl confirmar, se descontarán automáticamente los insumos consumidos de la bodega y las prendas ingresarán al inventario.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FashionColors.verdeExito, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Completar y Descontar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _ejecutarCompletarOrden(id, numero, variantes.isNotEmpty ? {'variante_id': variantes.first['id_variante']} : {});
      }
      return;
    }

    // Caso 2: Múltiples variantes (tallas S, M, L, etc.)
    final Map<int, TextEditingController> controladoresTalla = {};
    for (final v in variantes) {
      final vId = JsonParser.toInt(v['id_variante']);
      controladoresTalla[vId] = TextEditingController(text: '0');
    }

    // Auto-distribución inicial uniforme
    final count = variantes.length;
    final base = cantidadLote ~/ count;
    final resto = cantidadLote % count;
    for (int i = 0; i < count; i++) {
      final vId = JsonParser.toInt(variantes[i]['id_variante']);
      controladoresTalla[vId]?.text = '${base + (i < resto ? 1 : 0)}';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            int totalRepartido = 0;
            for (final v in variantes) {
              final vId = JsonParser.toInt(v['id_variante']);
              totalRepartido += int.tryParse(controladoresTalla[vId]?.text.trim() ?? '0') ?? 0;
            }
            final esExacto = totalRepartido == cantidadLote;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: const BoxDecoration(
                color: FashionColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FashionColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text('Completar $numero', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                    Text('Prenda: $nombrePrenda · Lote a confeccionar: $cantidadLote unidades', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: esExacto ? FashionColors.verdeExito.withValues(alpha: 0.1) : FashionColors.aviso.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(esExacto ? Icons.check_circle : Icons.info_outline, size: 18, color: esExacto ? FashionColors.verdeExito : FashionColors.aviso),
                          const SizedBox(width: 8),
                          Text(
                            'Unidades asignadas: $totalRepartido / $cantidadLote',
                            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: esExacto ? FashionColors.verdeExito : FashionColors.aviso),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Distribución por tallas para el kárdex:', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...variantes.map((v) {
                      final vId = JsonParser.toInt(v['id_variante']);
                      final talla = v['talla']?.toString() ?? 'Talla';
                      final stockActual = v['stock'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text('Talla $talla (Stock: $stockActual)', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: controladoresTalla[vId],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: esExacto ? FashionColors.verdeExito : FashionColors.inkSecondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: esExacto
                            ? () async {
                                final distribucion = variantes.map((v) {
                                  final vId = JsonParser.toInt(v['id_variante']);
                                  final cant = int.tryParse(controladoresTalla[vId]?.text.trim() ?? '0') ?? 0;
                                  return {'variante_id': vId, 'cantidad': cant};
                                }).where((d) => (d['cantidad'] as int) > 0).toList();

                                Navigator.pop(ctx);
                                await _ejecutarCompletarOrden(id, numero, {'distribucion': distribucion});
                              }
                            : null,
                        child: const Text('Confirmar Cierre y Descontar Insumos'),
                      ),
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

  Future<void> _ejecutarCompletarOrden(int id, String numero, Map<String, dynamic> payload) async {
    try {
      await ProductionService.instance.completarOrdenProduccion(id, payload);
      ChangeBus.instance.notifyAll(['produccion', 'inventarios', 'productos', 'dashboard']);
      await _cargarTodo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FashionColors.verdeExito,
            content: Text('$numero completada: insumos descontados y prendas ingresadas al kárdex.'),
          ),
        );
      }
    } catch (e) {
      final msg = ApiClient.obtenerMensajeError(e, 'No se pudo completar la orden de producción.');
      _mostrarErrorDialog(msg);
    }
  }

  // ==========================================
  // MODAL DE CANCELACIÓN EN 2 PASOS (PARIDAD WEB SCREENSHOTS 1 & 2)
  // ==========================================
  Future<void> _abrirModalCancelacion2Pasos(Map<String, dynamic> orden) async {
    final id = JsonParser.toInt(orden['id_orden'] ?? orden['id']);
    final numero = orden['numero']?.toString() ?? 'ORD-#$id';
    final cantidadOrden = JsonParser.toInt(orden['cantidad'], 1);

    // Obtener los insumos de la fórmula de esta orden
    List consumosOrden = [];
    final formula = orden['formula'];
    if (formula is Map<String, dynamic>) {
      final cList = formula['consumos'] ?? formula['materia_prima'];
      if (cList is List) consumosOrden = cList;
    }

    // Si la orden no traía consumos anidados, buscamos en _formulas por producto_id
    if (consumosOrden.isEmpty) {
      final productoId = formula is Map<String, dynamic>
          ? JsonParser.toInt(formula['producto_id'] ?? formula['producto']?['id_producto'])
          : null;
      if (productoId != null) {
        for (final g in _formulas) {
          if (JsonParser.toInt(g['producto_id']) == productoId) {
            consumosOrden = (g['consumos'] as List?) ?? [];
            break;
          }
        }
      }
    }

    final Map<int, TextEditingController> controladoresMateriales = {};
    for (final c in consumosOrden) {
      final mId = JsonParser.toInt(c['materia_prima_id']);
      if (mId > 0) {
        controladoresMateriales[mId] = TextEditingController(text: '0');
      }
    }

    int pasoCancelacion = 1;
    bool enviandoCancelacion = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(22),
                child: pasoCancelacion == 1
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded, size: 34, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¿Se usaron materiales?',
                            style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Para cancelar la orden $numero, dinos si se llegó a cortar tela o usar insumos del inventario.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkSecondary, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Opción 1: No usé nada (Devolver todo)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: FashionColors.borderSubtle),
                              ),
                              onPressed: enviandoCancelacion
                                  ? null
                                  : () async {
                                      setDialogState(() => enviandoCancelacion = true);
                                      try {
                                        await ProductionService.instance.cancelarOrdenProduccion(id, materialesUsados: []);
                                        Navigator.pop(dialogCtx);
                                        ChangeBus.instance.notifyAll(['produccion', 'inventarios']);
                                        await _cargarTodo();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: FashionColors.inkPrimary,
                                              content: Text('$numero cancelada y stock ajustado.'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() => enviandoCancelacion = false);
                                        _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo cancelar la orden.'));
                                      }
                                    },
                              child: Text(
                                'No, no usé nada (Devolver todo)',
                                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Opción 2: Sí usé materiales (Ajustar stock)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                setDialogState(() => pasoCancelacion = 2);
                              },
                              child: Text(
                                'Sí, usé materiales (Ajustar stock)',
                                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.spaceGrotesk(fontSize: 12, color: FashionColors.inkSecondary),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFDC2626)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ajuste de materiales',
                                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                                    ),
                                    Text(
                                      'Ingresa las cantidades realmente usadas.',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: consumosOrden.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No se encontraron materiales en la fórmula de esta orden.',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: consumosOrden.length,
                                    itemBuilder: (ctx, idx) {
                                      final c = consumosOrden[idx];
                                      final mId = JsonParser.toInt(c['materia_prima_id']);
                                      Map<String, dynamic>? mat;
                                      for (final m in _materias) {
                                        if (JsonParser.toInt(m['id_material'] ?? m['id']) == mId) {
                                          mat = m;
                                          break;
                                        }
                                      }

                                      final nomMat = c['materia_prima']?['nombre'] ?? c['nombre'] ?? mat?['nombre'] ?? 'Insumo #$mId';
                                      final unidad = c['unidad'] ?? mat?['unidad'] ?? 'un';
                                      final cantPorPrenda = JsonParser.toDouble(c['cantidad']);
                                      final requeridoTotal = cantPorPrenda * cantidadOrden;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: FashionColors.canvasBackground,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: FashionColors.borderSubtle),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    nomMat,
                                                    style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Requerido: ${requeridoTotal.toStringAsFixed(2)} $unidad',
                                                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: FashionColors.inkSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: 80,
                                              child: TextFormField(
                                                controller: controladoresMateriales[mId],
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                textAlign: TextAlign.center,
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => setDialogState(() => pasoCancelacion = 1),
                                child: Text('Atrás', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: enviandoCancelacion
                                    ? null
                                    : () async {
                                        setDialogState(() => enviandoCancelacion = true);
                                        try {
                                          final payloadMateriales = controladoresMateriales.entries.map((e) {
                                            return {
                                              'materia_prima_id': e.key,
                                              'cantidad_usada': double.tryParse(e.value.text.trim()) ?? 0,
                                            };
                                          }).toList();

                                          await ProductionService.instance.cancelarOrdenProduccion(
                                            id,
                                            materialesUsados: payloadMateriales,
                                          );
                                          Navigator.pop(dialogCtx);
                                          ChangeBus.instance.notifyAll(['produccion', 'inventarios']);
                                          await _cargarTodo();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: FashionColors.inkPrimary,
                                                content: Text('$numero cancelada y stock ajustado.'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setDialogState(() => enviandoCancelacion = false);
                                          _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo cancelar la orden.'));
                                        }
                                      },
                                child: Text(
                                  enviandoCancelacion ? 'Cancelando...' : 'Confirmar Cancelación',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
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

  // ==========================================
  // MODAL DE EDICIÓN DE ORDEN (PARIDAD WEB)
  // ==========================================
  void _abrirModalEdicionOrden(Map<String, dynamic> orden) {
    final id = JsonParser.toInt(orden['id_orden'] ?? orden['id']);
    final numero = orden['numero']?.toString() ?? 'ORD-#$id';
    final nombrePrenda = _nombrePrendaOrden(orden);
    final cantidadAnterior = JsonParser.toInt(orden['cantidad'], 1);
    final costoTotalAnterior = _extraerCostoOrden(orden);
    final costoPorUnidad = costoTotalAnterior / cantidadAnterior;

    final cantidadCtrl = TextEditingController(text: '$cantidadAnterior');
    final notasCtrl = TextEditingController(text: orden['notas']?.toString() ?? '');
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final nuevaCant = int.tryParse(cantidadCtrl.text.trim()) ?? cantidadAnterior;
            final nuevoCosto = costoPorUnidad * nuevaCant;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: const BoxDecoration(
                color: FashionColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FashionColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),

                    Text('Editar $numero', style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                    Text(nombrePrenda, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary)),
                    const SizedBox(height: 16),

                    Text('Unidades a producir', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El costo total se reajusta automáticamente según las unidades.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FashionColors.inkSecondary),
                    ),
                    const SizedBox(height: 14),

                    Text('Notas', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: notasCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: FashionColors.canvasBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: FashionColors.borderSubtle)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nuevo Costo Estimado:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(CurrencyFormatter.formatearCOP(nuevoCosto), style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.brandAccent)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FashionColors.brandAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: guardando
                                ? null
                                : () async {
                                    if (nuevaCant < 1 || nuevaCant > 100000) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('La cantidad debe estar entre 1 y 100.000.')));
                                      return;
                                    }

                                    setModalState(() => guardando = true);
                                    try {
                                      final payload = <String, dynamic>{
                                        'notas': notasCtrl.text.trim().isNotEmpty ? notasCtrl.text.trim() : null,
                                      };
                                      if (nuevaCant != cantidadAnterior) {
                                        payload['cantidad'] = nuevaCant;
                                        payload['costo_total'] = double.parse(nuevoCosto.toStringAsFixed(2));
                                      }

                                      await ProductionService.instance.actualizarOrdenProduccion(id, payload);
                                      Navigator.pop(sheetCtx);
                                      ChangeBus.instance.notifyAll(['produccion']);
                                      await _cargarTodo();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$numero actualizada.')));
                                      }
                                    } catch (e) {
                                      setModalState(() => guardando = false);
                                      _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo actualizar la orden.'));
                                    }
                                  },
                            child: Text(guardando ? 'Guardando...' : 'Guardar cambios', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
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

  Future<void> _cambiarEstadoOrden(int id, String nuevoEstado) async {
    try {
      await ProductionService.instance.actualizarOrdenProduccion(id, {'estado': nuevoEstado});
      ChangeBus.instance.notifyAll(['produccion']);
      _cargarTodo();
    } catch (e) {
      _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'Error al cambiar estado de orden.'));
    }
  }

  Future<void> _eliminarOrden(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Orden Cancelada'),
        content: const Text('¿Deseas eliminar definitivamente este registro de orden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (conf == true) {
      try {
        await ProductionService.instance.eliminarOrdenProduccion(id);
        ChangeBus.instance.notifyAll(['produccion']);
        _cargarTodo();
      } catch (e) {
        _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo eliminar la orden.'));
      }
    }
  }

  void _abrirModalNuevaOrden() {
    if (_calculadoraData == null || _calculadoraData!.formulas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configura al menos una fórmula para crear órdenes')));
      return;
    }

    ProductionFormulaModel formulaSeleccionada = _formulaSeleccionada ?? _calculadoraData!.formulas.first;
    final cantidadCtrl = TextEditingController(text: '50');
    final manoObraCtrl = TextEditingController(text: '${formulaSeleccionada.manoObraSugerida > 0 ? formulaSeleccionada.manoObraSugerida : 35000}');
    final precioCtrl = TextEditingController(text: '${formulaSeleccionada.precioVenta > 0 ? formulaSeleccionada.precioVenta : 85000}');
    final notasCtrl = TextEditingController();
    String estadoSeleccionado = 'planificada';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cant = int.tryParse(cantidadCtrl.text.trim()) ?? 1;
            final mo = double.tryParse(manoObraCtrl.text.trim()) ?? 0;
            final pv = double.tryParse(precioCtrl.text.trim()) ?? 0;

            double insumosUnidad = 0;
            for (final c in formulaSeleccionada.consumos) {
              final mat = _calculadoraData?.buscarMateriaPorId(c.materiaPrimaId);
              insumosUnidad += (c.cantidad * (mat?.costoUnitario ?? c.insumoCosto));
            }
            final costoLote = (insumosUnidad + mo) * cant;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: const BoxDecoration(
                color: FashionColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FashionColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text('Nueva Orden de Producción', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ProductionFormulaModel>(
                      value: formulaSeleccionada,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Prenda a Confeccionar *', border: OutlineInputBorder()),
                      items: _calculadoraData!.formulas.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f.nombre, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            formulaSeleccionada = val;
                            if (val.manoObraSugerida > 0) manoObraCtrl.text = '${val.manoObraSugerida}';
                            if (val.precioVenta > 0) precioCtrl.text = '${val.precioVenta}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cantidadCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Cantidad (Prendas) *', border: OutlineInputBorder()),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: manoObraCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Mano de Obra / Ud', border: OutlineInputBorder()),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: precioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Precio Venta Unitario', border: OutlineInputBorder()),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: estadoSeleccionado,
                            decoration: const InputDecoration(labelText: 'Estado Inicial', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'planificada', child: Text('Planificada')),
                              DropdownMenuItem(value: 'en_proceso', child: Text('En Proceso')),
                            ],
                            onChanged: (v) => setModalState(() => estadoSeleccionado = v ?? 'planificada'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notasCtrl,
                      decoration: const InputDecoration(labelText: 'Notas / Observaciones del lote', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: FashionColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: FashionColors.borderSubtle)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Costo Estimado del Lote:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(CurrencyFormatter.formatearCOP(costoLote), style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FashionColors.inkPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (cant <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('La cantidad debe ser mayor a 0')));
                            return;
                          }
                          try {
                            await ProductionService.instance.crearOrdenProduccion({
                              'formula_id': formulaSeleccionada.idFormula > 0 ? formulaSeleccionada.idFormula : formulaSeleccionada.id,
                              'cantidad': cant,
                              'costo_mano_obra': mo,
                              'precio_venta': pv,
                              'costo_total': costoLote,
                              'estado': estadoSeleccionado,
                              if (notasCtrl.text.trim().isNotEmpty) 'notas': notasCtrl.text.trim(),
                            });
                            Navigator.pop(ctx);
                            ChangeBus.instance.notifyAll(['produccion', 'dashboard']);
                            _cargarTodo();
                          } catch (e) {
                            _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'Error al crear la orden de producción.'));
                          }
                        },
                        child: const Text('Generar Orden de Producción'),
                      ),
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

  void _mostrarErrorDialog(String mensaje) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: FashionColors.peligro),
            const SizedBox(width: 8),
            Text('Aviso de Producción', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(mensaje, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.inkPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
