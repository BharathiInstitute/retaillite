/// App localization utilities with hardcoded strings
library;

import 'package:flutter/material.dart';

/// Supported locales
const supportedLocales = [
  Locale('en'), // English
  Locale('hi'), // Hindi
  Locale('te'), // Telugu
];

/// App localizations class with hardcoded translations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': _englishStrings,
    'hi': _hindiStrings,
    'te': _teluguStrings,
  };

  String _translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Getters for common strings
  String get appName => _translate('appName');
  String get appTagline => _translate('appTagline');

  // Navigation
  String get billing => _translate('billing');
  String get khata => _translate('khata');
  String get products => _translate('products');
  String get reports => _translate('reports');
  String get dashboard => _translate('dashboard');
  String get settings => _translate('settings');

  // Common actions
  String get save => _translate('save');
  String get cancel => _translate('cancel');
  String get delete => _translate('delete');
  String get add => _translate('add');
  String get edit => _translate('edit');
  String get search => _translate('search');
  String get searchProducts => _translate('searchProducts');
  String get share => _translate('share');
  String get close => _translate('close');
  String get confirm => _translate('confirm');
  String get retry => _translate('retry');
  String get loading => _translate('loading');
  String get noData => _translate('noData');

  // Billing
  String get total => _translate('total');
  String get subTotal => _translate('subTotal');
  String get cash => _translate('cash');
  String get upi => _translate('upi');
  String get udhar => _translate('udhar');
  String get pay => _translate('pay');
  String get payNow => _translate('payNow');
  String get receivedAmount => _translate('receivedAmount');
  String get change => _translate('change');
  String get quickAmounts => _translate('quickAmounts');
  String get selectPaymentMethod => _translate('selectPaymentMethod');
  String get billComplete => _translate('billComplete');
  String billNumber(int number) =>
      _translate('billNumber').replaceAll('{number}', '$number');
  String get printReceipt => _translate('printReceipt');
  String get shareReceipt => _translate('shareReceipt');
  String get newBill => _translate('newBill');
  String get cart => _translate('cart');
  String get emptyCart => _translate('emptyCart');
  String get addProductsToCart => _translate('addProductsToCart');
  String itemsInCart(int count) =>
      _translate('itemsInCart').replaceAll('{count}', '$count');
  String get scanBarcode => _translate('scanBarcode');
  String get barcode => _translate('barcode');

  // Products
  String get productName => _translate('productName');
  String get price => _translate('price');
  String get sellingPrice => _translate('sellingPrice');
  String get purchasePrice => _translate('purchasePrice');
  String get stock => _translate('stock');
  String get unit => _translate('unit');
  String get lowStock => _translate('lowStock');
  String get outOfStock => _translate('outOfStock');
  String get lowStockAlert => _translate('lowStockAlert');
  String get addProduct => _translate('addProduct');
  String get editProduct => _translate('editProduct');
  String get deleteProduct => _translate('deleteProduct');
  String get deleteProductConfirm => _translate('deleteProductConfirm');
  String get noProducts => _translate('noProducts');
  String get addFirstProduct => _translate('addFirstProduct');
  String get allProducts => _translate('allProducts');
  String get productAdded => _translate('productAdded');
  String get productUpdated => _translate('productUpdated');
  String get productDeleted => _translate('productDeleted');
  String get exportProducts => _translate('exportProducts');
  String get importProducts => _translate('importProducts');
  String get productCatalog => _translate('productCatalog');
  String get selectProducts => _translate('selectProducts');
  String get clear => _translate('clear');

  // Khata (Customers)
  String get customer => _translate('customer');
  String get customers => _translate('customers');
  String get customerName => _translate('customerName');
  String get phone => _translate('phone');
  String get address => _translate('address');
  String get balance => _translate('balance');
  String get payment => _translate('payment');
  String get recordPayment => _translate('recordPayment');
  String get sendReminder => _translate('sendReminder');
  String get reminder => _translate('reminder');
  String get totalDue => _translate('totalDue');
  String get addCustomer => _translate('addCustomer');
  String get editCustomer => _translate('editCustomer');
  String get noCustomers => _translate('noCustomers');
  String get addFirstCustomer => _translate('addFirstCustomer');
  String get allCustomers => _translate('allCustomers');
  String get withDue => _translate('withDue');
  String get paid => _translate('paid');
  String daysAgo(int days) =>
      _translate('daysAgo').replaceAll('{days}', '$days');
  String get paymentRecorded => _translate('paymentRecorded');
  String get transactions => _translate('transactions');
  String get purchase => _translate('purchase');
  String get noTransactions => _translate('noTransactions');

  // Reports
  String get today => _translate('today');
  String get thisWeek => _translate('thisWeek');
  String get thisMonth => _translate('thisMonth');
  String get totalSales => _translate('totalSales');
  String billsCount(int count) =>
      _translate('billsCount').replaceAll('{count}', '$count');
  String get averageBill => _translate('averageBill');
  String get exportPdf => _translate('exportPdf');
  String get topSellingProducts => _translate('topSellingProducts');
  String get noSalesData => _translate('noSalesData');
  String unitsSold(int count) =>
      _translate('unitsSold').replaceAll('{count}', '$count');
  String get recentBills => _translate('recentBills');

  // Settings
  String get shopDetails => _translate('shopDetails');
  String get shopName => _translate('shopName');
  String get ownerName => _translate('ownerName');
  String get gstNumber => _translate('gstNumber');
  String get subscription => _translate('subscription');
  String get freePlan => _translate('freePlan');
  String get premiumPlan => _translate('premiumPlan');
  String get unlimitedAccess => _translate('unlimitedAccess');
  String limitedAccess(int products, int bills) => _translate(
    'limitedAccess',
  ).replaceAll('{products}', '$products').replaceAll('{bills}', '$bills');
  String get upgradeToPremium => _translate('upgradeToPremium');
  String get appearance => _translate('appearance');
  String get darkMode => _translate('darkMode');
  String get language => _translate('language');
  String get selectLanguage => _translate('selectLanguage');
  String get english => _translate('english');
  String get hindi => _translate('hindi');
  String get telugu => _translate('telugu');
  String get printer => _translate('printer');
  String get configurePrinter => _translate('configurePrinter');
  String get dataManagement => _translate('dataManagement');
  String get backupData => _translate('backupData');
  String get exportData => _translate('exportData');
  String get support => _translate('support');
  String get helpCenter => _translate('helpCenter');
  String get sendFeedback => _translate('sendFeedback');
  String get rateApp => _translate('rateApp');
  String get about => _translate('about');
  String get version => _translate('version');
  String get signOut => _translate('signOut');
  String get signOutConfirm => _translate('signOutConfirm');

  // Auth
  String get login => _translate('login');
  String get signUp => _translate('signUp');
  String get email => _translate('email');
  String get password => _translate('password');
  String get forgotPassword => _translate('forgotPassword');
  String get welcomeBack => _translate('welcomeBack');
  String get loginToContinue => _translate('loginToContinue');
  String get dontHaveAccount => _translate('dontHaveAccount');
  String get alreadyHaveAccount => _translate('alreadyHaveAccount');
  String get createAccount => _translate('createAccount');
  String get setupShop => _translate('setupShop');
  String get enterShopDetails => _translate('enterShopDetails');
  String get getStarted => _translate('getStarted');
  String get resetPassword => _translate('resetPassword');
  String get sendResetLink => _translate('sendResetLink');
  String get backToLogin => _translate('backToLogin');

  // Settings extras
  String get syncNow => _translate('syncNow');
  String get syncStatus => _translate('syncStatus');
  String get syncInterval => _translate('syncInterval');
  String get dataRetention => _translate('dataRetention');
  String get paperSize => _translate('paperSize');
  String get fontSize => _translate('fontSize');
  String get printerSettings => _translate('printerSettings');
  String get editShopDetails => _translate('editShopDetails');
  String get connected => _translate('connected');
  String get notConnected => _translate('notConnected');
  String get logout => _translate('logout');
  String get on => _translate('on');
  String get off => _translate('off');
  String get shopInformation => _translate('shopInformation');
  String get appSettings => _translate('appSettings');
  String get sync => _translate('sync');
  String get pendingChanges => _translate('pendingChanges');
  String get uploadPendingChanges => _translate('uploadPendingChanges');
  String get syncCompleted => _translate('syncCompleted');
  String get syncFailed => _translate('syncFailed');
  String get loginEmail => _translate('loginEmail');
  String get days => _translate('days');

  // Errors
  String get error => _translate('error');
  String get somethingWentWrong => _translate('somethingWentWrong');
  String get networkError => _translate('networkError');
  String get tryAgain => _translate('tryAgain');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'te'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension for easy access
