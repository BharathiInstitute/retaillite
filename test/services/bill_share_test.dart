import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/services/bill_share_service.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  // ── generateBillText ──

  group('BillShareService.generateBillText', () {
    late BillModel bill;

    setUp(() {
      bill = BillModel(
        id: 'bill_1',
        billNumber: 42,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Rice',
            price: 50,
            quantity: 2,
            unit: 'kg',
          ),
          const CartItem(
            productId: 'p2',
            name: 'Dal',
            price: 120,
            quantity: 1,
            unit: 'kg',
          ),
        ],
        total: 220,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026, 2, 25, 14, 30),
        date: '2026-02-25',
      );
    });

    test('includes bill number', () {
      final text = BillShareService.generateBillText(bill);
      expect(text, contains('42'));
    });

    test('includes item names', () {
      final text = BillShareService.generateBillText(bill);
      expect(text, contains('Rice'));
      expect(text, contains('Dal'));
    });

    test('includes total amount', () {
      final text = BillShareService.generateBillText(bill);
      expect(text, contains('220'));
    });

    test('returns non-empty string', () {
      final text = BillShareService.generateBillText(bill);
      expect(text, isNotEmpty);
    });

    test('includes date', () {
      final text = BillShareService.generateBillText(bill);
      expect(text, contains('2026'));
    });

    test('includes quantities', () {
      final text = BillShareService.generateBillText(bill);
      expect(text, contains('2'));
    });

    test('handles single item bill', () {
      final singleItemBill = BillModel(
        id: 'bill_2',
        billNumber: 1,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Salt',
            price: 28,
            quantity: 1,
            unit: 'piece',
          ),
        ],
        total: 28,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2026, 1),
        date: '2026-01-01',
      );
      final text = BillShareService.generateBillText(singleItemBill);
      expect(text, contains('Salt'));
      expect(text, contains('28'));
    });

    test('handles customer name when present', () {
      final udharBill = BillModel(
        id: 'bill_3',
        billNumber: 10,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Oil',
            price: 150,
            quantity: 1,
            unit: 'liter',
          ),
        ],
        total: 150,
        paymentMethod: PaymentMethod.udhar,
        customerName: 'Rajesh Kumar',
        customerId: 'c1',
        createdAt: DateTime(2026, 2, 20),
        date: '2026-02-20',
      );
      final text = BillShareService.generateBillText(udharBill);
      expect(text, isNotEmpty);
    });
  });
}
