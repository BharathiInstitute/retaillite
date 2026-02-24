/// Receipt PDF generator for thermal printers
library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:intl/intl.dart';

/// Service for generating and printing receipts
class ReceiptService {
  ReceiptService._();

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('hh:mm a');

  /// Get PdfPageFormat from paper size index
  static PdfPageFormat _getPageFormat(int paperSizeIndex) {
    switch (paperSizeIndex) {
      case 0:
        return PdfPageFormat.roll57; // 58mm
      case 1:
      default:
        return PdfPageFormat.roll80; // 80mm
    }
  }

  /// Generate receipt PDF
  static Future<pw.Document> generateReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
    int? paperSizeIndex,
  }) async {
    final pdf = pw.Document();
    final effectivePaperSize =
        paperSizeIndex ?? PrinterStorage.getSavedPaperSize();
    final pageFormat = _getPageFormat(effectivePaperSize);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => _buildReceipt(
          bill: bill,
          shopName: shopName ?? 'Tulasi Stores',
          shopAddress: shopAddress,
          shopPhone: shopPhone,
          gstNumber: gstNumber,
          receiptFooter: receiptFooter ?? 'Thank you for shopping!',
        ),
      ),
    );

    return pdf;
  }

  /// Print receipt directly
  static Future<bool> printReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
    int? paperSizeIndex,
  }) async {
    final effectivePaperSize =
        paperSizeIndex ?? PrinterStorage.getSavedPaperSize();
    final pdf = await generateReceipt(
      bill: bill,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      gstNumber: gstNumber,
      receiptFooter: receiptFooter,
      paperSizeIndex: effectivePaperSize,
    );

    return await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Bill_${bill.billNumber}',
      format: _getPageFormat(effectivePaperSize),
    );
  }

  /// Share receipt as PDF
  static Future<void> shareReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
    int? paperSizeIndex,
  }) async {
    final pdf = await generateReceipt(
      bill: bill,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      gstNumber: gstNumber,
      receiptFooter: receiptFooter,
      paperSizeIndex: paperSizeIndex,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Bill_${bill.billNumber}_${bill.date}.pdf',
    );
  }

  static pw.Widget _buildReceipt({
    required BillModel bill,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    required String receiptFooter,
  }) {
    final createdAt = bill.createdAt;

    return pw.Column(
      children: [
        // Shop header
        pw.Text(
          shopName,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        if (shopAddress != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 8)),
        ],
        if (shopPhone != null) ...[
          pw.SizedBox(height: 2),
          pw.Text('Ph: $shopPhone', style: const pw.TextStyle(fontSize: 8)),
        ],
        if (gstNumber != null) ...[
          pw.SizedBox(height: 2),
          pw.Text('GSTIN: $gstNumber', style: const pw.TextStyle(fontSize: 8)),
        ],

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),

        // Bill info
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Bill #${bill.billNumber}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              _dateFormat.format(createdAt),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              bill.paymentMethod.displayName,
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              _timeFormat.format(createdAt),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),

        if (bill.customerName != null) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text('Customer: ', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                bill.customerName!,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),

        // Items header
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'Item',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                'Qty',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Amt',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.3),

        // Items list
        ...bill.items.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.name,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '@ ₹${item.price.toStringAsFixed(0)}',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    item.quantity.toString(),
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '₹${item.total.toStringAsFixed(0)}',
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5),

        // Total section
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Items:', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              '${bill.items.length}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '₹${bill.total.toStringAsFixed(0)}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),

        // Cash payment details
        if (bill.paymentMethod == PaymentMethod.cash &&
            bill.receivedAmount != null) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Received:', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                '₹${bill.receivedAmount!.toStringAsFixed(0)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          if ((bill.changeAmount ?? 0) > 0)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Change:', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  '₹${bill.changeAmount!.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
        ],

        // Udhar note
        if (bill.paymentMethod == PaymentMethod.udhar) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Text(
              '*** UDHAR - Payment Pending ***',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],

        pw.SizedBox(height: 12),
        pw.Divider(thickness: 0.3),

        // Footer
        pw.SizedBox(height: 4),
        pw.Text(
          receiptFooter,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('धन्यवाद! फिर आइए।', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Powered by Tulasi Stores',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 20), // Space for tear
      ],
    );
  }
}
