/// Test factories for creating model instances
/// Provides sensible defaults — override only what your test cares about.
library;

import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/models/user_model.dart';
import 'package:retaillite/models/transaction_model.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';

/// Factory for [ProductModel]
ProductModel makeProduct({
  String id = 'prod-1',
  String name = 'Test Product',
  double price = 100.0,
  double? purchasePrice,
  int stock = 50,
  int? lowStockAlert,
  String? barcode,
  String? imageUrl,
  String? category,
  ProductUnit unit = ProductUnit.piece,
  DateTime? createdAt,
}) {
  return ProductModel(
    id: id,
    name: name,
    price: price,
    purchasePrice: purchasePrice,
    stock: stock,
    lowStockAlert: lowStockAlert,
    barcode: barcode,
    imageUrl: imageUrl,
    category: category,
    unit: unit,
    createdAt: createdAt ?? DateTime(2024),
  );
}

/// Factory for [BillModel]
BillModel makeBill({
  String id = 'bill-1',
  int billNumber = 1,
  List<CartItem>? items,
  double total = 100.0,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  String? customerId,
  String? customerName,
  double receivedAmount = 100.0,
  DateTime? createdAt,
  String? date,
}) {
  return BillModel(
    id: id,
    billNumber: billNumber,
    items:
        items ??
        const [
          CartItem(
            productId: 'p1',
            name: 'Rice',
            price: 50.0,
            quantity: 2,
            unit: 'kg',
          ),
        ],
    total: total,
    paymentMethod: paymentMethod,
    customerId: customerId,
    customerName: customerName,
    receivedAmount: receivedAmount,
    createdAt: createdAt ?? DateTime(2024, 1, 15, 10, 30),
    date: date ?? '2024-01-15',
  );
}

/// Factory for [CustomerModel]
CustomerModel makeCustomer({
  String id = 'cust-1',
  String name = 'Rahul Sharma',
  String phone = '9876543210',
  double balance = 0,
  DateTime? lastTransactionAt,
  DateTime? createdAt,
}) {
  return CustomerModel(
    id: id,
    name: name,
    phone: phone,
    balance: balance,
    lastTransactionAt: lastTransactionAt,
    createdAt: createdAt ?? DateTime(2024),
  );
}

/// Factory for [TransactionModel]
TransactionModel makeTransaction({
  String id = 'txn-1',
  String customerId = 'cust-1',
  TransactionType type = TransactionType.payment,
  double amount = 500.0,
  String? billId,
  String? note,
  String paymentMode = 'cash',
  DateTime? createdAt,
}) {
  return TransactionModel(
    id: id,
    customerId: customerId,
    type: type,
    amount: amount,
    billId: billId,
    note: note,
    paymentMode: paymentMode,
    createdAt: createdAt ?? DateTime(2024),
  );
}

/// Factory for [UserModel]
UserModel makeUser({
  String id = 'user-1',
  String shopName = 'Test Shop',
  String ownerName = 'Test Owner',
  String phone = '9876543210',
  String? email = 'test@test.com',
  String? address,
  String? gstNumber,
  String? upiId,
  UserSettings? settings,
  bool isPaid = false,
  bool phoneVerified = false,
  bool emailVerified = false,
  DateTime? createdAt,
}) {
  return UserModel(
    id: id,
    shopName: shopName,
    ownerName: ownerName,
    phone: phone,
    email: email,
    address: address,
    gstNumber: gstNumber,
    upiId: upiId,
    settings: settings ?? const UserSettings(),
    isPaid: isPaid,
    phoneVerified: phoneVerified,
    emailVerified: emailVerified,
    createdAt: createdAt ?? DateTime(2024),
  );
}

/// Factory for [ExpenseModel]
ExpenseModel makeExpense({
  String id = 'exp-1',
  double amount = 500.0,
  ExpenseCategory category = ExpenseCategory.rent,
  String? description,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  DateTime? createdAt,
  String? date,
}) {
  return ExpenseModel(
    id: id,
    amount: amount,
    category: category,
    description: description,
    paymentMethod: paymentMethod,
    createdAt: createdAt ?? DateTime(2024, 1, 15),
    date: date ?? '2024-01-15',
  );
}

/// Factory for [UserSubscription]
UserSubscription makeSubscription({
  SubscriptionPlan plan = SubscriptionPlan.free,
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? startedAt,
  DateTime? expiresAt,
}) {
  return UserSubscription(
    plan: plan,
    status: status,
    startedAt: startedAt,
    expiresAt: expiresAt,
  );
}

/// Factory for [UserLimits]
UserLimits makeLimits({
  int billsThisMonth = 0,
  int billsLimit = 50,
  int productsCount = 0,
  int customersCount = 0,
}) {
  return UserLimits(
    billsThisMonth: billsThisMonth,
    billsLimit: billsLimit,
    productsCount: productsCount,
    customersCount: customersCount,
  );
}

/// Factory for [NotificationModel]
NotificationModel makeNotification({
  String id = 'notif-1',
  String title = 'Test Notification',
  String body = 'Test body content',
  NotificationType type = NotificationType.announcement,
  NotificationTargetType targetType = NotificationTargetType.all,
  String? targetUserId,
  String? targetPlan,
  DateTime? createdAt,
  String sentBy = 'admin',
  Map<String, dynamic>? data,
  bool read = false,
}) {
  return NotificationModel(
    id: id,
    title: title,
    body: body,
    type: type,
    targetType: targetType,
    targetUserId: targetUserId,
    targetPlan: targetPlan,
    createdAt: createdAt ?? DateTime(2024, 1, 15),
    sentBy: sentBy,
    data: data,
    read: read,
  );
}

/// Factory for [AdminUser]
AdminUser makeAdminUser({
  String id = 'admin-user-1',
  String email = 'shop@example.com',
  String shopName = 'Test Shop',
  String ownerName = 'Test Owner',
  String? phone = '9876543210',
  UserSubscription? subscription,
  UserLimits? limits,
  UserActivity? activity,
  DateTime? createdAt,
}) {
  return AdminUser(
    id: id,
    email: email,
    shopName: shopName,
    ownerName: ownerName,
    phone: phone,
    subscription: subscription ?? const UserSubscription(),
    limits: limits ?? const UserLimits(),
    activity: activity ?? const UserActivity(),
    createdAt: createdAt ?? DateTime(2024),
  );
}

/// Generates a list of bills for load testing
List<BillModel> makeBills(int count, {PaymentMethod? method}) {
  return List.generate(count, (i) {
    return makeBill(
      id: 'bill-$i',
      billNumber: i + 1,
      total: 100.0 + i,
      paymentMethod:
          method ?? PaymentMethod.values[i % 3], // Rotate cash, upi, udhar
      createdAt: DateTime(2024, 1, 15, 10, i),
      date: '2024-01-15',
    );
  });
}
