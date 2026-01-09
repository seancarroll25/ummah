import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../pages/MainPage.dart';
import '../services/subscription_service.dart';

class PremiumGuard extends StatefulWidget {
  final Widget child;

  const PremiumGuard({super.key, required this.child});

  @override
  State<PremiumGuard> createState() => _PremiumGuardState();
}

class _PremiumGuardState extends State<PremiumGuard> {
  bool _checking = true;
  bool _isPremium = false;
  bool _paywallShown = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    _isPremium = await SubscriptionService.hasPremium();
    setState(() => _checking = false);

    if (!_isPremium && !_paywallShown) {
      _paywallShown = true;
      await _showPaywall();
    }
  }

  Future<void> _showPaywall() async {
    debugPrint('[PREMIUM GUARD] Presenting paywall');

    await RevenueCatUI.presentPaywall();

    await SubscriptionService.refresh();
    _isPremium = await SubscriptionService.hasPremium();

    debugPrint(
      '[PREMIUM GUARD] After paywall entitlement: $_isPremium',
    );

    if (!_isPremium && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isPremium) {
      return widget.child;
    }

    // Temporary placeholder while paywall is active
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
