// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modal para administrar las promociones y descuentos del catálogo
class ModalPromocionesSheet extends StatefulWidget {
  final List<Product> productos;

  const ModalPromocionesSheet({super.key, required this.productos});

  @override
  State<ModalPromocionesSheet> createState() => _ModalPromocionesSheetState();
}

class _ModalPromocionesSheetState extends State<ModalPromocionesSheet> {
  bool _cargando = true;
  List<Promotion> _promociones = [];

  @override
  void initState() {
    super.initState();
    _cargarPromos();
  }

  Future<void> _cargarPromos() async {
    setState(() => _cargando = true);
    try {
      final promos = await PromotionService.instance.listarPromociones();
      if (mounted) setState(() => _promociones = promos);
    } catch (_) {
      try {
        final vigentes = await PromotionService.instance.obtenerPromocionesVigentes(forzar: true);
        if (mounted) setState(() => _promociones = vigentes);
      } catch (_) {}
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _crearPromoModal() {
    final nombreCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    String tipo = 'porcentaje';
    int? productoId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Nueva Promoción',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreCtrl,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la promoción *',
                    hintText: 'Ej. Gran Descuento de Temporada',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo de Descuento'),
                  items: const [
                    DropdownMenuItem(value: 'porcentaje', child: Text('Porcentaje (%)')),
                    DropdownMenuItem(value: 'monto', child: Text('Monto fijo (COP)')),
                  ],
                  onChanged: (v) => setDState(() => tipo = v ?? 'porcentaje'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valorCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Valor del descuento *',
                    hintText: tipo == 'porcentaje' ? 'Ej. 20' : 'Ej. 15000',
                    suffixText: tipo == 'porcentaje' ? '%' : 'COP',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: productoId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Aplicar a'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toda la tienda (Global)')),
                    ...widget.productos.map((p) => DropdownMenuItem(
                          value: p.idProducto,
                          child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) => setDState(() => productoId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: FashionColors.textoMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.primaryCorporate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final nom = nombreCtrl.text.trim();
                final val = double.tryParse(valorCtrl.text.trim()) ?? 0;
                if (nom.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre de la promoción es obligatorio.'),
                      backgroundColor: FashionColors.peligro,
                    ),
                  );
                  return;
                }
                if (val <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El valor del descuento debe ser mayor a cero.'),
                      backgroundColor: FashionColors.peligro,
                    ),
                  );
                  return;
                }
                if (tipo == 'porcentaje' && val > 90) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El descuento máximo permitido es 90%.'),
                      backgroundColor: FashionColors.peligro,
                    ),
                  );
                  return;
                }

                // Regla de exclusión mutua estricta:
                // 1. Si se intenta crear una promoción global (Toda la tienda):
                //    No debe haber promociones activas para prendas específicas.
                if (productoId == null) {
                  final especificasActivas = _promociones.where((p) => p.activa && p.idProducto != null).toList();
                  if (especificasActivas.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Conflicto de Promoción', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                        content: Text(
                          'No puedes crear una promoción para toda la tienda mientras existan ${especificasActivas.length} promoción(es) activa(s) para prendas específicas (${especificasActivas.map((e) => e.nombre).take(2).join(', ')}).\n\nElimina o desactiva las promociones específicas primero para evitar cobros inconsistentes.',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: Text('Entendido', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                } else {
                  // 2. Si se intenta crear una promoción para una prenda específica:
                  //    No debe haber una promoción global activa para toda la tienda.
                  final globalesActivas = _promociones.where((p) => p.activa && p.idProducto == null).toList();
                  if (globalesActivas.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Conflicto de Promoción', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                        content: Text(
                          'No puedes crear una promoción específica mientras exista una promoción global activa para toda la tienda («${globalesActivas.first.nombre}»).\n\nElimina o desactiva la promoción global primero.',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: Text('Entendido', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // 3. Tampoco puede haber otra promoción activa para la misma prenda
                  final mismaPrenda = _promociones.where((p) => p.activa && p.idProducto == productoId).toList();
                  if (mismaPrenda.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Conflicto de Promoción', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                        content: Text(
                          'Esta prenda ya cuenta con la promoción activa «${mismaPrenda.first.nombre}».\n\nEdita o elimina la promoción existente antes de registrar otra.',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: Text('Entendido', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                }

                Navigator.pop(ctx);
                try {
                  await PromotionService.instance.crearPromocion({
                    'nombre': nom,
                    'tipo': tipo,
                    'valor': val,
                    'producto_id': productoId,
                    'activa': true,
                  });
                  PromotionService.instance.invalidarCachePromociones();
                  await _cargarPromos();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Promoción creada exitosamente.'),
                        backgroundColor: FashionColors.verdeExito,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible crear la promoción.')),
                        backgroundColor: FashionColors.peligro,
                      ),
                    );
                  }
                }
              },
              child: Text('Guardar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: FashionColors.backgroundCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: FashionColors.bordeClaro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Campañas y Promociones',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: FashionColors.textoPrincipal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionColors.primaryCorporate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _crearPromoModal,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Nueva Promo',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _promociones.isEmpty
                    ? Center(
                        child: Text(
                          'No hay promociones registradas',
                          style: GoogleFonts.poppins(color: FashionColors.textoMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _promociones.length,
                        itemBuilder: (context, index) {
                          final pr = _promociones[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: FashionColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FashionColors.bordeClaro),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: pr.activa
                                      ? FashionColors.verdeExito.withValues(alpha: 0.12)
                                      : FashionColors.textoMuted.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.local_offer,
                                  color: pr.activa ? FashionColors.verdeExito : FashionColors.textoMuted,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                pr.nombre,
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: FashionColors.textoPrincipal,
                                ),
                              ),
                              subtitle: Text(
                                '${pr.tipo == "porcentaje" ? "${pr.valor.toInt()}%" : CurrencyFormatter.formatearCOP(pr.valor)} · ${pr.nombreProducto ?? "Toda la tienda"}',
                                style: GoogleFonts.poppins(fontSize: 12, color: FashionColors.textoMuted),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: FashionColors.peligro),
                                tooltip: 'Eliminar promoción',
                                onPressed: () async {
                                  if (pr.id == null) return;
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text(
                                        'Eliminar promoción',
                                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                                      ),
                                      content: Text(
                                        '¿Deseas eliminar definitivamente la promoción "${pr.nombre}"?',
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text('Cancelar', style: GoogleFonts.poppins(color: FashionColors.textoMuted)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: FashionColors.peligro,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text('Eliminar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmar != true) return;

                                  try {
                                    await PromotionService.instance.eliminarPromocion(pr.id!);
                                    PromotionService.instance.invalidarCachePromociones();
                                    await _cargarPromos();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Promoción eliminada correctamente.'),
                                          backgroundColor: FashionColors.verdeExito,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible eliminar la promoción.')),
                                          backgroundColor: FashionColors.peligro,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
