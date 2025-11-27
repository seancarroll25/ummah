import 'dart:async';
import 'dart:developer';

import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
void presentPaywall() async {
  final result = await RevenueCatUI.presentPaywall();
  log('Paywall result: $result');
}

void presentPaywallIfNeeded() async {
  final result = await RevenueCatUI.presentPaywallIfNeeded("pro");
  log('Paywall result: $result');
}
