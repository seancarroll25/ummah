import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _errorMessage;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {

      final isInitialized = await SubscriptionService.isInitialized();

      if (!isInitialized) {
        try {
          await SubscriptionService.init();
        } catch (e, st) {
          rethrow;
        }

        await Future.delayed(const Duration(milliseconds: 500));

      }

      _isPremium = await SubscriptionService.hasPremium();

      setState(() => _checking = false);

      if (!_isPremium && !_paywallShown && mounted) {
        _paywallShown = true;

        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {

          await _showPaywall();
        } else {}
      } else {}

    } catch (e, st) {

      String errorCode = 'UNKNOWN';
      String errorMsg = e.toString();

      if (e is PlatformException) {
        errorCode = e.code;
        errorMsg = e.message ?? e.toString();

      }



      setState(() {
        _checking = false;
        _errorMessage = errorMsg;
        _errorCode = errorCode;
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    }
  }

  Future<void> _showPaywall() async {
    try {


      final paywallResult = await RevenueCatUI.presentPaywall();




      await SubscriptionService.refresh();

      _isPremium = await SubscriptionService.hasPremium();


      if (!_isPremium && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else if (mounted) {
        // User purchased, update UI
        setState(() {});
      }

    } catch (e, st) {


      String errorCode = 'UNKNOWN';
      String errorMsg = e.toString();

      if (e is PlatformException) {
        errorCode = e.code;
        errorMsg = e.message ?? e.toString();

      }

      // On error, navigate to main page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription error [$errorCode]: $errorMsg'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: Text(
                        'Error Code: $errorCode\n\n'
                            'Message: $errorMsg\n\n'
                            'Type: ${e.runtimeType}\n\n'
                            'Full Error:\n$e',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking subscription status...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Subscription Error',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_errorCode != null)
                  Text(
                    'Error Code: $_errorCode',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainPage()),
                    );
                  },
                  child: const Text('Continue to App'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _checking = true;
                      _errorMessage = null;
                      _errorCode = null;
                      _paywallShown = false;
                    });
                    _check();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isPremium) {
      return widget.child;
    }

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading subscription options...'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {

    super.dispose();
  }
}