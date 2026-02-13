/// User/Shop model for LITE app
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
  final UserSettings settings;
  final bool isPaid;
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
    required this.settings,
    this.isPaid = false,
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
      settings: UserSettings.fromMap(
        (data['settings'] as Map<String, dynamic>?) ?? {},
      ),
      isPaid: (data['isPaid'] as bool?) ?? false,
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
      'settings': settings.toMap(),
      'isPaid': isPaid,
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
    UserSettings? settings,
    bool? isPaid,
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
      settings: settings ?? this.settings,
      isPaid: isPaid ?? this.isPaid,
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
      printerAddress: printerAddress ?? this.printerAddress,
      billSize: billSize ?? this.billSize,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      taxRate: taxRate ?? this.taxRate,
      receiptFooter: receiptFooter ?? this.receiptFooter,
    );
  }
}
