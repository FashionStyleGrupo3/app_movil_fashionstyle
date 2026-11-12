// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/constants/payment_constants.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/services/invoice_pdf_service.dart';
import 'package:fashion_style_mobile/data/services/pos_sale_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Modal de Registro de Venta Mostrador (POS)
class ModalNuevaVentaPos extends StatefulWidget {
  final VoidCallback onCobrada;

  const ModalNuevaVentaPos({super.key, required this.onCobrada});

  @override
  State<ModalNuevaVentaPos> createState() => _ModalNuevaVentaPosState();
}

class _ModalNuevaVentaPosState extends State<ModalNuevaVentaPos> {
  List<Product> _productos = [];
  bool _cargandoProds = true;
  String _busqueda = '';

  final List<Map<String, dynamic>> _bolsa = [];
  String _medioPago = 'efectivo';
  final TextEditingController _nombreCtrl = TextEditingController(text: 'Consumidor Final');
  final TextEditingController _docCtrl = TextEditingController(text: '222222222222');
  final TextEditingController _telCtrl = TextEditingController();
  bool _procesandoCobro = false;

  @override
  void initState() {
    super.initState();
    _cargarPrendas();
  }

  Future<void> _cargarPrendas() async {
    try {
      final p = await ProductService.instance.obtenerProductos();
      if (mounted) setState(() => _productos = p);
    } catch (_) {}
    if (mounted) setState(() => _cargandoProds = false);
  }

  double get _totalBolsa {
    return _bolsa.fold(0.0, (sum, it) => sum + (it['precio'] * it['cantidad']));
  }

