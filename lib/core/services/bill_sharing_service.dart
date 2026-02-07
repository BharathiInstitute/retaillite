/// Bill sharing service for SMS and WhatsApp
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to share bills via SMS and WhatsApp
class BillSharingService {
  /// Format a bill into a shareable text message
  static String formatBillMessage(BillModel bill, {String? shopName}) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('dd-MMM-yyyy').format(bill.createdAt);

    // Header
    buffer.writeln('🧾 *${shopName ?? 'LITE Billing'}*');
    buffer.writeln();
    buffer.writeln('Bill #${bill.billNumber} | $dateStr');
    buffer.writeln();

    // Items
    for (final item in bill.items) {
      buffer.writeln(
        '▸ ${item.name} x ${item.quantity} - ${item.total.asCurrency}',
      );
    }
    buffer.writeln();

    // Total
    buffer.writeln('💰 *Total: ${bill.total.asCurrency}*');
    buffer.writeln('💳 Payment: ${bill.paymentMethod.displayName}');

    // Footer
    buffer.writeln();
    buffer.writeln('Thank you for shopping with us! 🙏');

    return buffer.toString();
  }

  /// Send bill via SMS (Android only)
  /// Returns true if SMS app was opened successfully
  static Future<bool> sendSMS({
    required String phone,
    required BillModel bill,
    String? shopName,
  }) async {
    // SMS is only available on Android
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    final message = formatBillMessage(bill, shopName: shopName);
    final encodedMessage = Uri.encodeComponent(message);

    // Format phone number (remove any non-digit characters)
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    final smsUrl = Uri.parse('sms:$cleanPhone?body=$encodedMessage');

    try {
      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
        return true;
      }
    } catch (e) {
      // SMS failed
    }

    return false;
  }

  /// Send bill via WhatsApp
  /// On Android: Tries WhatsApp Business first, then normal WhatsApp
  /// On Desktop/Web: Uses WhatsApp Web
  static Future<bool> sendWhatsApp({
    required String phone,
    required BillModel bill,
    String? shopName,
  }) async {
    final message = formatBillMessage(bill, shopName: shopName);
    final encodedMessage = Uri.encodeComponent(message);

    // Format phone number with country code (assuming India +91)
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    // Desktop/Web: Use WhatsApp Web
    if (kIsWeb || _isDesktop) {
      final webUrl = Uri.parse(
        'https://wa.me/$cleanPhone?text=$encodedMessage',
      );
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return true;
      } catch (e) {
        return false;
      }
    }

    // Android: Try WhatsApp Business first, then normal WhatsApp
    if (Platform.isAndroid) {
      // Try WhatsApp Business first
      final businessUrl = Uri.parse(
        'whatsapp://send?phone=$cleanPhone&text=$encodedMessage',
      );

      try {
        if (await canLaunchUrl(businessUrl)) {
          await launchUrl(businessUrl);
          return true;
        }
      } catch (e) {
        // WhatsApp Business not available, try normal WhatsApp
      }

      // Fallback to WhatsApp Web URL which opens in WhatsApp app
      final fallbackUrl = Uri.parse(
        'https://wa.me/$cleanPhone?text=$encodedMessage',
      );
      try {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        return true;
      } catch (e) {
        return false;
      }
    }

    // iOS: Use WhatsApp URL scheme
    if (Platform.isIOS) {
      final iosUrl = Uri.parse(
        'whatsapp://send?phone=$cleanPhone&text=$encodedMessage',
      );
      try {
        if (await canLaunchUrl(iosUrl)) {
          await launchUrl(iosUrl);
          return true;
        }
        // Fallback to web
        final webUrl = Uri.parse(
          'https://wa.me/$cleanPhone?text=$encodedMessage',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return true;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  /// Check if running on desktop platform
  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Check if SMS is available on current platform
  static bool get isSmsAvailable {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if WhatsApp sharing is available
  static bool get isWhatsAppAvailable =>
      true; // Available on all platforms via web fallback

  /// Send bill via Email
  static Future<bool> sendEmail({
    required BillModel bill,
    String? shopName,
  }) async {
    final message = formatBillMessage(bill, shopName: shopName);
    final subject = Uri.encodeComponent(
      'Bill #${bill.billNumber} from ${shopName ?? 'LITE Billing'}',
    );
    final body = Uri.encodeComponent(message);

    final emailUrl = Uri.parse('mailto:?subject=$subject&body=$body');

    try {
      await launchUrl(emailUrl, mode: LaunchMode.externalApplication);
      return true;
    } catch (e) {
      return false;
    }
  }
}