extension LocalizationsExtension on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizations(const Locale('en'));
}

// ============ ENGLISH STRINGS ============
const Map<String, String> _englishStrings = {
  'appName': 'Tulasi Stores',
  'appTagline': "India's Easiest Billing App",
  'billing': 'Billing',
  'khata': 'Khata',
  'products': 'Products',
  'reports': 'Reports',
  'dashboard': 'Dashboard',
  'settings': 'Settings',
  'save': 'Save',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'add': 'Add',
  'edit': 'Edit',
  'search': 'Search',
  'searchProducts': 'Search products...',
  'share': 'Share',
  'close': 'Close',
  'confirm': 'Confirm',
  'retry': 'Retry',
  'loading': 'Loading...',
  'noData': 'No data available',
  'total': 'Total',
  'subTotal': 'Sub Total',
  'cash': 'Cash',
  'upi': 'UPI',
  'udhar': 'Credit',
  'pay': 'Pay',
  'payNow': 'Pay Now',
  'receivedAmount': 'Received Amount',
  'change': 'Change',
  'quickAmounts': 'Quick Amounts',
  'selectPaymentMethod': 'Select Payment Method',
  'billComplete': 'Bill Complete!',
  'billNumber': 'Bill #{number}',
  'printReceipt': 'Print Receipt',
  'shareReceipt': 'Share Receipt',
  'newBill': 'New Bill',
  'cart': 'Cart',
  'emptyCart': 'Cart is empty',
  'addProductsToCart': 'Add products to start billing',
  'itemsInCart': '{count} items',
  'scanBarcode': 'Scan Barcode',
  'barcode': 'Barcode',
  'productName': 'Product Name',
  'price': 'Price',
  'sellingPrice': 'Selling Price',
  'purchasePrice': 'Purchase Price',
  'stock': 'Stock',
  'unit': 'Unit',
  'lowStock': 'Low Stock',
  'outOfStock': 'Out of Stock',
  'lowStockAlert': 'Low Stock Alert',
  'addProduct': 'Add Product',
  'editProduct': 'Edit Product',
  'deleteProduct': 'Delete Product',
  'deleteProductConfirm': 'Are you sure you want to delete this product?',
  'noProducts': 'No products yet',
  'addFirstProduct': 'Add your first product to get started',
  'allProducts': 'All',
  'productAdded': 'Product added successfully',
  'productUpdated': 'Product updated successfully',
  'productDeleted': 'Product deleted successfully',
  'exportProducts': 'Export Products',
  'importProducts': 'Import Products',
  'productCatalog': 'Product Catalog',
  'selectProducts': 'Select Products',
  'clear': 'Clear',
  'customer': 'Customer',
  'customers': 'Customers',
  'customerName': 'Customer Name',
  'phone': 'Phone',
  'address': 'Address',
  'balance': 'Balance',
  'payment': 'Payment',
  'recordPayment': 'Record Payment',
  'sendReminder': 'Send Reminder',
  'reminder': 'Reminder',
  'totalDue': 'Total Due',
  'addCustomer': 'Add Customer',
  'editCustomer': 'Edit Customer',
  'noCustomers': 'No customers yet',
  'addFirstCustomer': 'Add your first customer to track credit',
  'allCustomers': 'All',
  'withDue': 'With Due',
  'paid': 'Paid',
  'daysAgo': '{days} days ago',
  'paymentRecorded': 'Payment recorded successfully',
  'transactions': 'Transactions',
  'purchase': 'Purchase',
  'noTransactions': 'No transactions yet',
  'today': 'Today',
  'thisWeek': 'This Week',
  'thisMonth': 'This Month',
  'totalSales': 'Total Sales',
  'billsCount': '{count} bills',
  'averageBill': 'Avg',
  'exportPdf': 'Export PDF',
  'topSellingProducts': 'Top Selling Products',
  'noSalesData': 'No sales data available',
  'unitsSold': '{count} units sold',
  'recentBills': 'Recent Bills',
  'shopDetails': 'Shop Details',
  'shopName': 'Shop Name',
  'ownerName': 'Owner Name',
  'gstNumber': 'GST Number',
  'subscription': 'Subscription',
  'freePlan': 'Free Plan',
  'premiumPlan': 'Premium Plan',
  'unlimitedAccess': 'Unlimited products & bills',
  'limitedAccess': '{products} products, {bills} bills/day',
  'upgradeToPremium': 'Upgrade to Premium',
  'appearance': 'Appearance',
  'darkMode': 'Dark Mode',
  'language': 'Language',
  'selectLanguage': 'Select Language',
  'english': 'English',
  'hindi': 'हिंदी',
  'telugu': 'తెలుగు',
  'printer': 'Printer Settings',
  'configurePrinter': 'Configure Printer',
  'dataManagement': 'Data Management',
  'backupData': 'Backup Data',
  'exportData': 'Export Data',
  'support': 'Support',
  'helpCenter': 'Help Center',
  'sendFeedback': 'Send Feedback',
  'rateApp': 'Rate App',
  'about': 'About',
  'version': 'Version',
  'signOut': 'Sign Out',
  'signOutConfirm': 'Are you sure you want to sign out?',
  'login': 'Login',
  'signUp': 'Sign Up',
  'email': 'Email',
  'password': 'Password',
  'forgotPassword': 'Forgot Password?',
  'welcomeBack': 'Welcome Back!',
  'loginToContinue': 'Login to continue to your shop',
  'dontHaveAccount': "Don't have an account?",
  'alreadyHaveAccount': 'Already have an account?',
  'createAccount': 'Create Account',
  'setupShop': 'Setup Your Shop',
  'enterShopDetails': 'Enter your shop details to get started',
  'getStarted': 'Get Started',
  'resetPassword': 'Reset Password',
  'sendResetLink': 'Send Reset Link',
  'backToLogin': 'Back to Login',
  // Settings extras
  'syncNow': 'Sync Now',
  'syncStatus': 'Sync Status',
  'syncInterval': 'Sync Interval',
  'dataRetention': 'Data Retention',
  'paperSize': 'Paper Size',
  'fontSize': 'Font Size',
  'printerSettings': 'Printer Settings',
  'editShopDetails': 'Edit Shop Details',
  'connected': 'Connected',
  'notConnected': 'Not connected',
  'logout': 'Logout',
  'on': 'On',
  'off': 'Off',
  'shopInformation': 'Shop Information',
  'appSettings': 'App Settings',
  'sync': 'Sync',
  'pendingChanges': 'pending changes',
  'uploadPendingChanges': 'Upload pending changes',
  'syncCompleted': 'Sync completed!',
  'syncFailed': 'Sync failed',
  'loginEmail': 'Login Email',
  'days': 'days',
  'error': 'Error',
  'somethingWentWrong': 'Something went wrong',
  'networkError': 'Network error. Please check your connection.',
  'tryAgain': 'Try Again',
};

