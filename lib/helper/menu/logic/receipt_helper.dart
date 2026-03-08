import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Receipt formatting and PDF generation helper
class ReceiptHelper {
  /// Format date to readable format (e.g., "Jan 08, 2026")
  static String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  /// Format time to readable format (e.g., "02:30 PM")
  static String formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  /// Generate PDF receipt and print
  static Future<void> generateAndPrintReceipt({
    required List<Map<String, dynamic>> cartItems,
    required int total,
    required double paid,
    required double change,
    required String receiptNumber,
    required String paymentMethod,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('BYTE & BITE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Smart POS Solution', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Visayan Village, Tagum City', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 12),
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: ${formatDate(date)}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Time: ${formatTime(date)}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Receipt #: $receiptNumber', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Payment: $paymentMethod', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              // Items
              ...cartItems.map((item) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(item['name'].toString(), style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('P${item['price']}.00', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('x${item['quantity']}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                      pw.Text('P${item['price'] * item['quantity']}.00', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                ],
              )),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('P$total.00', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Paid:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('P${paid.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('P${change.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 12),
              pw.Text('Thank you for your purchase!', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Come again soon!', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
