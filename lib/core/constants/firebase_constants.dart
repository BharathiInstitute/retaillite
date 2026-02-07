/// Firebase/Firestore collection and field name constants
library;

class FirebaseConstants {
  FirebaseConstants._();

  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String customersCollection = 'customers';
  static const String billsCollection = 'bills';
  static const String transactionsCollection = 'transactions';

  // User Document Fields
  static const String fieldShopName = 'shopName';
  static const String fieldOwnerName = 'ownerName';
  static const String fieldPhone = 'phone';
  static const String fieldAddress = 'address';
  static const String fieldGstNumber = 'gstNumber';
  static const String fieldSettings = 'settings';
  static const String fieldIsPaid = 'isPaid';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';

  // Product Fields
  static const String fieldName = 'name';
  static const String fieldPrice = 'price';
  static const String fieldPurchasePrice = 'purchasePrice';
  static const String fieldStock = 'stock';
  static const String fieldLowStockAlert = 'lowStockAlert';
  static const String fieldBarcode = 'barcode';
  static const String fieldUnit = 'unit';

  // Customer Fields
  static const String fieldBalance = 'balance';

  // Bill Fields
  static const String fieldBillNumber = 'billNumber';
  static const String fieldItems = 'items';
  static const String fieldTotal = 'total';
  static const String fieldPaymentMethod = 'paymentMethod';
  static const String fieldCustomerId = 'customerId';
  static const String fieldReceivedAmount = 'receivedAmount';
  static const String fieldDate = 'date';

  // Transaction Fields
  static const String fieldType = 'type';
  static const String fieldAmount = 'amount';
  static const String fieldBillId = 'billId';
  static const String fieldNote = 'note';
}
