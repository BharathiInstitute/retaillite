/// Tests for ReceiptService.generateReceipt — PDF generation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:retaillite/core/services/receipt_service.dart';
import 'package:retaillite/models/bill_model.dart';

// These tests call generateReceipt and save() the pdf to check the output
// is a valid PDF. PrinterStorage calls inside ReceiptService need
// SharedPreferences initialised, so we do that in setUpAll.
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late BillModel cashBill;
  late BillModel udharBill;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({
      'printer_paper_size': 1, // 80mm
      'printer_font_size': 1,
      'printer_custom_width': 0,
    });
  });

  setUp(() {
    cashBill = BillModel(
      id: 'r1',
      billNumber: 101,
      items: [
        const CartItem(
          productId: 'p1',
          name: 'Atta 10kg',
          price: 350,
          quantity: 1,
          unit: 'kg',
        ),
        const CartItem(
          productId: 'p2',
          name: 'Sugar 5kg',
          price: 210,
          quantity: 2,
          unit: 'kg',
        ),
      ],
      total: 770,
      paymentMethod: PaymentMethod.cash,
      receivedAmount: 800,
      createdAt: DateTime(2026, 4, 1, 10),
      date: '2026-04-01',
    );

    udharBill = BillModel(
      id: 'r2',
      billNumber: 102,
      items: [
        const CartItem(
          productId: 'p3',
          name: 'Milk 1L',
          price: 60,
          quantity: 3,
          unit: 'liter',
        ),
      ],
      total: 180,
      paymentMethod: PaymentMethod.udhar,
      customerName: 'Suresh Patel',
      createdAt: DateTime(2026, 4, 1, 11),
      date: '2026-04-01',
    );
  });

  group('ReceiptService.generateReceipt — 80mm paper', () {
    test('returns a document that saves to valid PDF bytes', () async {
      final doc = await ReceiptService.generateReceipt(
        bill: cashBill,
        paperSizeIndex: 1,
      );
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('with all shop details', () async {
      final doc = await ReceiptService.generateReceipt(
        bill: cashBill,
        shopName: 'Dev Store',
        shopAddress: '45 MG Road',
        shopPhone: '9876543210',
        gstNumber: '29AABCU9603R1ZM',
        receiptFooter: 'Visit Again!',
        paperSizeIndex: 1,
      );
      final bytes = await doc.save();
      expect(bytes.length, greaterThan(200));
    });

    test('with udhar bill (customer + credit)', () async {
      final doc = await ReceiptService.generateReceipt(
        bill: udharBill,
        paperSizeIndex: 1,
      );
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });
  });

  group('ReceiptService.generateReceipt — 58mm paper', () {
    test('produces valid PDF for 58mm paper', () async {
      final doc = await ReceiptService.generateReceipt(
        bill: cashBill,
        paperSizeIndex: 0,
      );
      final bytes = await doc.save();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });

  group('ReceiptService.generateReceipt — edge cases', () {
    test('empty items list does not crash', () async {
      final emptyBill = BillModel(
        id: 'e1',
        billNumber: 999,
        items: const [],
        total: 0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final doc = await ReceiptService.generateReceipt(
        bill: emptyBill,
        paperSizeIndex: 1,
      );
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });

    test('many items (30) does not crash', () async {
      final items = List.generate(
        30,
        (i) => CartItem(
          productId: 'p$i',
          name: 'Product $i Name',
          price: (i + 1) * 10,
          quantity: i + 1,
          unit: 'piece',
        ),
      );
      final bigBill = BillModel(
        id: 'big',
        billNumber: 500,
        items: items,
        total: items.fold(0.0, (s, i) => s + i.total),
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 100000,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final doc = await ReceiptService.generateReceipt(
        bill: bigBill,
        paperSizeIndex: 1,
      );
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });

    test('UPI payment receipt', () async {
      final upi = BillModel(
        id: 'upi1',
        billNumber: 300,
        items: [
          const CartItem(
            productId: 'u1',
            name: 'Chips',
            price: 20,
            quantity: 2,
            unit: 'piece',
          ),
        ],
        total: 40,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2026, 6, 15, 17, 30),
        date: '2026-06-15',
      );
      final doc = await ReceiptService.generateReceipt(
        bill: upi,
        paperSizeIndex: 1,
      );
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });
  });

  group('ReceiptService — page format helper', () {
    test('roll57 width is around 58mm', () {
      // PdfPageFormat.roll57 width is ~162 points ≈ 57mm
      expect(PdfPageFormat.roll57.width, closeTo(162, 3));
    });

    test('roll80 width is around 80mm', () {
      // PdfPageFormat.roll80 width is 226 (points ≈ ~80mm)
      expect(PdfPageFormat.roll80.width, closeTo(226, 2));
    });
  });
}
