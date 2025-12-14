import 'package:purchases_flutter/purchases_flutter.dart';

Future<bool> hasProAccess() async {
  try {
    CustomerInfo info = await Purchases.getCustomerInfo();
    // Replace 'pro_features' with your RevenueCat entitlement identifier
    return info.entitlements.all["pro_features"]?.isActive ?? false;
  } catch (e) {
    print("Error fetching RevenueCat info: $e");
    return false;
  }
}
