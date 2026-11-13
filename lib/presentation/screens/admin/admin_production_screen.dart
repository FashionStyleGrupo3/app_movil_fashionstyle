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
  // 3. FÓRMULAS DE PRODUCCIÓN
  // ==========================================
  Widget _construirFormulas() {
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
              Text('${_formulas.length} Fórmulas configuradas', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkSecondary)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionColors.inkPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _abrirModalNuevaFormula(),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Nueva Fórmula', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _formulas.isEmpty
              ? RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 48),
                      Icon(Icons.format_list_bulleted_outlined, size: 48, color: FashionColors.inkSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Center(child: Text('No hay fórmulas configuradas', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 14))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                    itemCount: _formulas.length,
                    itemBuilder: (context, index) {
                      final f = _formulas[index];
                      final consumos = (f['consumos'] as List?) ?? [];
                      final nombre = f['nombre']?.toString() ?? 'Prenda';
                      final precio = JsonParser.toDouble(f['precio_venta']);

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                            child: const Icon(Icons.format_list_bulleted, color: Color(0xFF7C3AED), size: 20),
                          ),
                          title: Text(nombre, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
                          subtitle: Text(
                            '${consumos.length} insumos · PVP: ${CurrencyFormatter.formatearCOP(precio)}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: FashionColors.inkSecondary),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              color: FashionColors.surfaceMuted,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Insumos de Confección:', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  if (consumos.isEmpty)
                                    const Text('Sin insumos registrados', style: TextStyle(fontSize: 11, color: FashionColors.inkSecondary))
                                  else
                                    ...consumos.map((c) {
                                      final mId = c['materia_prima_id'];
                                      final materia = _calculadoraData?.buscarMateriaPorId(JsonParser.toInt(mId));
                                      final cant = JsonParser.toDouble(c['cantidad']);
                                      final unid = c['unidad'] ?? materia?.unidad ?? 'un';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('• ${materia?.nombre ?? "Insumo #$mId"}', style: const TextStyle(fontSize: 12)),
                                            Text('$cant $unid', style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _abrirModalNuevaFormula() {
    int? selectedProductoId;
    int? selectedMateriaId;
    final cantidadCtrl = TextEditingController(text: '1.5');
    final notasCtrl = TextEditingController();

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
                    Text('Nueva Fórmula de Producción', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedProductoId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Prenda / Producto *', border: OutlineInputBorder()),
                      items: (_calculadoraData?.formulas ?? []).map((f) {
                        return DropdownMenuItem<int>(
                          value: f.productoId,
                          child: Text(f.nombre, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedProductoId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedMateriaId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Materia Prima / Insumo *', border: OutlineInputBorder()),
                      items: _materias.map((m) {
                        final id = m['id_material'] ?? m['id'];
                        return DropdownMenuItem<int>(
                          value: id is int ? id : int.tryParse(id.toString()),
                          child: Text('${m['nombre']} (${m['unidad'] ?? "un"})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedMateriaId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cantidadCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Consumo por unidad confeccionada *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notasCtrl,
                      decoration: const InputDecoration(labelText: 'Notas / Observaciones', border: OutlineInputBorder()),
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
                          if (selectedProductoId == null || selectedMateriaId == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Selecciona producto y materia prima')));
                            return;
                          }
                          try {
                            await ProductionService.instance.crearFormula({
                              'producto_id': selectedProductoId,
                              'materia_prima_id': selectedMateriaId,
                              'cantidad': double.tryParse(cantidadCtrl.text.trim()) ?? 1,
                              'notas': notasCtrl.text.trim(),
                            });
                            Navigator.pop(ctx);
                            ChangeBus.instance.notifyAll(['produccion']);
                            _cargarTodo();
                          } catch (e) {
                            _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'Error al registrar insumo en la fórmula.'));
                          }
                        },
                        child: const Text('Agregar Insumo a la Fórmula'),
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
  // 5. ÓRDENES DE PRODUCCIÓN (COMPLETAR & CRUD)
  // ==========================================
  Widget _construirOrdenes() {
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
              Text('${_ordenes.length} Órdenes de Producción', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkSecondary)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionColors.inkPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _abrirModalNuevaOrden(),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Nueva Orden', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ordenes.isEmpty
              ? RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 48),
                      Icon(Icons.assignment_outlined, size: 48, color: FashionColors.inkSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Center(child: Text('No hay órdenes de producción registradas', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 14))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarTodo,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                    itemCount: _ordenes.length,
                    itemBuilder: (context, index) {
                      final o = _ordenes[index];
                      final id = o['id_orden'] ?? o['id'];
                      final numero = o['numero']?.toString() ?? 'ORD-#$id';
                      final estado = (o['estado']?.toString() ?? 'planificada').toLowerCase();
                      final esCompletada = estado == 'completada';
                      final esCancelada = estado == 'cancelada' || estado == 'cancelado';
                      final nombrePrenda = _nombrePrendaOrden(o);
                      final costoReal = _extraerCostoOrden(o);
                      final cantidad = JsonParser.toInt(o['cantidad']);

                      Color badgeColor = FashionColors.slateAccent;
                      if (esCompletada) badgeColor = FashionColors.verdeExito;
                      if (esCancelada) badgeColor = FashionColors.peligro;
                      if (estado == 'en_proceso') badgeColor = const Color(0xFF2563EB);
                      if (estado == 'pausada') badgeColor = FashionColors.aviso;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(numero, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      estado.toUpperCase(),
                                      style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700, color: badgeColor),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!esCompletada && !esCancelada)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz, size: 18),
                                      onSelected: (val) {
                                        if (val == 'cancelar') {
                                          _cancelarOrden(id);
                                        } else if (val == 'en_proceso' || val == 'pausada') {
                                          _cambiarEstadoOrden(id, val);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        if (estado != 'en_proceso')
                                          const PopupMenuItem(value: 'en_proceso', child: Text('Pasar a En Proceso')),
                                        if (estado != 'pausada')
                                          const PopupMenuItem(value: 'pausada', child: Text('Pausar Orden')),
                                        const PopupMenuItem(value: 'cancelar', child: Text('Cancelar Orden', style: TextStyle(color: FashionColors.peligro))),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(nombrePrenda, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Lote: $cantidad prendas', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: FashionColors.inkSecondary)),
                                  const Text(' · ', style: TextStyle(color: FashionColors.inkSecondary)),
                                  Text('Costo: ${CurrencyFormatter.formatearCOP(costoReal)}', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.inkPrimary)),
                                ],
                              ),
                              if (o['notas'] != null && o['notas'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Notas: ${o['notas']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: FashionColors.inkSecondary)),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!esCompletada && !esCancelada) ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: FashionColors.verdeExito,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _abrirModalCompletar(o),
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: Text('Completar Orden', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                  if (esCancelada) ...[
                                    TextButton.icon(
                                      style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
                                      onPressed: () => _eliminarOrden(id),
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text('Eliminar Orden', style: TextStyle(fontSize: 11)),
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

  Future<void> _cancelarOrden(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Orden'),
        content: const Text('¿Estás seguro de cancelar esta orden de producción?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FashionColors.peligro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar Orden'),
          ),
        ],
      ),
    );

    if (conf == true) {
      try {
        await ProductionService.instance.cancelarOrdenProduccion(id);
        ChangeBus.instance.notifyAll(['produccion']);
        _cargarTodo();
      } catch (e) {
        _mostrarErrorDialog(ApiClient.obtenerMensajeError(e, 'No se pudo cancelar la orden.'));
      }
    }
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
