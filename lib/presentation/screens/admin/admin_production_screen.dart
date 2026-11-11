// @source-mirror: src/views/admin/VistaPedidosyFacturas.vue, src/components/pedidos/ModalGestionDespacho.vue, src/components/facturas/ModalCrearFactura.vue, src/components/facturas/ModalCargaMasivaFacturas.vue, src/views/admin/VistaProduccion.vue, src/components/produccion/CalculadoraProduccion.vue, src/components/produccion/GestorOrdenesProduccion.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
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

  bool _cargando = true;
  CalculatorDataset? _calculadoraData;
  List<Map<String, dynamic>> _materias = [];
  List<Map<String, dynamic>> _formulas = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _ordenes = [];

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    try {
      final resultados = await Future.wait([
        ProductionService.instance.cargarDatosCalculadora(),
        ProductionService.instance.listarMateriasPrimas(),
        ProductionService.instance.listarFormulas(),
        ProductionService.instance.listarProveedores(),
        ProductionService.instance.listarOrdenesProduccion(),
      ]);

      if (mounted) {
        final calcData = resultados[0] as CalculatorDataset;
        setState(() {
          _calculadoraData = calcData;
          _materias = resultados[1] as List<Map<String, dynamic>>;
          _formulas = resultados[2] as List<Map<String, dynamic>>;
          _proveedores = resultados[3] as List<Map<String, dynamic>>;
          _ordenes = resultados[4] as List<Map<String, dynamic>>;
          if (calcData.formulas.isNotEmpty) {
            _formulaSeleccionada = calcData.formulas.first;
          }
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/produccion',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: FashionColors.inkPrimary,
              unselectedLabelColor: FashionColors.inkSecondary,
              indicatorColor: FashionColors.brandAccent,
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
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
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

  // 1. SIMULADOR Y CALCULADORA
  Widget _construirSimulador() {
    if (_calculadoraData == null || _calculadoraData!.formulas.isEmpty) {
      return const Center(child: Text('Crea fórmulas de producción para usar el simulador.'));
    }

    final f = _formulaSeleccionada ?? _calculadoraData!.formulas.first;

    // Costo insumos por prenda
    double costoInsumosUnidad = 0;
    bool factible = true;
    final List<String> faltantes = [];

    for (final c in f.consumos) {
      final insumo = _calculadoraData!.buscarMateriaPorId(c.materiaPrimaId);
      final costoUnitario = insumo?.costoUnitario ?? 0;
      final stockActual = insumo?.stockActual ?? 0;
      final requeridoTotal = c.cantidad * _cantidadProducir;

      costoInsumosUnidad += (c.cantidad * costoUnitario);
      if (requeridoTotal > stockActual) {
        factible = false;
        faltantes.add('${insumo?.nombre ?? "Insumo"} (Req: $requeridoTotal, Stock: $stockActual)');
      }
    }

    final costoTotalUnidad = costoInsumosUnidad + _costoManoObra;
    final costoLoteTotal = costoTotalUnidad * _cantidadProducir;
    final ingresoTotal = _precioVenta * _cantidadProducir;
    final utilidadNeta = ingresoTotal - costoLoteTotal;
    final margenPorcentaje = ingresoTotal > 0 ? ((utilidadNeta / ingresoTotal) * 100) : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<ProductionFormulaModel>(
          initialValue: f,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Fórmula de prenda', border: OutlineInputBorder()),
          items: _calculadoraData!.formulas.map((form) => DropdownMenuItem(value: form, child: Text(form.nombre, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) => setState(() => _formulaSeleccionada = val),
        ),
        const SizedBox(height: 12),

        // Parámetros
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: FashionColors.grisBorde)),
          child: Column(
            children: [
              _filaSimulador('Costo insumos (unidad):', CurrencyFormatter.formatearCOP(costoInsumosUnidad)),
              _filaSimulador('Mano de obra (unidad):', CurrencyFormatter.formatearCOP(_costoManoObra)),
              _filaSimulador('Costo total unitario:', CurrencyFormatter.formatearCOP(costoTotalUnidad), negrita: true),
              const Divider(),
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
            backgroundColor: FashionColors.brandAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () async {
            try {
              await ProductionService.instance.crearOrdenProduccion({
                'formula_id': f.id,
                'cantidad': _cantidadProducir,
                'costo_mano_obra': _costoManoObra,
                'costo_estimado': costoLoteTotal,
                'estado': 'planificada',
              });
              _cargarTodo();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orden de producción generada en estado Planificada')));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible crear la orden de producción.')),
                    backgroundColor: FashionColors.peligro,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.post_add),
          label: Text('Generar Orden de Producción', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        const SizedBox(height: 96),
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

  // 2. MATERIAS PRIMAS
  Widget _construirMateriasPrimas() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
      itemCount: _materias.length,
      itemBuilder: (context, index) {
        final m = _materias[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
          child: ListTile(
            leading: const Icon(Icons.layers, color: Color(0xFF2563EB)),
            title: Text(m['nombre']?.toString() ?? 'Insumo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
            subtitle: Text(
              'Stock: ${m['stock_actual']} ${m['unidad_medida']?['codigo'] ?? ''} · Costo: ${CurrencyFormatter.formatearCOP(JsonParser.toDouble(m['costo_unitario']))}',
              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: FashionColors.inkSecondary),
            ),
          ),
        );
      },
    );
  }

  // 3. FÓRMULAS
  Widget _construirFormulas() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
      itemCount: _formulas.length,
      itemBuilder: (context, index) {
        final f = _formulas[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
          child: ListTile(
            leading: const Icon(Icons.format_list_bulleted, color: Color(0xFF7C3AED)),
            title: Text(f['nombre']?.toString() ?? 'Fórmula', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
            subtitle: Text('${(f['consumos'] as List?)?.length ?? 0} insumos configurados', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary)),
          ),
        );
      },
    );
  }

  // 4. PROVEEDORES
  Widget _construirProveedores() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
      itemCount: _proveedores.length,
      itemBuilder: (context, index) {
        final p = _proveedores[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
          child: ListTile(
            leading: const Icon(Icons.store, color: Color(0xFF0D9488)),
            title: Text(p['nombre']?.toString() ?? 'Proveedor', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
            subtitle: Text('Contacto: ${p['contacto'] ?? ''} · Tel: ${p['telefono'] ?? ''}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary)),
          ),
        );
      },
    );
  }

  // 5. ÓRDENES DE PRODUCCIÓN
  Widget _construirOrdenes() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
      itemCount: _ordenes.length,
      itemBuilder: (context, index) {
        final o = _ordenes[index];
        final id = o['id_orden'] ?? o['id'];
        final estado = o['estado']?.toString() ?? 'planificada';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
          child: ListTile(
            title: Text('Orden #$id · ${o['formula']?['nombre'] ?? "Lote"}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: FashionColors.inkPrimary)),
            subtitle: Text(
              'Volumen: ${o['cantidad']} prendas · Costo: ${CurrencyFormatter.formatearCOP(JsonParser.toDouble(o['costo_estimado']))}',
              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: FashionColors.inkSecondary),
            ),
            trailing: estado != 'completada'
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: FashionColors.statusSuccess, foregroundColor: Colors.white),
                    onPressed: () async {
                      try {
                        await ProductionService.instance.completarOrdenProduccion(id);
                        _cargarTodo();
                      } catch (_) {}
                    },
                    child: Text('Completar', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700)),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: FashionColors.statusSuccess.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text('Completada', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: FashionColors.statusSuccess)),
                  ),
          ),
        );
      },
    );
  }
}
