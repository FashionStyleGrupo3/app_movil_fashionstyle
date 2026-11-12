import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';

/// Modal y generador para exportar datos del panel administrativo a documentos reales (PDF / Excel-CSV).
class AdminExportDialog {
  static Future<void> mostrarDialogoExportacion(
    BuildContext context, {
    required String titulo,
    required List<String> encabezados,
    required List<List<dynamic>> filas,
    required String nombreArchivo,
  }) async {
    if (filas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros disponibles para exportar')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: FashionColors.backgroundCanvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'Exportar Reporte',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.textoPrincipal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$titulo (${filas.length} registros)',
                style: GoogleFonts.poppins(fontSize: 12.5, color: FashionColors.textoMuted),
              ),
              const SizedBox(height: 20),

              // Opción PDF
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: FashionColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FashionColors.bordeClaro),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FashionColors.peligro.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined, color: FashionColors.peligro, size: 24),
                  ),
                  title: Text(
                    'Exportar en PDF',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Genera un documento PDF tabulado con membrete oficial listo para imprimir o compartir',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: FashionColors.textoMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _generarYCompartirPdf(
                      context,
                      titulo: titulo,
                      encabezados: encabezados,
                      filas: filas,
                      nombreArchivo: nombreArchivo,
                    );
                  },
                ),
              ),

              // Opción Excel / CSV
              Container(
                decoration: BoxDecoration(
                  color: FashionColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FashionColors.bordeClaro),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FashionColors.verdeExito.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.table_view_outlined, color: FashionColors.verdeExito, size: 24),
                  ),
                  title: Text(
                    'Exportar en Excel (.csv / .xlsx)',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Guarda un archivo de hoja de cálculo compatible con Excel y Google Sheets',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: FashionColors.textoMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _generarYCompartirExcel(
                      context,
                      titulo: titulo,
                      encabezados: encabezados,
                      filas: filas,
                      nombreArchivo: nombreArchivo,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _generarYCompartirPdf(
    BuildContext context, {
    required String titulo,
    required List<String> encabezados,
    required List<List<dynamic>> filas,
    required String nombreArchivo,
  }) async {
    try {
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FASHIONSTYLE - REPORTE ADMINISTRATIVO',
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(titulo, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Fecha: ${DateTime.now().toLocal().toString().split('.')[0]}',
                            style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Total registros: ${filas.length}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: encabezados,
                data: filas.map((r) => r.map((c) => c?.toString() ?? '').toList()).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF111111)),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await doc.save();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$nombreArchivo.pdf');
      await file.writeAsBytes(pdfBytes);

      await Printing.layoutPdf(
        name: '$nombreArchivo.pdf',
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    }
  }

  static Future<void> _generarYCompartirExcel(
    BuildContext context, {
    required String titulo,
    required List<String> encabezados,
    required List<List<dynamic>> filas,
    required String nombreArchivo,
  }) async {
    try {
      final buffer = StringBuffer('\uFEFF');

      String escapar(dynamic v) {
        if (v == null) return '';
        final s = v.toString();
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }

      buffer.writeln(encabezados.map(escapar).join(','));

      for (final fila in filas) {
        buffer.writeln(fila.map(escapar).join(','));
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$nombreArchivo.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Reporte: $titulo - FashionStyle',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar archivo: $e'),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    }
  }
}
