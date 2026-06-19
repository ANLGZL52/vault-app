import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/subscription_status.dart';
import 'revenuecat_service.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  final ValueNotifier<SubscriptionStatus> statusNotifier = ValueNotifier(
    const SubscriptionStatus.free(),
  );

  bool _isListening = false;

  SubscriptionStatus get status => statusNotifier.value;
  bool get hasVaultPro => status.hasVaultPro;
  bool get hasUnlimitedVaults => status.hasUnlimitedVaults;
  int get purchasedVaultAllowance => status.purchasedVaultAllowance;

  Future<void> start() async {
    if (!RevenueCatService.instance.isPlatformSupported ||
        !RevenueCatService.instance.isConfigured) {
      statusNotifier.value = const SubscriptionStatus.free();
      return;
    }

    if (!_isListening) {
      Purchases.addCustomerInfoUpdateListener(_handleCustomerInfoUpdate);
      _isListening = true;
    }

    await refresh();
  }

  Future<void> refresh() async {
    if (!RevenueCatService.instance.isPlatformSupported ||
        !RevenueCatService.instance.isConfigured) {
      statusNotifier.value = const SubscriptionStatus.free();
      return;
    }

    statusNotifier.value = await RevenueCatService.instance
        .getSubscriptionStatus();
    _logStatus();
  }

  void reset() {
    statusNotifier.value = const SubscriptionStatus.free();
  }

  void dispose() {
    if (_isListening) {
      Purchases.removeCustomerInfoUpdateListener(_handleCustomerInfoUpdate);
      _isListening = false;
    }
    statusNotifier.dispose();
  }

  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) {
    statusNotifier.value = RevenueCatService.instance
        .subscriptionStatusFromCustomerInfo(customerInfo);
    _logStatus();
  }

  void _logStatus() {
    if (kDebugMode) {
      debugPrint('[RevenueCat] Vault Pro active: ${status.hasVaultPro}');
      debugPrint(
        '[RevenueCat] Unlimited vaults active: ${status.hasUnlimitedVaults}',
      );
      debugPrint(
        '[RevenueCat] Purchased vault allowance: ${status.purchasedVaultAllowance}',
      );
      debugPrint(
        '[RevenueCat] Active products: ${status.activeProducts.map((product) => product.name).toList()}',
      );
    }
  }
}
