import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Document buildReceiptDocument({
  required String receiptNumber,
  required DateTime date,
  required List<Map<String, dynamic>> items,
  required int total,
  required double paid,
  required double change,
  required String paymentMethod,
}) {
  final pdf = pw.Document();

  String formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  String formatTime(DateTime dt) {
    int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'BYTE & BITE',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Smart POS Solution',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Visayan Village, Tagum City',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Date: ${formatDate(date)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Time: ${formatTime(date)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Receipt #: $receiptNumber',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Payment: $paymentMethod',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 8),
            // Items
            ...items.map((item) {
              final name = item['name']?.toString() ?? '';
              final price = item['price']?.toString() ?? '0';
              final qty = item['quantity']?.toString() ?? '1';
              final subtotal = item['total']?.toString() ?? '0';
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(name, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        'P$price.00',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'x$qty',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'P$subtotal.00',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                ],
              );
            }),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'P$total.00',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Amount Paid:',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'P${paid.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Change:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  'P${change.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Text(
              'System‑generated sales slip. Official BIR receipt issued separately.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 16),
          ],
        );
      },
    ),
  );

  return pdf;
}
