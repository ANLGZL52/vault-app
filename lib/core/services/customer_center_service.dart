import 'package:flutter/foundation.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'revenuecat_service.dart';
import 'subscription_service.dart';

class CustomerCenterService {
  CustomerCenterService._();

  static final CustomerCenterService instance = CustomerCenterService._();

  Future<void> presentCustomerCenter() async {
    if (!RevenueCatService.instance.isPlatformSupported ||
        !RevenueCatService.instance.isConfigured) {
      throw const RevenueCatServiceException(
        'Abonelik yönetimi bu platformda kullanılamıyor.',
      );
    }

    try {
      await RevenueCatUI.presentCustomerCenter(
        onRestoreStarted: () => _debugLog('Restore started.'),
        onRestoreCompleted: (customerInfo) {
          _debugLog('Restore completed.');
          SubscriptionService.instance.refresh();
        },
        onRestoreFailed: (error) => _debugLog('Restore failed: $error'),
        onRefundRequestStarted: (productIdentifier) =>
            _debugLog('Refund started for $productIdentifier.'),
        onRefundRequestCompleted: (productIdentifier, status) => _debugLog(
          'Refund completed for $productIdentifier with status $status.',
        ),
        onShowingManageSubscriptions: () =>
            _debugLog('Showing manage subscriptions.'),
      );
      await SubscriptionService.instance.refresh();
    } catch (error) {
      _debugLog('Customer Center error: $error');
      rethrow;
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[RevenueCat] $message');
    }
  }
}
