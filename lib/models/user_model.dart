/// User/Shop model for Tulasi Stores app
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String shopName;
  final String ownerName;
  final String phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? shopLogoPath;
  final String? profileImagePath;
  final String? photoUrl;
  final String? upiId;
  final UserSettings settings;
  final bool isPaid;
  final bool phoneVerified;
  final bool emailVerified;
  final DateTime? phoneVerifiedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.shopLogoPath,
    this.profileImagePath,
    this.photoUrl,
    this.upiId,
    required this.settings,
    this.isPaid = false,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.phoneVerifiedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      shopName: (data['shopName'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: data['email'] as String?,
      address: data['address'] as String?,
      gstNumber: data['gstNumber'] as String?,
      shopLogoPath: data['shopLogoPath'] as String?,
      profileImagePath: data['profileImagePath'] as String?,
      photoUrl: data['photoUrl'] as String?,
      upiId: data['upiId'] as String?,
      settings: UserSettings.fromMap(
        (data['settings'] as Map<String, dynamic>?) ?? {},
      ),
      isPaid: (data['isPaid'] as bool?) ?? false,
      phoneVerified: (data['phoneVerified'] as bool?) ?? false,
      emailVerified: (data['emailVerified'] as bool?) ?? false,
      phoneVerifiedAt: (data['phoneVerifiedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'shopLogoPath': shopLogoPath,
      'profileImagePath': profileImagePath,
      'photoUrl': photoUrl,
      'upiId': upiId,
      'settings': settings.toMap(),
      'isPaid': isPaid,
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
      'phoneVerifiedAt': phoneVerifiedAt != null
          ? Timestamp.fromDate(phoneVerifiedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  UserModel copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? shopLogoPath,
    String? profileImagePath,
    String? photoUrl,
    String? upiId,
    UserSettings? settings,
    bool? isPaid,
    bool? phoneVerified,
    bool? emailVerified,
    DateTime? phoneVerifiedAt,
  }) {
    return UserModel(
      id: id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      shopLogoPath: shopLogoPath ?? this.shopLogoPath,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      photoUrl: photoUrl ?? this.photoUrl,
      upiId: upiId ?? this.upiId,
      settings: settings ?? this.settings,
      isPaid: isPaid ?? this.isPaid,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class UserSettings {
  final String language;
  final bool darkMode;
  final bool autoPrint;
  final bool printPreview;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool lowStockAlerts;
  final bool subscriptionAlerts;
  final bool dailySummary;
  final String? printerAddress;
  final String billSize;
  final bool gstEnabled;
  final double taxRate;
  final String receiptFooter;

  const UserSettings({
    this.language = 'hi',
    this.darkMode = false,
    this.autoPrint = false,
    this.printPreview = true,
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.lowStockAlerts = true,
    this.subscriptionAlerts = true,
    this.dailySummary = true,
    this.printerAddress,
    this.billSize = '58mm',
    this.gstEnabled = true,
    this.taxRate = 5.0,
    this.receiptFooter = 'Thank you for shopping!',
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      language: (map['language'] as String?) ?? 'hi',
      darkMode: (map['darkMode'] as bool?) ?? false,
      autoPrint: (map['autoPrint'] as bool?) ?? false,
      printPreview: (map['printPreview'] as bool?) ?? true,
      soundEnabled: (map['soundEnabled'] as bool?) ?? true,
      notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? true,
      lowStockAlerts: (map['lowStockAlerts'] as bool?) ?? true,
      subscriptionAlerts: (map['subscriptionAlerts'] as bool?) ?? true,
      dailySummary: (map['dailySummary'] as bool?) ?? true,
      printerAddress: map['printerAddress'] as String?,
      billSize: (map['billSize'] as String?) ?? '58mm',
      gstEnabled: (map['gstEnabled'] as bool?) ?? true,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 5.0,
      receiptFooter:
          (map['receiptFooter'] as String?) ?? 'Thank you for shopping!',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'darkMode': darkMode,
      'autoPrint': autoPrint,
      'printPreview': printPreview,
      'soundEnabled': soundEnabled,
      'notificationsEnabled': notificationsEnabled,
      'lowStockAlerts': lowStockAlerts,
      'subscriptionAlerts': subscriptionAlerts,
      'dailySummary': dailySummary,
      'printerAddress': printerAddress,
      'billSize': billSize,
      'gstEnabled': gstEnabled,
      'taxRate': taxRate,
      'receiptFooter': receiptFooter,
    };
  }

  UserSettings copyWith({
    String? language,
    bool? darkMode,
    bool? autoPrint,
    bool? printPreview,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? lowStockAlerts,
    bool? subscriptionAlerts,
    bool? dailySummary,
    String? printerAddress,
    String? billSize,
    bool? gstEnabled,
    double? taxRate,
    String? receiptFooter,
  }) {
    return UserSettings(
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      autoPrint: autoPrint ?? this.autoPrint,
      printPreview: printPreview ?? this.printPreview,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      subscriptionAlerts: subscriptionAlerts ?? this.subscriptionAlerts,
      dailySummary: dailySummary ?? this.dailySummary,
      printerAddress: printerAddress ?? this.printerAddress,
      billSize: billSize ?? this.billSize,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      taxRate: taxRate ?? this.taxRate,
      receiptFooter: receiptFooter ?? this.receiptFooter,
    );
  }
}
