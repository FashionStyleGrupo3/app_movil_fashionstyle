// @source-mirror: src/components/facturas/VisorFacturaFashion.vue
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/currency_formatter.dart';
import '../../data/services/order_and_invoice_service.dart';
import '../../data/services/pos_and_payment_service.dart';

class InvoicePdfGenerator {
  static const PdfColor _colorPrimario = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _colorRosa = PdfColor.fromInt(0xFFF43F5E);
  static const PdfColor _colorGrisClaro = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor _colorTextoMuted = PdfColor.fromInt(0xFF64748B);

  static Future<void> generarYCompartirFactura(InvoiceModel factura) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ENCABEZADO Y MEMBRETE BOUTIQUE
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FASHION STYLE',
                        style: pw.TextStyle(
                          color: _colorRosa,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Boutique de Confección & Moda Femenina', style: const pw.TextStyle(fontSize: 10, color: _colorTextoMuted)),
                      pw.Text('NIT: 901.842.109-4 · Régimen Común', style: const pw.TextStyle(fontSize: 10, color: _colorTextoMuted)),
                      pw.Text('Medellín, Colombia · Tel: +57 300 000 0000', style: const pw.TextStyle(fontSize: 10, color: _colorTextoMuted)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: _colorGrisClaro,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'FACTURA DE VENTA',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _colorPrimario),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(factura.numero, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _colorRosa)),
                        pw.SizedBox(height: 4),
                        pw.Text('Fecha: ${factura.fecha ?? 'N/A'}', style: const pw.TextStyle(fontSize: 9, color: _colorTextoMuted)),
                        pw.Text('Estado: ${factura.estado.toUpperCase()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _colorPrimario)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Divider(color: _colorRosa, thickness: 1.5),
              pw.SizedBox(height: 12),

              // DATOS DEL CLIENTE
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _colorGrisClaro),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DATOS DEL ADQUIRENTE / CLIENTE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _colorTextoMuted)),
                        pw.SizedBox(height: 4),
                        pw.Text(factura.clienteNombre.isNotEmpty ? factura.clienteNombre : 'Consumidor Final', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('C.C./NIT: ${factura.clienteDocumento.isNotEmpty ? factura.clienteDocumento : '222222222222'}', style: const pw.TextStyle(fontSize: 9)),
                        if (factura.clienteCorreo.isNotEmpty) pw.Text('Correo: ${factura.clienteCorreo}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('DIRECCIÓN DE ENTREGA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _colorTextoMuted)),
                        pw.SizedBox(height: 4),
                        pw.Text(factura.clienteDireccion.isNotEmpty ? factura.clienteDireccion : 'Mostrador Principal', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Ciudad: ${factura.clienteCiudad.isNotEmpty ? factura.clienteCiudad : 'Medellín'}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Medio de pago: ${factura.metodoPago}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // TABLA DE DETALLES
              pw.Table(
                border: pw.TableBorder.all(color: _colorGrisClaro, width: 0.8),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(2),
                  4: pw.FlexColumnWidth(2),
                },
                children: [
                  // Cabecera
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _colorGrisClaro),
                    children: [
                      _celdaHeader('Descripción / Prenda'),
                      _celdaHeader('Talla', align: pw.TextAlign.center),
                      _celdaHeader('Cant.', align: pw.TextAlign.center),
                      _celdaHeader('Precio Unit.', align: pw.TextAlign.right),
                      _celdaHeader('Subtotal', align: pw.TextAlign.right),
                    ],
                  ),
                  // Filas
                  ...factura.detalles.map(
                    (it) => pw.TableRow(
                      children: [
                        _celda(it.descripcion),
                        _celda(it.talla, align: pw.TextAlign.center),
                        _celda('${it.cantidad}', align: pw.TextAlign.center),
                        _celda(CurrencyFormatter.formatearCOP(it.precio), align: pw.TextAlign.right),
                        _celda(CurrencyFormatter.formatearCOP(it.subtotal), align: pw.TextAlign.right),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // TOTALES
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _filaTotales('Subtotal:', CurrencyFormatter.formatearCOP(factura.subtotal)),
                        if (factura.descuento > 0)
                          _filaTotales('Descuento:', '-${CurrencyFormatter.formatearCOP(factura.descuento)}'),
                        _filaTotales('Impuestos (IVA):', CurrencyFormatter.formatearCOP(factura.impuestos)),
                        pw.Divider(color: _colorPrimario),
                        _filaTotales(
                          'TOTAL PAGADO:',
                          CurrencyFormatter.formatearCOP(factura.total),
                          esTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // PIE DE PÁGINA
              pw.Divider(color: _colorGrisClaro),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Gracias por tu compra en Fashion Style Boutique. Conserva esta factura para cambios o garantías (30 días).',
                  style: const pw.TextStyle(fontSize: 8, color: _colorTextoMuted),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Factura_${factura.numero}.pdf',
    );
  }

  static Future<void> generarYCompartirReciboPos(PosSaleModel venta) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('FASHION STYLE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _colorRosa)),
              pw.Text('Comprobante de Caja Mostrador (POS)', style: const pw.TextStyle(fontSize: 8, color: _colorTextoMuted)),
              pw.Text('NIT: 901.842.109-4', style: const pw.TextStyle(fontSize: 8, color: _colorTextoMuted)),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Venta N°: ${venta.codigo}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(venta.fecha ?? '', style: const pw.TextStyle(fontSize: 8, color: _colorTextoMuted)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cliente: ${venta.clienteNombre.isNotEmpty ? venta.clienteNombre : 'Consumidor'}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Medio: ${venta.medioPago.toUpperCase()}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              // DETALLES TICKETERA
              ...venta.detalles.map(
                (d) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${d.nombre} (${d.talla}) x${d.cantidad}', style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Text(CurrencyFormatter.formatearCOP(d.subtotal), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SUBTOTAL:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(CurrencyFormatter.formatearCOP(venta.facturaSubtotal > 0 ? venta.facturaSubtotal : venta.total), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (venta.facturaImpuesto > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('IVA INCLUIDO:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(CurrencyFormatter.formatearCOP(venta.facturaImpuesto), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL PAGADO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(CurrencyFormatter.formatearCOP(venta.total), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _colorRosa)),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Text('¡Gracias por tu compra!', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('Prendas con cambio dentro de los 30 días con este recibo.', style: const pw.TextStyle(fontSize: 7, color: _colorTextoMuted), textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'POS_${venta.codigo}.pdf',
    );
  }

  static pw.Widget _celdaHeader(String texto, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        texto,
        textAlign: align,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _colorPrimario),
      ),
    );
  }

  static pw.Widget _celda(String texto, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        texto,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static pw.Widget _filaTotales(String etiqueta, String valor, {bool esTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            etiqueta,
            style: pw.TextStyle(
              fontSize: esTotal ? 11 : 9,
              fontWeight: esTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: esTotal ? _colorRosa : _colorTextoMuted,
            ),
          ),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: esTotal ? 12 : 9,
              fontWeight: pw.FontWeight.bold,
              color: esTotal ? _colorRosa : _colorPrimario,
            ),
          ),
        ],
      ),
    );
  }
}
