import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static const entitlementId = 'Ummah Pro';
  static const _tag = '[SUBSCRIPTION]';

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Purchases.setLogLevel(LogLevel.debug);

    await Purchases.configure(
      PurchasesConfiguration(
        'test_dqzUaVZmxSDqJRgSiAeKqEkbwFU', // sandbox OK
      ),
    );

    debugPrint('$_tag RevenueCat initialized');
  }

  static Future<bool> hasPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active =
      info.entitlements.active.containsKey(entitlementId);

      debugPrint(
        '$_tag entitlement active: $active | '
            'all entitlements: ${info.entitlements.active.keys}',
      );

      return active;
    } catch (e, st) {
      debugPrint('$_tag entitlement check error: $e\n$st');
      return false;
    }
  }

  static Future<void> refresh() async {
    await Purchases.getCustomerInfo();
  }
}