// ============ HINDI STRINGS ============
const Map<String, String> _hindiStrings = {
  'appName': 'Tulasi Stores',
  'appTagline': 'भारत का सबसे आसान बिलिंग ऐप',
  'billing': 'बिलिंग',
  'khata': 'खाता',
  'products': 'सामान',
  'reports': 'रिपोर्ट',
  'dashboard': 'डैशबोर्ड',
  'settings': 'सेटिंग्स',
  'save': 'सहेजें',
  'cancel': 'रद्द करें',
  'delete': 'हटाएं',
  'add': 'जोड़ें',
  'edit': 'संपादित करें',
  'search': 'खोजें',
  'searchProducts': 'सामान खोजें...',
  'share': 'शेयर करें',
  'close': 'बंद करें',
  'confirm': 'पुष्टि करें',
  'retry': 'पुनः प्रयास करें',
  'loading': 'लोड हो रहा है...',
  'noData': 'कोई डेटा नहीं',
  'total': 'कुल',
  'subTotal': 'उप-कुल',
  'cash': 'नकद',
  'upi': 'यूपीआई',
  'udhar': 'उधार',
  'pay': 'भुगतान करें',
  'payNow': 'अभी भुगतान करें',
  'receivedAmount': 'प्राप्त राशि',
  'change': 'वापसी',
  'quickAmounts': 'त्वरित राशि',
  'selectPaymentMethod': 'भुगतान विधि चुनें',
  'billComplete': 'बिल पूर्ण!',
  'billNumber': 'बिल #{number}',
  'printReceipt': 'रसीद प्रिंट करें',
  'shareReceipt': 'रसीद शेयर करें',
  'newBill': 'नया बिल',
  'cart': 'कार्ट',
  'emptyCart': 'कार्ट खाली है',
  'addProductsToCart': 'बिलिंग शुरू करने के लिए सामान जोड़ें',
  'itemsInCart': '{count} आइटम',
  'scanBarcode': 'बारकोड स्कैन करें',
  'barcode': 'बारकोड',
  'productName': 'उत्पाद का नाम',
  'price': 'मूल्य',
  'sellingPrice': 'बिक्री मूल्य',
  'purchasePrice': 'खरीद मूल्य',
  'stock': 'स्टॉक',
  'unit': 'इकाई',
  'lowStock': 'कम स्टॉक',
  'outOfStock': 'स्टॉक समाप्त',
  'lowStockAlert': 'कम स्टॉक चेतावनी',
  'addProduct': 'सामान जोड़ें',
  'editProduct': 'सामान संपादित करें',
  'deleteProduct': 'सामान हटाएं',
  'deleteProductConfirm': 'क्या आप इस उत्पाद को हटाना चाहते हैं?',
  'noProducts': 'कोई सामान नहीं',
  'addFirstProduct': 'शुरू करने के लिए पहला सामान जोड़ें',
  'allProducts': 'सभी',
  'productAdded': 'सामान सफलतापूर्वक जोड़ा गया',
  'productUpdated': 'सामान अपडेट हो गया',
  'productDeleted': 'सामान हटा दिया गया',
  'exportProducts': 'प्रोडक्ट निर्यात करें',
  'importProducts': 'प्रोडक्ट आयात करें',
  'productCatalog': 'प्रोडक्ट कैटलॉग',
  'selectProducts': 'प्रोडक्ट चुनें',
  'clear': 'साफ करें',
  'customer': 'ग्राहक',
  'customers': 'ग्राहक',
  'customerName': 'ग्राहक का नाम',
  'phone': 'फोन',
  'address': 'पता',
  'balance': 'बकाया',
  'payment': 'भुगतान',
  'recordPayment': 'भुगतान दर्ज करें',
  'sendReminder': 'याद दिलाएं',
  'reminder': 'रिमाइंडर',
  'totalDue': 'कुल बकाया',
  'addCustomer': 'ग्राहक जोड़ें',
  'editCustomer': 'ग्राहक संपादित करें',
  'noCustomers': 'कोई ग्राहक नहीं',
  'addFirstCustomer': 'उधार ट्रैक करने के लिए ग्राहक जोड़ें',
  'allCustomers': 'सभी',
  'withDue': 'बकाया वाले',
  'paid': 'भुगतान किया',
  'daysAgo': '{days} दिन पहले',
  'paymentRecorded': 'भुगतान दर्ज हो गया',
  'transactions': 'लेनदेन',
  'purchase': 'खरीद',
  'noTransactions': 'कोई लेनदेन नहीं',
  'today': 'आज',
  'thisWeek': 'इस सप्ताह',
  'thisMonth': 'इस महीने',
  'totalSales': 'कुल बिक्री',
  'billsCount': '{count} बिल',
  'averageBill': 'औसत',
  'exportPdf': 'पीडीएफ निर्यात',
  'topSellingProducts': 'सबसे ज्यादा बिकने वाले',
  'noSalesData': 'बिक्री डेटा उपलब्ध नहीं',
  'unitsSold': '{count} यूनिट बिके',
  'recentBills': 'हाल के बिल',
  'shopDetails': 'दुकान विवरण',
  'shopName': 'दुकान का नाम',
  'ownerName': 'मालिक का नाम',
  'gstNumber': 'जीएसटी नंबर',
  'subscription': 'सदस्यता',
  'freePlan': 'मुफ्त प्लान',
  'premiumPlan': 'प्रीमियम प्लान',
  'unlimitedAccess': 'असीमित सामान और बिल',
  'limitedAccess': '{products} सामान, {bills} बिल/दिन',
  'upgradeToPremium': 'प्रीमियम में अपग्रेड करें',
  'appearance': 'दिखावट',
  'darkMode': 'डार्क मोड',
  'language': 'भाषा',
  'selectLanguage': 'भाषा चुनें',
  'english': 'English',
  'hindi': 'हिंदी',
  'telugu': 'తెలుగు',
  'printer': 'प्रिंटर सेटिंग्स',
  'configurePrinter': 'प्रिंटर कॉन्फ़िगर करें',
  'dataManagement': 'डेटा प्रबंधन',
  'backupData': 'डेटा बैकअप',
  'exportData': 'डेटा निर्यात',
  'support': 'सहायता',
  'helpCenter': 'सहायता केंद्र',
  'sendFeedback': 'फीडबैक भेजें',
  'rateApp': 'ऐप रेट करें',
  'about': 'बारे में',
  'version': 'वर्जन',
  'signOut': 'साइन आउट',
  'signOutConfirm': 'क्या आप साइन आउट करना चाहते हैं?',
  'login': 'लॉगिन',
  'signUp': 'साइन अप',
  'email': 'ईमेल',
  'password': 'पासवर्ड',
  'forgotPassword': 'पासवर्ड भूल गए?',
  'welcomeBack': 'वापसी पर स्वागत!',
  'loginToContinue': 'अपनी दुकान में जारी रखने के लिए लॉगिन करें',
  'dontHaveAccount': 'खाता नहीं है?',
  'alreadyHaveAccount': 'पहले से खाता है?',
  'createAccount': 'खाता बनाएं',
  'setupShop': 'अपनी दुकान सेटअप करें',
  'enterShopDetails': 'शुरू करने के लिए दुकान विवरण दर्ज करें',
  'getStarted': 'शुरू करें',
  'resetPassword': 'पासवर्ड रीसेट करें',
  'sendResetLink': 'रीसेट लिंक भेजें',
  'backToLogin': 'लॉगिन पर वापस जाएं',
  // Settings extras
  'syncNow': 'अभी सिंक करें',
  'syncStatus': 'सिंक स्थिति',
  'syncInterval': 'सिंक अंतराल',
  'dataRetention': 'डेटा अवधि',
  'paperSize': 'पेपर साइज़',
  'fontSize': 'फॉन्ट साइज़',
  'printerSettings': 'प्रिंटर सेटिंग्स',
  'editShopDetails': 'दुकान विवरण संपादित करें',
  'connected': 'कनेक्टेड',
  'notConnected': 'कनेक्ट नहीं',
  'logout': 'लॉगआउट',
  'on': 'चालू',
  'off': 'बंद',
  'shopInformation': 'दुकान की जानकारी',
  'appSettings': 'ऐप सेटिंग्स',
  'sync': 'सिंक',
  'pendingChanges': 'लंबित परिवर्तन',
  'uploadPendingChanges': 'लंबित परिवर्तन अपलोड करें',
  'syncCompleted': 'सिंक पूर्ण!',
  'syncFailed': 'सिंक विफल',
  'loginEmail': 'लॉगिन ईमेल',
  'days': 'दिन',
  'error': 'त्रुटि',
  'somethingWentWrong': 'कुछ गलत हो गया',
  'networkError': 'नेटवर्क त्रुटि। कृपया कनेक्शन जांचें।',
  'tryAgain': 'पुनः प्रयास करें',
};

