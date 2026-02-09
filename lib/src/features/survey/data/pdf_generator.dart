import 'dart:io';
import 'dart:typed_data';
import 'package:field_pro/src/features/survey/domain/survey_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  // Safety Helpers
  String _safeStr(String? value) => value ?? "-";

  String _safeDate(DateTime? date) {
    if (date == null) return "No Date";
    return date.toString().split(' ')[0];
  }

  Future<Uint8List> generateSurveyReport(
    SurveyModel survey,
    List<String> photoPaths,
    Uint8List? signature,
  ) async {
    final pdf = pw.Document();

    // 1. Process Photos
    final List<pw.Widget> photoWidgets = [];
    for (var path in photoPaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          final image = pw.MemoryImage(file.readAsBytesSync());
          photoWidgets.add(
            pw.Container(
              width: 100,
              height: 100,
              margin: const pw.EdgeInsets.only(right: 10, bottom: 10),
              child: pw.Image(image, fit: pw.BoxFit.cover),
            ),
          );
        }
      } catch (e) {
        print("Error loading photo: $e");
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Novo Field Survey Report",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "ID: ${survey.id.length > 6 ? survey.id.substring(0, 6) : survey.id}",
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // DETAILS
            pw.Text(
              "Customer Details",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            _buildSafeRow("Name", survey.customerName),
            _buildSafeRow("Address", survey.address),
            _buildSafeRow("Date", _safeDate(survey.dateCreated)),

            pw.SizedBox(height: 20),

            // TECH DATA
            pw.Text(
              "Technical Data",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            _buildSafeRow("Roof Pitch", survey.roofPitch),
            _buildSafeRow("Main Breaker", "${survey.mainBreakerAmps} A"),
            _buildSafeRow("Panel Location", _safeStr(survey.panelLocation)),

            pw.SizedBox(height: 20),

            // PHOTOS
            pw.Text(
              "Photos (${photoWidgets.length})",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            if (photoWidgets.isEmpty)
              pw.Text(
                "(No photos)",
                style: const pw.TextStyle(color: PdfColors.grey),
              )
            else
              pw.Wrap(children: photoWidgets),

            // --- SIGNATURE SECTION ---
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.black),
            pw.SizedBox(height: 10),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // --- 1. TECHNICIAN SIGNATURE (Added) ---
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Technician",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 10),
                    // This text acts as a "Digital Signature"
                    pw.Text(
                      "Novo Technician",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontStyle: pw.FontStyle.italic,
                        font: pw.Font.courier(),
                      ),
                    ),
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                    pw.Text(
                      "Authorized Signature",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),

                // --- 2. CUSTOMER SIGNATURE ---
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (signature != null)
                      pw.Container(
                        width: 100,
                        height: 40,
                        child: pw.Image(pw.MemoryImage(signature)),
                      )
                    else
                      pw.Container(height: 40),

                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                    pw.Text(
                      "Customer Signature",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSafeRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value ?? "-"),
        ],
      ),
    );
  }
}
