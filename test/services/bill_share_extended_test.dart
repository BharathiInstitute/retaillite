/// Extended tests for BillShareService — text generation, PDF generation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/services/bill_share_service.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  late BillModel cashBill;
  late BillModel udharBill;
  late BillModel upiBill;

  setUp(() {
    cashBill = BillModel(
      id: 'bill_001',
      billNumber: 42,
      items: [
        const CartItem(
          productId: 'p1',
          name: 'Basmati Rice 5kg',
          price: 450,
          quantity: 2,
          unit: 'kg',
        ),
        const CartItem(
          productId: 'p2',
          name: 'Tata Salt 1kg',
          price: 28,
          quantity: 3,
          unit: 'piece',
        ),
      ],
      total: 984,
      paymentMethod: PaymentMethod.cash,
      receivedAmount: 1000,
      createdAt: DateTime(2026, 3, 24, 14, 30),
      date: '2026-03-24',
    );

    udharBill = BillModel(
      id: 'bill_002',
      billNumber: 43,
      items: [
        const CartItem(
          productId: 'p3',
          name: 'Cooking Oil 1L',
          price: 150,
          quantity: 1,
          unit: 'liter',
        ),
      ],
      total: 150,
      paymentMethod: PaymentMethod.udhar,
      customerId: 'c1',
      customerName: 'Rajesh Kumar',
      createdAt: DateTime(2026, 3, 24, 15),
      date: '2026-03-24',
    );

    upiBill = BillModel(
      id: 'bill_003',
      billNumber: 44,
      items: [
        const CartItem(
          productId: 'p4',
          name: 'Maggi Noodles',
          price: 14,
          quantity: 5,
          unit: 'piece',
        ),
      ],
      total: 70,
      paymentMethod: PaymentMethod.upi,
      createdAt: DateTime(2026, 3, 24, 16),
      date: '2026-03-24',
    );
  });

  // ─────────────────────────────────────────────────────
  // generateBillText — Content Validation
  // ─────────────────────────────────────────────────────
  group('BillShareService.generateBillText — content', () {
    test('includes shop name', () {
      final text = BillShareService.generateBillText(
        cashBill,
        shopName: 'Tulasi Stores',
      );
      expect(text, contains('Tulasi Stores'));
    });

    test('uses default shop name when not provided', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('My Shop'));
    });

    test('includes bill number with INV prefix', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('Bill #INV-42'));
    });

    test('includes formatted date', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('24 Mar 2026'));
    });

    test('includes all item names with quantities', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('Basmati Rice 5kg'));
      expect(text, contains('× 2'));
      expect(text, contains('Tata Salt 1kg'));
      expect(text, contains('× 3'));
    });

    test('includes total with currency symbol', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('984'));
    });

    test('includes payment method emoji for cash', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('💵'));
      expect(text, contains('Cash'));
    });

    test('includes payment method emoji for UPI', () {
      final text = BillShareService.generateBillText(upiBill);
      expect(text, contains('📱'));
      expect(text, contains('UPI'));
    });

    test('includes payment method emoji for credit', () {
      final text = BillShareService.generateBillText(udharBill);
      expect(text, contains('💳'));
      expect(text, contains('Credit'));
    });

    test('includes received and change for cash payment', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('Received'));
      expect(text, contains('Change'));
    });

    test('no received/change for UPI', () {
      final text = BillShareService.generateBillText(upiBill);
      expect(text, isNot(contains('Received:')));
      expect(text, isNot(contains('Change:')));
    });

    test('includes customer name for walk-in when no customer', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('Walk-in'));
    });

    test('includes customer name when present', () {
      final text = BillShareService.generateBillText(udharBill);
      expect(text, contains('Rajesh Kumar'));
    });

    test('includes thank you message', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('Thank you'));
    });

    test('includes separator lines', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('━'));
    });

    test('includes product emoji', () {
      final text = BillShareService.generateBillText(cashBill);
      expect(text, contains('📦'));
    });
  });

  // ─────────────────────────────────────────────────────
  // generateBillText — Edge Cases
  // ─────────────────────────────────────────────────────
  group('BillShareService.generateBillText — edge cases', () {
    test('empty items list', () {
      final emptyBill = BillModel(
        id: 'empty',
        billNumber: 99,
        items: const [],
        total: 0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final text = BillShareService.generateBillText(emptyBill);
      expect(text, isNotEmpty);
      expect(text, contains('Bill #INV-99'));
    });

    test('single item bill', () {
      final text = BillShareService.generateBillText(udharBill);
      expect(text, contains('Cooking Oil 1L'));
      expect(text, contains('150'));
    });

    test('special characters in product name', () {
      final specialBill = BillModel(
        id: 'sp',
        billNumber: 50,
        items: [
          const CartItem(
            productId: 'sp1',
            name: 'Rice & Dal "Special"',
            price: 200,
            quantity: 1,
            unit: 'piece',
          ),
        ],
        total: 200,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final text = BillShareService.generateBillText(specialBill);
      expect(text, contains('Rice & Dal'));
    });
  });

  // ─────────────────────────────────────────────────────
  // generateBillPdf — PDF Generation
  // ─────────────────────────────────────────────────────
  group('BillShareService.generateBillPdf', () {
    test('generates non-empty PDF bytes', () async {
      final pdfBytes = await BillShareService.generateBillPdf(cashBill);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });

    test('PDF starts with PDF header bytes', () async {
      final pdfBytes = await BillShareService.generateBillPdf(cashBill);
      // PDF files always start with %PDF
      final header = String.fromCharCodes(pdfBytes.sublist(0, 4));
      expect(header, equals('%PDF'));
    });

    test('generates PDF for single item bill', () async {
      final pdfBytes = await BillShareService.generateBillPdf(udharBill);
      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.sublist(0, 4));
      expect(header, equals('%PDF'));
    });

    test('generates PDF with shop details', () async {
      final pdfBytes = await BillShareService.generateBillPdf(
        cashBill,
        shopName: 'Test Shop',
        shopAddress: '123 Road',
        shopPhone: '9876543210',
        gstNumber: 'GST123',
      );
      expect(pdfBytes, isNotEmpty);
    });

    test('generates PDF for UPI bill', () async {
      final pdfBytes = await BillShareService.generateBillPdf(upiBill);
      expect(pdfBytes, isNotEmpty);
    });

    test('generates PDF for udhar bill', () async {
      final pdfBytes = await BillShareService.generateBillPdf(udharBill);
      expect(pdfBytes, isNotEmpty);
    });

    test('PDF for empty bill does not crash', () async {
      final emptyBill = BillModel(
        id: 'empty',
        billNumber: 1,
        items: const [],
        total: 0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final pdfBytes = await BillShareService.generateBillPdf(emptyBill);
      expect(pdfBytes, isNotEmpty);
    });

    test('PDF for many items does not crash', () async {
      final items = List.generate(
        25,
        (i) => CartItem(
          productId: 'p$i',
          name: 'Product #$i Long Name',
          price: (i + 1) * 10,
          quantity: i + 1,
          unit: 'piece',
        ),
      );
      final bigBill = BillModel(
        id: 'big',
        billNumber: 200,
        items: items,
        total: items.fold(0.0, (s, i) => s + i.total),
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 50000,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final pdfBytes = await BillShareService.generateBillPdf(bigBill);
      expect(pdfBytes, isNotEmpty);
    });
  });
}