// ============ TELUGU STRINGS ============
const Map<String, String> _teluguStrings = {
  'appName': 'Tulasi Stores',
  'appTagline': 'భారతదేశం యొక్క సులభమైన బిల్లింగ్ యాప్',
  'billing': 'బిల్లింగ్',
  'khata': 'ఖాతా',
  'products': 'ఉత్పత్తులు',
  'reports': 'రిపోర్టులు',
  'dashboard': 'డాష్‌బోర్డ్',
  'settings': 'సెట్టింగ్స్',
  'save': 'సేవ్',
  'cancel': 'రద్దు',
  'delete': 'తొలగించు',
  'add': 'జోడించు',
  'edit': 'సవరించు',
  'search': 'వెతకండి',
  'searchProducts': 'ఉత్పత్తులను వెతకండి...',
  'share': 'షేర్',
  'close': 'మూసివేయండి',
  'confirm': 'నిర్ధారించు',
  'retry': 'మళ్ళీ ప్రయత్నించండి',
  'loading': 'లోడ్ అవుతోంది...',
  'noData': 'డేటా లేదు',
  'total': 'మొత్తం',
  'subTotal': 'ఉప మొత్తం',
  'cash': 'నగదు',
  'upi': 'యుపిఐ',
  'udhar': 'అరువు',
  'pay': 'చెల్లించు',
  'payNow': 'ఇప్పుడు చెల్లించు',
  'receivedAmount': 'అందిన మొత్తం',
  'change': 'చిల్లర',
  'quickAmounts': 'త్వరిత మొత్తాలు',
  'selectPaymentMethod': 'చెల్లింపు విధానం ఎంచుకోండి',
  'billComplete': 'బిల్లు పూర్తి!',
  'billNumber': 'బిల్లు #{number}',
  'printReceipt': 'రసీదు ప్రింట్',
  'shareReceipt': 'రసీదు షేర్',
  'newBill': 'కొత్త బిల్లు',
  'cart': 'కార్ట్',
  'emptyCart': 'కార్ట్ ఖాళీగా ఉంది',
  'addProductsToCart': 'బిల్లింగ్ ప్రారంభించడానికి ఉత్పత్తులను జోడించండి',
  'itemsInCart': '{count} ఐటమ్స్',
  'scanBarcode': 'బార్‌కోడ్ స్కాన్',
  'barcode': 'బార్‌కోడ్',
  'productName': 'ఉత్పత్తి పేరు',
  'price': 'ధర',
  'sellingPrice': 'అమ్మకపు ధర',
  'purchasePrice': 'కొనుగోలు ధర',
  'stock': 'స్టాక్',
  'unit': 'యూనిట్',
  'lowStock': 'తక్కువ స్టాక్',
  'outOfStock': 'స్టాక్ లేదు',
  'lowStockAlert': 'తక్కువ స్టాక్ హెచ్చరిక',
  'addProduct': 'ఉత్పత్తి జోడించు',
  'editProduct': 'ఉత్పత్తి సవరించు',
  'deleteProduct': 'ఉత్పత్తి తొలగించు',
  'deleteProductConfirm': 'మీరు ఈ ఉత్పత్తిని తొలగించాలనుకుంటున్నారా?',
  'noProducts': 'ఉత్పత్తులు లేవు',
  'addFirstProduct': 'ప్రారంభించడానికి మొదటి ఉత్పత్తిని జోడించండి',
  'allProducts': 'అన్నీ',
  'productAdded': 'ఉత్పత్తి విజయవంతంగా జోడించబడింది',
  'productUpdated': 'ఉత్పత్తి నవీకరించబడింది',
  'productDeleted': 'ఉత్పత్తి తొలగించబడింది',
  'exportProducts': 'ఉత్పత్తులను ఎగుమతి చేయండి',
  'importProducts': 'ఉత్పత్తులను దిగుమతి చేయండి',
  'productCatalog': 'ఉత్పత్తి కాటలాగ్',
  'selectProducts': 'ఉత్పత్తులను ఎంచుకోండి',
  'clear': 'క్లియర్',
  'customer': 'కస్టమర్',
  'customers': 'కస్టమర్లు',
  'customerName': 'కస్టమర్ పేరు',
  'phone': 'ఫోన్',
  'address': 'చిరునామా',
  'balance': 'బ్యాలెన్స్',
  'payment': 'చెల్లింపు',
  'recordPayment': 'చెల్లింపు నమోదు',
  'sendReminder': 'రిమైండర్ పంపు',
  'reminder': 'రిమైండర్',
  'totalDue': 'మొత్తం బకాయి',
  'addCustomer': 'కస్టమర్ జోడించు',
  'editCustomer': 'కస్టమర్ సవరించు',
  'noCustomers': 'కస్టమర్లు లేరు',
  'addFirstCustomer': 'అరువు ట్రాక్ చేయడానికి కస్టమర్ జోడించండి',
  'allCustomers': 'అందరూ',
  'withDue': 'బకాయి ఉన్నవారు',
  'paid': 'చెల్లించారు',
  'daysAgo': '{days} రోజుల క్రితం',
  'paymentRecorded': 'చెల్లింపు నమోదు అయింది',
  'transactions': 'లావాదేవీలు',
  'purchase': 'కొనుగోలు',
  'noTransactions': 'లావాదేవీలు లేవు',
  'today': 'ఈరోజు',
  'thisWeek': 'ఈ వారం',
  'thisMonth': 'ఈ నెల',
  'totalSales': 'మొత్తం అమ్మకాలు',
  'billsCount': '{count} బిల్లులు',
  'averageBill': 'సగటు',
  'exportPdf': 'PDF ఎగుమతి',
  'topSellingProducts': 'ఎక్కువగా అమ్ముడైనవి',
  'noSalesData': 'అమ్మకాల డేటా లేదు',
  'unitsSold': '{count} యూనిట్లు అమ్ముడయ్యాయి',
  'recentBills': 'ఇటీవలి బిల్లులు',
  'shopDetails': 'షాప్ వివరాలు',
  'shopName': 'షాప్ పేరు',
  'ownerName': 'యజమాని పేరు',
  'gstNumber': 'GST నంబర్',
  'subscription': 'సబ్‌స్క్రిప్షన్',
  'freePlan': 'ఫ్రీ ప్లాన్',
  'premiumPlan': 'ప్రీమియం ప్లాన్',
  'unlimitedAccess': 'అపరిమిత ఉత్పత్తులు & బిల్లులు',
  'limitedAccess': '{products} ఉత్పత్తులు, {bills} బిల్లులు/రోజు',
  'upgradeToPremium': 'ప్రీమియంకు అప్‌గ్రేడ్',
  'appearance': 'రూపం',
  'darkMode': 'డార్క్ మోడ్',
  'language': 'భాష',
  'selectLanguage': 'భాష ఎంచుకోండి',
  'english': 'English',
  'hindi': 'हिंदी',
  'telugu': 'తెలుగు',
  'printer': 'ప్రింటర్ సెట్టింగ్స్',
  'configurePrinter': 'ప్రింటర్ కాన్ఫిగర్',
  'dataManagement': 'డేటా నిర్వహణ',
  'backupData': 'డేటా బ్యాకప్',
  'exportData': 'డేటా ఎగుమతి',
  'support': 'సపోర్ట్',
  'helpCenter': 'సహాయ కేంద్రం',
  'sendFeedback': 'ఫీడ్‌బ్యాక్ పంపు',
  'rateApp': 'యాప్ రేట్ చేయండి',
  'about': 'గురించి',
  'version': 'వెర్షన్',
  'signOut': 'సైన్ ఔట్',
  'signOutConfirm': 'మీరు సైన్ ఔట్ చేయాలనుకుంటున్నారా?',
  'login': 'లాగిన్',
  'signUp': 'సైన్ అప్',
  'email': 'ఇమెయిల్',
  'password': 'పాస్‌వర్డ్',
  'forgotPassword': 'పాస్‌వర్డ్ మర్చిపోయారా?',
  'welcomeBack': 'తిరిగి స్వాగతం!',
  'loginToContinue': 'మీ షాప్‌లో కొనసాగించడానికి లాగిన్ అవ్వండి',
  'dontHaveAccount': 'ఖాతా లేదా?',
  'alreadyHaveAccount': 'ఇప్పటికే ఖాతా ఉందా?',
  'createAccount': 'ఖాతా సృష్టించు',
  'setupShop': 'మీ షాప్ సెటప్ చేయండి',
  'enterShopDetails': 'ప్రారంభించడానికి షాప్ వివరాలు నమోదు చేయండి',
  'getStarted': 'ప్రారంభించు',
  'resetPassword': 'పాస్‌వర్డ్ రీసెట్',
  'sendResetLink': 'రీసెట్ లింక్ పంపు',
  'backToLogin': 'లాగిన్‌కు తిరిగి వెళ్ళు',
  // Settings extras
  'syncNow': 'ఇప్పుడు సింక్',
  'syncStatus': 'సింక్ స్థితి',
  'syncInterval': 'సింక్ వ్యవధి',
  'dataRetention': 'డేటా నిలుపుదల',
  'paperSize': 'పేపర్ సైజు',
  'fontSize': 'ఫాంట్ సైజు',
  'printerSettings': 'ప్రింటర్ సెట్టింగ్స్',
  'editShopDetails': 'షాప్ వివరాలు సవరించు',
  'connected': 'కనెక్ట్ అయింది',
  'notConnected': 'కనెక్ట్ కాలేదు',
  'logout': 'లాగౌట్',
  'on': 'ఆన్',
  'off': 'ఆఫ్',
  'shopInformation': 'షాప్ సమాచారం',
  'appSettings': 'యాప్ సెట్టింగ్స్',
  'sync': 'సింక్',
  'pendingChanges': 'పెండింగ్ మార్పులు',
  'uploadPendingChanges': 'పెండింగ్ మార్పులు అప్‌లోడ్',
  'syncCompleted': 'సింక్ పూర్తయింది!',
  'syncFailed': 'సింక్ విఫలమైంది',
  'loginEmail': 'లాగిన్ ఇమెయిల్',
  'days': 'రోజులు',
  'error': 'లోపం',
  'somethingWentWrong': 'ఏదో తప్పు జరిగింది',
  'networkError': 'నెట్‌వర్క్ లోపం. దయచేసి కనెక్షన్ తనిఖీ చేయండి.',
  'tryAgain': 'మళ్ళీ ప్రయత్నించండి',
};
