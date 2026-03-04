/// Integration test: Full billing flow
///
/// Tests the end-to-end flow: product creation → cart → bill creation → summary.
/// Uses pure model logic (no Firebase) to verify data integrity at each step.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/sales_summary_model.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import '../helpers/test_factories.dart';

void main() {
  group('Integration: Full Billing Flow', () {
    late List<ProductModel> products;
    late List<BillModel> createdBills;
    late CustomerModel customer;
    late UserLimits limits;

    setUp(() {
      products = List.generate(
        5,
        (i) => makeProduct(
          id: 'prod-$i',
          name: 'Product ${i + 1}',
          price: 100.0 + (i * 50),
          purchasePrice: 60.0 + (i * 30),
          stock: 100,
          lowStockAlert: 10,
        ),
      );
      createdBills = [];
      customer = makeCustomer(name: 'Rajesh Kumar');
      limits = const UserLimits(
        productsCount: 5,
        customersCount: 1,
      );
    });

    test('Step 1: Products are valid', () {
      for (final p in products) {
        expect(p.isOutOfStock, false);
        expect(p.profit, isNotNull);
        expect(p.profit!, greaterThan(0));
      }
    });

    test('Step 2: Cart items compute totals correctly', () {
      final cartItems = [
        CartItem(
          productId: products[0].id,
          name: products[0].name,
          price: products[0].price,
          quantity: 3,
          unit: 'pcs',
        ),
        CartItem(
          productId: products[1].id,
          name: products[1].name,
          price: products[1].price,
          quantity: 2,
          unit: 'pcs',
        ),
      ];

      final total = cartItems.fold<double>(0, (sum, item) => sum + item.total);
      expect(total, (100.0 * 3) + (150.0 * 2)); // 300 + 300 = 600
    });

    test('Step 3: Bill creation within subscription limits', () {
      expect(limits.isAtLimit, false);

      final bill = makeBill(
        total: 600,
        receivedAmount: 700,
        items: [
          CartItem(
            productId: products[0].id,
            name: products[0].name,
            price: products[0].price,
            quantity: 3,
            unit: 'pcs',
          ),
          CartItem(
            productId: products[1].id,
            name: products[1].name,
            price: products[1].price,
            quantity: 2,
            unit: 'pcs',
          ),
        ],
      );

      createdBills.add(bill);

      expect(bill.total, 600);
      expect(bill.changeAmount, 100); // 700 - 600
      expect(bill.itemCount, 5); // 3 + 2
    });

    test('Step 4: Stock decrements correctly', () {
      // Simulate stock decrement after billing
      final updated0 = products[0].copyWith(stock: products[0].stock - 3);
      final updated1 = products[1].copyWith(stock: products[1].stock - 2);

      expect(updated0.stock, 97);
      expect(updated1.stock, 98);
      expect(updated0.isLowStock, false);
      expect(updated0.isOutOfStock, false);
    });

    test('Step 5: Udhar bill updates customer balance', () {
      final udharBill = makeBill(
        id: 'bill-2',
        billNumber: 2,
        total: 500,
        paymentMethod: PaymentMethod.udhar,
        customerId: customer.id,
        customerName: customer.name,
      );

      createdBills.add(udharBill);

      // Update customer balance
      final updatedCustomer = customer.copyWith(
        balance: customer.balance + udharBill.total,
        lastTransactionAt: DateTime.now(),
      );

      expect(updatedCustomer.balance, 500);
      expect(updatedCustomer.hasDue, true);
      expect(updatedCustomer.isOverdue, false); // Just created
    });

    test('Step 6: Payment records reduce customer balance', () {
      final customerWithDebt = customer.copyWith(balance: 500);
      final afterPayment = customerWithDebt.copyWith(
        balance: customerWithDebt.balance - 200,
        lastTransactionAt: DateTime.now(),
      );

      expect(afterPayment.balance, 300);
      expect(afterPayment.hasDue, true);
    });

    test('Step 7: Daily summary aggregates correctly', () {
      final bills = [
        makeBill(id: 'b1', total: 300),
        makeBill(id: 'b2', total: 500, paymentMethod: PaymentMethod.upi),
        makeBill(id: 'b3', total: 200, paymentMethod: PaymentMethod.udhar),
      ];

      final totalSales = bills.fold<double>(0, (s, b) => s + b.total);
      final cashAmount = bills
          .where((b) => b.paymentMethod == PaymentMethod.cash)
          .fold<double>(0, (s, b) => s + b.total);
      final upiAmount = bills
          .where((b) => b.paymentMethod == PaymentMethod.upi)
          .fold<double>(0, (s, b) => s + b.total);
      final udharAmount = bills
          .where((b) => b.paymentMethod == PaymentMethod.udhar)
          .fold<double>(0, (s, b) => s + b.total);

      final summary = SalesSummary(
        totalSales: totalSales,
        billCount: bills.length,
        cashAmount: cashAmount,
        upiAmount: upiAmount,
        udharAmount: udharAmount,
        avgBillValue: totalSales / bills.length,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );

      expect(summary.totalSales, 1000);
      expect(summary.billCount, 3);
      expect(summary.cashPercentage, 30.0);
      expect(summary.upiPercentage, 50.0);
      expect(summary.udharPercentage, 20.0);
    });

    test('Step 8: Subscription limit blocks at boundary', () {
      // Simulate reaching limit
      const atLimit = UserLimits(billsThisMonth: 50);
      expect(atLimit.isAtLimit, true);
      expect(atLimit.usagePercentage, 1.0);

      // Pro upgrade removes block
      const proLimits = UserLimits(billsThisMonth: 50, billsLimit: 500);
      expect(proLimits.isAtLimit, false);
      expect(proLimits.usagePercentage, 0.1);
    });
  });

  group('Integration: Subscription Lifecycle', () {
    test('Free → Pro → Business upgrade path', () {
      // Start as free
      const free = UserSubscription();
      expect(free.billsLimit, 50);
      expect(free.planPrice, 0);
      expect(free.isActive, true);

      // User reaches limit
      const freeLimits = UserLimits(billsThisMonth: 50);
      expect(freeLimits.isAtLimit, true);

      // Upgrade to Pro
      const pro = UserSubscription(
        plan: SubscriptionPlan.pro,
      );
      expect(pro.billsLimit, 500);
      expect(pro.planPrice, 299);
      expect(pro.isActive, true);

      // Pro limits updated
      const proLimits = UserLimits(billsThisMonth: 50, billsLimit: 500);
      expect(proLimits.isAtLimit, false);
      expect(proLimits.isNearLimit, false);

      // Upgrade to Business
      const biz = UserSubscription(
        plan: SubscriptionPlan.business,
      );
      expect(biz.billsLimit, 999999);
      expect(biz.planPrice, 999);
    });

    test('Subscription expiry → renewal flow', () {
      // Active trial
      const trial = UserSubscription(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.trial,
      );
      expect(trial.isActive, true);

      // Trial expires
      const expired = UserSubscription(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.expired,
      );
      expect(expired.isActive, false);
      // Bills limit still reflects plan (for display), but isActive blocks new bills
      expect(expired.billsLimit, 500);

      // Renewed
      const renewed = UserSubscription(
        plan: SubscriptionPlan.pro,
      );
      expect(renewed.isActive, true);
    });

    test('Cancelled subscription is not active', () {
      const cancelled = UserSubscription(
        plan: SubscriptionPlan.business,
        status: SubscriptionStatus.cancelled,
      );
      expect(cancelled.isActive, false);
    });
  });

  group('Integration: Multi-item Cart to Bill', () {
    test('Large cart with 50 items computes correctly', () {
      final items = List.generate(
        50,
        (i) => CartItem(
          productId: 'p-$i',
          name: 'Item $i',
          price: 10.0 + i,
          quantity: i + 1,
          unit: 'pcs',
        ),
      );

      final total = items.fold<double>(0, (sum, item) => sum + item.total);
      final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);

      final bill = BillModel(
        id: 'big-bill',
        billNumber: 1,
        items: items,
        total: total,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: total,
        createdAt: DateTime.now(),
        date: '2024-03-01',
      );

      expect(bill.itemCount, itemCount);
      expect(bill.changeAmount, 0);
      expect(bill.total, total);
      expect(bill.items.length, 50);
    });
  });

  group('Integration: Report Period Navigation', () {
    test('Navigate through week periods consistently', () {
      final thisWeek = ReportPeriod.week.getDateRange();
      final lastWeek = ReportPeriod.week.getDateRange(offset: -1);
      final nextWeek = ReportPeriod.week.getDateRange(offset: 1);

      // Each week starts on Monday
      expect(thisWeek.start.weekday, DateTime.monday);
      expect(lastWeek.start.weekday, DateTime.monday);
      expect(nextWeek.start.weekday, DateTime.monday);

      // Weeks are 7 days apart
      expect(thisWeek.start.difference(lastWeek.start).inDays, 7);
      expect(nextWeek.start.difference(thisWeek.start).inDays, 7);
    });

    test('Navigate through month periods consistently', () {
      for (int i = -6; i <= 6; i++) {
        final range = ReportPeriod.month.getDateRange(offset: i);
        expect(range.start.day, 1, reason: 'offset=$i should start on day 1');
        expect(range.end.hour, 23, reason: 'offset=$i should end at 23:59');
      }
    });
  });

  group('Integration: AppConstants consistency with UserSubscription', () {
    test('Free tier limits match AppConstants', () {
      const sub = UserSubscription();
      expect(sub.billsLimit, AppConstants.freeMaxBillsPerMonth);
    });

    test('Pro tier limits match AppConstants', () {
      const sub = UserSubscription(plan: SubscriptionPlan.pro);
      expect(sub.billsLimit, AppConstants.proMaxBillsPerMonth);
    });

    test('Business tier limits match AppConstants', () {
      const sub = UserSubscription(plan: SubscriptionPlan.business);
      expect(sub.billsLimit, AppConstants.businessMaxBillsPerMonth);
    });
  });
}
