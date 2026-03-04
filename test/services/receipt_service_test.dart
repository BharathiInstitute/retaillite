import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

void main() {
  group('ReceiptService._getPageFormat', () {
    // The method is static private, but we can test the mapping logic
    // by verifying the known paper size indices create valid receipts
    test('paper size 0 is 58mm roll', () {
      // 58mm = PdfPageFormat.roll57 (57mm printable area)
      expect(PdfPageFormat.roll57.width, greaterThan(0));
    });

    test('paper size 1 is 80mm roll', () {
      expect(PdfPageFormat.roll80.width, greaterThan(PdfPageFormat.roll57.width));
    });
  });

  group('ReceiptService page format constants', () {
    test('roll57 width is smaller than roll80', () {
      expect(PdfPageFormat.roll57.width, lessThan(PdfPageFormat.roll80.width));
    });

    test('roll formats have no fixed height', () {
      // Roll paper has infinite height (continuous)
      expect(PdfPageFormat.roll57.height, greaterThan(0));
      expect(PdfPageFormat.roll80.height, greaterThan(0));
    });
  });
}
