import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

/// Service for managing referral codes and tracking referrals.
class ReferralService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Gets the current user's referral code, creating one if it doesn't exist.
  static Future<String> getOrCreateCode() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data['referralCode'] != null) {
      return data['referralCode'] as String;
    }

    // Generate a new referral code
    final code = _generateCode(uid);
    await _firestore.collection('users').doc(uid).set({
      'referralCode': code,
    }, SetOptions(merge: true));
    return code;
  }

  /// Gets the count of successful referrals for the current user.
  static Future<int> getReferralCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    final snapshot = await _firestore
        .collection('referral_rewards')
        .where('referrerId', isEqualTo: uid)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Shares the referral code via the platform share sheet.
  /// On web, copies to clipboard instead (Web Share API is unreliable).
  static Future<bool> share(String code) async {
    final text =
        'Try RetailLite for your shop! Use my referral code $code to sign up: https://retaillite.com/refer?code=$code';

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: text));
      return true; // Caller should show "Copied" feedback
    }

    await Share.share(text, subject: 'Try RetailLite - Referral Code: $code');
    return false; // Native share sheet shown, no extra feedback needed
  }

  static String _generateCode(String uid) {
    final random = Random();
    final suffix = random.nextInt(9999).toString().padLeft(4, '0');
    final prefix = uid.substring(0, 4).toUpperCase();
    return '$prefix$suffix';
  }
}
