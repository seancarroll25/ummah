import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

class SubscriptionService {
  static const entitlementId = 'Ummah Pro';
  static const _tag = '[SUBSCRIPTION]';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {


      WidgetsFlutterBinding.ensureInitialized();

      await Purchases.setLogLevel(LogLevel.debug);


      final appUserId = await _getOrCreateAppUserId();


      PurchasesConfiguration configuration;

      if (defaultTargetPlatform == TargetPlatform.iOS) {


        if (appUserId.isNotEmpty) {
          configuration = PurchasesConfiguration('appl_ZwrTewcVpVFkPQREDTQvOzqjMNq')
            ..appUserID = appUserId;
        } else {
          configuration = PurchasesConfiguration('appl_ZwrTewcVpVFkPQREDTQvOzqjMNq');
        }
      } else if (defaultTargetPlatform == TargetPlatform.android) {

        if (appUserId.isNotEmpty) {
          configuration = PurchasesConfiguration('ANDROID_KEY')
            ..appUserID = appUserId;
        } else {
          configuration = PurchasesConfiguration('android key');
        }
      } else {
        throw Exception('Unsupported platform: ${defaultTargetPlatform.toString()}');
      }


      await Purchases.configure(configuration);


      _initialized = true;

      try {
        final customerInfo = await Purchases.getCustomerInfo();

      } catch (e, st) {

        _logPurchasesError(e, st);
      }



    } catch (e, st) {

      _logPurchasesError(e, st);

      _initialized = false;
      rethrow;
    }
  }

  static Future<String> _getOrCreateAppUserId() async {

    // For now, return empty string to let RevenueCat generate anonymous ID
    return '';
  }

  static Future<bool> hasPremium() async {
    try {
      if (!_initialized) {

        await init();
      }



      final info = await Purchases.getCustomerInfo();



      final active = info.entitlements.active.containsKey(entitlementId);


      if (!active && info.entitlements.all.containsKey(entitlementId)) {
        final entitlement = info.entitlements.all[entitlementId]!;

      }



      return active;
    } catch (e, st) {

      _logPurchasesError(e, st);

      return false;
    }
  }

  static Future<void> refresh() async {
    try {
      if (!_initialized) {

        return;
      }


      final info = await Purchases.getCustomerInfo();

    } catch (e, st) {

      _logPurchasesError(e, st);

    }
  }

  static Future<bool> isInitialized() async {
    return _initialized;
  }

  static void _logPurchasesError(dynamic error, StackTrace stackTrace) {
    if (error is PlatformException) {



      final code = error.code;

      if (code == '23' || code == 'UNEXPECTED_BACKEND_RESPONSE_ERROR') {
        debugPrint('$_tag     - Meaning: Unexpected backend response (Error 23)');
        debugPrint('$_tag     - Check: API key, network connection, RevenueCat status');
      } else if (code == '0' || code == 'UNKNOWN_ERROR') {
        debugPrint('$_tag     - Meaning: Unknown error');
      } else if (code == '1' || code == 'PURCHASE_CANCELLED_ERROR') {
        debugPrint('$_tag     - Meaning: User cancelled the purchase');
      } else if (code == '2' || code == 'STORE_PROBLEM_ERROR') {
        debugPrint('$_tag     - Meaning: Problem with App Store');
      } else if (code == '3' || code == 'PURCHASE_NOT_ALLOWED_ERROR') {
        debugPrint('$_tag     - Meaning: User not allowed to purchase');
      } else if (code == '4' || code == 'PURCHASE_INVALID_ERROR') {
        debugPrint('$_tag     - Meaning: Purchase invalid');
      } else if (code == '5' || code == 'PRODUCT_NOT_AVAILABLE_FOR_PURCHASE_ERROR') {
        debugPrint('$_tag     - Meaning: Product not available');
        debugPrint('$_tag     - Check: App Store Connect product setup');
      } else if (code == '6' || code == 'PRODUCT_ALREADY_PURCHASED_ERROR') {
        debugPrint('$_tag     - Meaning: Product already purchased');
      } else if (code == '7' || code == 'INVALID_RECEIPT_ERROR') {
        debugPrint('$_tag     - Meaning: Invalid receipt');
        debugPrint('$_tag     - Check: Using sandbox account?');
      } else if (code == '8' || code == 'MISSING_RECEIPT_FILE_ERROR') {
        debugPrint('$_tag     - Meaning: Receipt file missing');
      } else if (code == '9' || code == 'NETWORK_ERROR') {
        debugPrint('$_tag     - Meaning: Network connection problem');
        debugPrint('$_tag     - Check: Internet connection');
      } else if (code == '10' || code == 'INVALID_CREDENTIALS_ERROR') {
        debugPrint('$_tag     - Meaning: Invalid API credentials');
        debugPrint('$_tag     - Check: API key in RevenueCat dashboard');
      } else if (code == '16' || code == 'INVALID_APP_USER_ID_ERROR') {
        debugPrint('$_tag     - Meaning: Invalid app user ID');
      } else if (code == '20' || code == 'OPERATION_ALREADY_IN_PROGRESS_ERROR') {
        debugPrint('$_tag     - Meaning: Operation already in progress');
      } else {
        debugPrint('$_tag     - Code Value: $code');
        debugPrint('$_tag     - See: https://www.revenuecat.com/docs/errors');
      }
    } else {
      debugPrint('$_tag   Error Type: ${error.runtimeType}');
      debugPrint('$_tag   Error String: $error');
    }
  }
}