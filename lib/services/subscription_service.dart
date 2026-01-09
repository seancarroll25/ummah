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

  }

  static Future<bool> hasPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active =
      info.entitlements.active.containsKey(entitlementId);



      return active;
    } catch (e, st) {
      return false;
    }
  }

  static Future<void> refresh() async {
    await Purchases.getCustomerInfo();
  }
}