  void _agregarPrenda(Product p, ProductVariant v) {
    if (v.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La talla "${v.talla}" de "${p.nombre}" no tiene stock disponible'),
          backgroundColor: FashionColors.peligro,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final idVariante = v.idVariante > 0 ? v.idVariante : (v.id > 0 ? v.id : 0);
    final precioItem = v.precioVenta > 0 ? v.precioVenta : p.precioMinimo;

    setState(() {
      final idx = _bolsa.indexWhere((it) => it['variante_id'] == idVariante);
      if (idx != -1) {
        if (_bolsa[idx]['cantidad'] < v.stock) {
          _bolsa[idx]['cantidad'] += 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock máximo alcanzado para talla "${v.talla}" (${v.stock} disponibles)'),
              backgroundColor: FashionColors.peligro,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      } else {
        _bolsa.add({
          'variante_id': idVariante,
          'nombre': p.nombre,
          'talla': v.talla,
          'sku': v.sku,
          'precio': precioItem,
          'cantidad': 1,
          'max_stock': v.stock,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agregado: ${p.nombre} (${v.talla}) · ${CurrencyFormatter.formatearCOP(precioItem)}'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: FashionColors.verdeExito,
      ),
    );
  }

  void _abrirDialogoSeleccionTalla(Product p) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 56,
                child: p.primeraImagenUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.primeraImagenUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: FashionColors.surfaceMuted,
                          child: const Icon(Icons.checkroom, color: FashionColors.inkPrimary, size: 20),
                        ),
                      )
                    : Container(
                        color: FashionColors.surfaceMuted,
                        child: const Icon(Icons.checkroom, color: FashionColors.inkPrimary, size: 20),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                  ),
                  Text(
                    '${p.categoria?.nombre ?? "Prenda"} · Selecciona una talla',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(dlgCtx),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: p.variantes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Esta prenda no tiene tallas configuradas.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkMuted),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: p.variantes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final v = p.variantes[idx];
                    final disponible = v.stock > 0;
                    final precio = v.precioVenta > 0 ? v.precioVenta : p.precioMinimo;

                    return Container(
                      decoration: BoxDecoration(
                        color: disponible ? FashionColors.surfaceMuted : FashionColors.surfaceMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: disponible ? FashionColors.borderSubtle : FashionColors.borderSubtle.withValues(alpha: 0.5),
                        ),
                      ),
                      child: InkWell(
                        onTap: disponible
                            ? () {
                                Navigator.pop(dlgCtx);
                                _agregarPrenda(p, v);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: disponible ? FashionColors.inkPrimary : FashionColors.borderSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    v.talla.toUpperCase(),
                                    style: GoogleFonts.jetBrainsMono(
                                      color: disponible ? Colors.white : FashionColors.inkMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatearCOP(precio),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: FashionColors.inkPrimary,
                                      ),
                                    ),
                                    Text(
                                      disponible ? 'Stock: ${v.stock} uds disponibles' : 'Agotado (0 uds)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: disponible ? FashionColors.statusSuccess : FashionColors.statusDanger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: disponible ? FashionColors.inkPrimary : FashionColors.surfacePanel,
                                  foregroundColor: disponible ? Colors.white : FashionColors.inkMuted,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: disponible
                                    ? () {
                                        Navigator.pop(dlgCtx);
                                        _agregarPrenda(p, v);
                                      }
                                    : null,
                                child: Text(
                                  disponible ? '+ Agregar' : 'Agotado',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _cobrarVenta() async {
    if (_bolsa.isEmpty) return;

    setState(() => _procesandoCobro = true);
    try {
      final payload = {
        'medio_pago': _medioPago,
        'cliente_nombre': _nombreCtrl.text.trim(),
        'cliente_documento': _docCtrl.text.trim(),
        'cliente_telefono': _telCtrl.text.trim(),
        'items': _bolsa.map((it) => {
          'variante_id': it['variante_id'],
          'cantidad': it['cantidad'],
          'precio_unitario': it['precio'],
        }).toList(),
      };

      final venta = await PosSaleService.instance.registrarVenta(
        items: (payload['items'] as List).cast<Map<String, dynamic>>(),
        medioPago: _medioPago,
        clienteNombre: _nombreCtrl.text.trim(),
        clienteDocumento: _docCtrl.text.trim(),
      );
      widget.onCobrada();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta POS registrada: ${venta.codigo}'),
            backgroundColor: FashionColors.verdeExito,
          ),
        );
        InvoicePdfGenerator.generarYCompartirReciboPos(venta);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo procesar la venta en el punto de venta.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesandoCobro = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: FashionColors.backgroundCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: FashionColors.bordeClaro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Caja Mostrador (POS)',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.textoPrincipal),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),

          // Buscador de prendas
          TextField(
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar prendas para agregar a la venta...',
              hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: FashionColors.textoMuted),
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              filled: true,
              fillColor: FashionColors.surfaceSecondary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.bordeClaro)),
            ),
            onChanged: (val) => setState(() => _busqueda = val),
          ),
          const SizedBox(height: 8),

          // Catálogo rápido de selección con modal de tallas
          SizedBox(
            height: 120,
            child: _cargandoProds
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final p = _productos[index];
                      if (_busqueda.isNotEmpty && !p.nombre.toLowerCase().contains(_busqueda.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        width: 156,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: FashionColors.surfaceCard,
                          border: Border.all(color: FashionColors.borderSubtle),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _abrirDialogoSeleccionTalla(p),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 38,
                                          height: 48,
                                          child: p.primeraImagenUrl.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: p.primeraImagenUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => Container(
                                                    color: FashionColors.surfaceMuted,
                                                    child: const Icon(Icons.checkroom, color: FashionColors.inkPrimary, size: 18),
                                                  ),
                                                )
                                              : Container(
                                                  color: FashionColors.surfaceMuted,
                                                  child: const Icon(Icons.checkroom, color: FashionColors.inkPrimary, size: 18),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.nombre,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                color: FashionColors.inkPrimary,
                                                height: 1.15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              CurrencyFormatter.formatearCOP(p.precioMinimo),
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 10.5,
                                                color: FashionColors.inkPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: FashionColors.inkPrimary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.touch_app_outlined, size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Elegir talla',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 10),
          const Divider(color: FashionColors.bordeClaro),

          // Bolsa de mostrador
          Expanded(
            child: _bolsa.isEmpty
                ? Center(
                    child: Text(
                      'Toca una prenda arriba para elegir talla y agregar a la venta',
                      style: GoogleFonts.poppins(color: FashionColors.textoMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _bolsa.length,
                    itemBuilder: (context, index) {
                      final it = _bolsa[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: FashionColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FashionColors.bordeClaro),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            '${it['nombre']} (${it['talla']})',
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 12.5, color: FashionColors.textoPrincipal),
                          ),
                          subtitle: Text(
                            '${CurrencyFormatter.formatearCOP(it['precio'])} x${it['cantidad']}',
                            style: GoogleFonts.poppins(fontSize: 11, color: FashionColors.textoMuted),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.remove_circle_outline, size: 18),
                                onPressed: () {
                                  setState(() {
                                    if (it['cantidad'] > 1) {
                                      it['cantidad'] -= 1;
                                    } else {
                                      _bolsa.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text('${it['cantidad']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                onPressed: () {
                                  if (it['cantidad'] < it['max_stock']) {
                                    setState(() => it['cantidad'] += 1);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Stock máximo alcanzado (${it['max_stock']})'),
                                        backgroundColor: FashionColors.peligro,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline, size: 20, color: FashionColors.peligro),
                                tooltip: 'Quitar de la venta',
                                onPressed: () {
                                  setState(() {
                                    _bolsa.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Medio de pago y total
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _medioPago,
                  style: GoogleFonts.poppins(fontSize: 13, color: FashionColors.textoPrincipal),
                  decoration: InputDecoration(
                    labelText: 'Medio de pago',
                    filled: true,
                    fillColor: FashionColors.surfaceSecondary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.bordeClaro)),
                  ),
                  items: mediosPagoPos.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _medioPago = v ?? 'efectivo'),
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total:', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: FashionColors.textoMuted)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        CurrencyFormatter.formatearCOP(_totalBolsa),
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: FashionColors.textoPrincipal),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: FashionColors.primaryCorporate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _procesandoCobro || _bolsa.isEmpty ? null : _cobrarVenta,
              icon: _procesandoCobro ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
              label: Text(
                _procesandoCobro ? 'Procesando...' : 'Cobrar e Imprimir Comprobante',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
