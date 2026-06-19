import 'package:flutter/foundation.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'revenuecat_service.dart';
import 'subscription_service.dart';

class PaywallService {
  PaywallService._();

  static final PaywallService instance = PaywallService._();

  Future<PaywallResult> presentPaywall() async {
    if (!RevenueCatService.instance.isPlatformSupported ||
        !RevenueCatService.instance.isConfigured) {
      return PaywallResult.error;
    }

    if (!await RevenueCatService.instance.canPresentPaywall()) {
      _debugLog('Paywall blocked because offerings are not available.');
      return PaywallResult.error;
    }

    try {
      final result = await RevenueCatUI.presentPaywall(
        displayCloseButton: true,
      );
      await SubscriptionService.instance.refresh();
      _debugLog('Paywall result: $result');
      return result;
    } catch (error) {
      _debugLog('Paywall error: $error');
      return PaywallResult.error;
    }
  }

  Future<PaywallResult> presentPaywallIfNeeded() async {
    if (!RevenueCatService.instance.isPlatformSupported ||
        !RevenueCatService.instance.isConfigured) {
      return PaywallResult.error;
    }

    if (!await RevenueCatService.instance.canPresentPaywall()) {
      _debugLog(
        'Paywall-if-needed blocked because offerings are not available.',
      );
      return PaywallResult.error;
    }

    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        RevenueCatService.entitlementId,
        displayCloseButton: true,
      );
      await SubscriptionService.instance.refresh();
      _debugLog('Paywall-if-needed result: $result');
      return result;
    } catch (error) {
      _debugLog('Paywall-if-needed error: $error');
      return PaywallResult.error;
    }
  }

  bool purchaseSucceeded(PaywallResult result) {
    return result == PaywallResult.purchased ||
        result == PaywallResult.restored ||
        result == PaywallResult.notPresented;
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[RevenueCat] $message');
    }
  }
}
