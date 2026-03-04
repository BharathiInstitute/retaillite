import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        .collection('referrals')
        .where('referrerId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Shares the referral code via the platform share sheet.
  static Future<void> share(String code) async {
    await Share.share(
      'Try RetailLite for your shop! Use my referral code $code to sign up: https://retaillite.com/refer?code=$code',
      subject: 'Try RetailLite - Referral Code: $code',
    );
  }

  static String _generateCode(String uid) {
    final random = Random();
    final suffix = random.nextInt(9999).toString().padLeft(4, '0');
    final prefix = uid.substring(0, 4).toUpperCase();
    return '$prefix$suffix';
  }
}
