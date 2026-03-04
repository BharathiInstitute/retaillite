/// Bill sharing service — generates formatted text and PDF for sharing bills
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for sharing bills via WhatsApp, SMS, PDF download, and general share
class BillShareService {
  /// Default shop name used when no name is provided
  static const String _defaultShopName = AppConstants.defaultShopName;

  // ==================== Text Generation ====================

  /// Generate formatted bill text for SMS / general share
  static String generateBillText(BillModel bill, {String? shopName}) {
    final name = shopName ?? _defaultShopName;
    final buffer = StringBuffer();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(bill.createdAt);

    buffer.writeln('🧾 *$name*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Bill #INV-${bill.billNumber}');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('Customer: ${bill.customerName ?? 'Walk-in'}');
    buffer.writeln();

    // Items
    for (final item in bill.items) {
      final itemTotal = Formatters.currency(item.price * item.quantity);
      buffer.writeln('📦 ${item.name} × ${item.quantity}  $itemTotal');
    }

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *Total: ${Formatters.currency(bill.total)}*');
    buffer.writeln(
      '${bill.paymentMethod.emoji} Paid: ${bill.paymentMethod.displayName}',
    );

    if (bill.receivedAmount != null && bill.changeAmount != null) {
      buffer.writeln('Received: ${Formatters.currency(bill.receivedAmount!)}');
      buffer.writeln('Change: ${Formatters.currency(bill.changeAmount!)}');
    }

    buffer.writeln();
    buffer.writeln('Thank you for your purchase! 🙏');

    return buffer.toString();
  }

  // ==================== PDF Generation ====================

  /// Generate a PDF invoice for the bill
  static Future<Uint8List> generateBillPdf(
    BillModel bill, {
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
  }) async {
    final name = shopName ?? _defaultShopName;
    final doc = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(bill.createdAt);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (shopAddress != null && shopAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    shopAddress,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'Ph: $shopPhone',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              if (gstNumber != null && gstNumber.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'GSTIN: $gstNumber',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Bill info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Bill #INV-${bill.billNumber}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Customer: ${bill.customerName ?? 'Walk-in'}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 12),

              // Items table header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 8,
                ),
                color: PdfColors.grey200,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'Item',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'Qty',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Price',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Items
              ...bill.items.map(
                (item) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          item.name,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${item.quantity}',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          Formatters.currency(item.price),
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          Formatters.currency(item.total),
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(),

              // Total
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      Formatters.currency(bill.total),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                child: pw.Text(
                  'Payment: ${bill.paymentMethod.displayName}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),

              if (bill.receivedAmount != null) ...[
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    'Received: ${Formatters.currency(bill.receivedAmount!)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                if (bill.changeAmount != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                    child: pw.Text(
                      'Change: ${Formatters.currency(bill.changeAmount!)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
              ],

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Center(
                child: pw.Text(
                  'Thank you for your purchase!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Generated by $name',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ==================== Share Methods ====================

  /// Share bill PDF via WhatsApp to a specific phone number
  static Future<void> shareViaWhatsApp(
    BillModel bill,
    String phone, {
    required BuildContext context,
  }) async {
    try {
      final pdfBytes = await generateBillPdf(bill);
      final fileName = 'Invoice_${bill.billNumber}.pdf';

      // Share the PDF file — WhatsApp will be one of the sharing options
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf')],
        text:
            'Invoice #INV-${bill.billNumber} - ${Formatters.currency(bill.total)}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share a pre-filled bill summary directly to a WhatsApp number.
  ///
  /// Opens WhatsApp (or web.whatsapp.com) with a ready-to-send message.
  /// [customerPhone] should be a 10-digit Indian mobile number.
  static Future<void> shareDirectToWhatsApp({
    required BillModel bill,
    required String customerPhone,
    String shopDisplayName = _defaultShopName,
    required BuildContext context,
  }) async {
    try {
      final digits = customerPhone.replaceAll(RegExp(r'[^\d]'), '');
      // Accept 10-digit (add +91) or already-normalised 12-digit numbers
      final normalised = digits.length == 10 ? '91$digits' : digits;

      final dateStr = DateFormat('d MMM yyyy').format(bill.createdAt);
      final msg =
          '🧾 *$shopDisplayName*\n'
          'Bill #INV-${bill.billNumber}\n'
          '📅 $dateStr\n\n'
          '${bill.items.map((i) => '• ${i.name} x${i.quantity} = ₹${(i.price * i.quantity).toStringAsFixed(0)}').join('\n')}\n\n'
          '━━━━━━━━━━\n'
          '💰 *Total: ₹${bill.total.toStringAsFixed(2)}*\n\n'
          'Thank you for your purchase! 🙏';

      final uri = Uri.parse(
        'https://wa.me/$normalised?text=${Uri.encodeComponent(msg)}',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to system share sheet
        await Share.share(msg);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing via WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share bill text via SMS to a specific phone number
  static Future<void> shareViaSms(
    BillModel bill,
    String phone, {
    required BuildContext context,
  }) async {
    try {
      final text = generateBillText(bill);
      final encoded = Uri.encodeComponent(text);
      final uri = Uri.parse('sms:$phone?body=$encoded');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: general share
        await Share.share(text);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Download/print PDF
  static Future<void> downloadPdf(
    BillModel bill, {
    required BuildContext context,
  }) async {
    try {
      final pdfBytes = await generateBillPdf(bill);
      await Printing.layoutPdf(
        onLayout: (_) => Future.value(pdfBytes),
        name: 'Invoice_${bill.billNumber}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// General share (system share sheet) with PDF
  static Future<void> shareGeneral(
    BillModel bill, {
    required BuildContext context,
  }) async {
    try {
      final pdfBytes = await generateBillPdf(bill);
      final fileName = 'Invoice_${bill.billNumber}.pdf';

      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf')],
        text:
            'Invoice #INV-${bill.billNumber} - ${Formatters.currency(bill.total)}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
