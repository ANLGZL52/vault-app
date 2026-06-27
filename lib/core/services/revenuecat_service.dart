import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/subscription_status.dart';

class RevenueCatServiceException implements Exception {
  const RevenueCatServiceException(this.message, [this.originalError]);

  final String message;
  final Object? originalError;

  @override
  String toString() => message;
}

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  static const apiKey = 'appl_qwHQgRIVLDyAMEecmiWkNCyljPY';
  static const entitlementId = 'Vault Pro';
  static const offeringIdentifier = 'default';
  static const productAllVaults = 'all_vaults';
  static const productThreeVaults = '3_kasa';
  static const productFiveVaults = '5_vaults';
  static const productIds = [
    productAllVaults,
    productThreeVaults,
    productFiveVaults,
  ];

  bool _isConfigured = false;
  String? _currentUserId;
  String? _lastPaywallUnavailableReason;

  bool get isConfigured => _isConfigured;
  String? get currentUserId => _currentUserId;
  String? get lastPaywallUnavailableReason => _lastPaywallUnavailableReason;
  bool get isPlatformSupported {
    if (kIsWeb) return true;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
  }

  Future<void> prepareForStartup() async {
    if (!isPlatformSupported) {
      _debugLog('RevenueCat skipped on unsupported platform.');
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
  }

  Future<void> initialize(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw const RevenueCatServiceException(
        'RevenueCat kullanıcı kimliği boş olamaz.',
      );
    }

    try {
      if (!isPlatformSupported) {
        _debugLog('RevenueCat initialize skipped on unsupported platform.');
        return;
      }

      await prepareForStartup();

      if (!_isConfigured) {
        _debugLog(
          'Selected RevenueCat API key prefix: ${_apiKeyPrefix(apiKey)}',
        );
        final configuration = PurchasesConfiguration(apiKey)
          ..appUserID = trimmedUserId;
        await Purchases.configure(configuration);
        _isConfigured = true;
        _currentUserId = trimmedUserId;
        _debugLog('Configured with authenticated user: $trimmedUserId');
        await _logConfiguredStatus();
      } else if (_currentUserId != trimmedUserId) {
        await login(trimmedUserId);
      }

      await getCustomerInfo();
      await debugRevenueCatState();
    } catch (error) {
      throw _toServiceException(error);
    }
  }

  Future<void> login(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw const RevenueCatServiceException(
        'RevenueCat kullanıcı kimliği boş olamaz.',
      );
    }

    try {
      if (!_isConfigured) {
        await initialize(trimmedUserId);
        return;
      }

      await Purchases.logIn(trimmedUserId);
      _currentUserId = trimmedUserId;
      _debugLog('Logged in as authenticated user: $trimmedUserId');
      await getCustomerInfo();
      await debugRevenueCatState();
    } catch (error) {
      throw _toServiceException(error);
    }
  }

  Future<void> logout() async {
    if (!_isConfigured) return;

    try {
      await Purchases.logOut();
      _currentUserId = null;
      _debugLog('Logged out from RevenueCat.');
    } catch (error) {
      throw _toServiceException(error);
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_isConfigured) return null;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _debugLog('Fetched CustomerInfo for ${customerInfo.originalAppUserId}');
      return customerInfo;
    } catch (error) {
      throw _toServiceException(error);
    }
  }

  Future<bool> hasVaultPro() async {
    try {
      final status = await getSubscriptionStatus();
      return status.hasVaultPro;
    } catch (error) {
      _debugLog('hasVaultPro failed: $error');
      return false;
    }
  }

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final customerInfo = await getCustomerInfo();
    if (customerInfo == null) return const SubscriptionStatus.free();

    return subscriptionStatusFromCustomerInfo(customerInfo);
  }

  SubscriptionStatus subscriptionStatusFromCustomerInfo(
    CustomerInfo customerInfo,
  ) {
    final activeEntitlements = customerInfo.entitlements.active;
    final entitlement = activeEntitlements[entitlementId];
    final activeProductIds = <String>{
      ...customerInfo.activeSubscriptions,
      ...customerInfo.allPurchasedProductIdentifiers,
      if (entitlement?.productIdentifier != null)
        entitlement!.productIdentifier,
    };

    final activeProducts = <VaultPurchaseProduct>{};
    var purchasedVaultAllowance = 0;
    var hasUnlimitedVaults = false;

    if (activeProductIds.contains(productThreeVaults)) {
      activeProducts.add(VaultPurchaseProduct.threeVaults);
      purchasedVaultAllowance += 3;
    }

    if (activeProductIds.contains(productFiveVaults)) {
      activeProducts.add(VaultPurchaseProduct.fiveVaults);
      purchasedVaultAllowance += 5;
    }

    if (activeProductIds.contains(productAllVaults)) {
      activeProducts.add(VaultPurchaseProduct.allVaults);
      hasUnlimitedVaults = true;
    }

    final hasVaultPro =
        entitlement?.isActive == true || activeProducts.isNotEmpty;

    _debugLog('active product identifiers: ${activeProductIds.toList()}');
    _debugLog(
      'active entitlement identifiers: ${activeEntitlements.keys.toList()}',
    );
    _debugLog('hasUnlimitedVaults: $hasUnlimitedVaults');
    _debugLog('purchasedVaultAllowance: $purchasedVaultAllowance');
    _debugLog(
      'activeProducts: ${activeProducts.map((product) => product.name).toList()}',
    );

    return SubscriptionStatus(
      hasVaultPro: hasVaultPro,
      hasUnlimitedVaults: hasUnlimitedVaults,
      purchasedVaultAllowance: purchasedVaultAllowance,
      activeProducts: activeProducts,
    );
  }

  Future<bool> canPresentPaywall() async {
    _lastPaywallUnavailableReason = null;
    _debugLog('canPresentPaywall local configured: $_isConfigured');
    _debugLog('canPresentPaywall current user id: $_currentUserId');
    _debugLog('expected current offering identifier: $offeringIdentifier');

    if (!isPlatformSupported) {
      return _paywallUnavailable('Satın alma bu platformda desteklenmiyor.');
    }

    if (!_isConfigured) {
      return _paywallUnavailable('RevenueCat yapılandırılmamış.');
    }

    try {
      final sdkConfigured = await Purchases.isConfigured;
      _debugLog('Purchases.isConfigured=$sdkConfigured');
      if (!sdkConfigured) {
        return _paywallUnavailable('RevenueCat yapılandırılmamış.');
      }
    } on PlatformException catch (error) {
      _logPlatformException('Purchases.isConfigured failed', error);
      return _paywallUnavailable(_platformExceptionDetails(error));
    }

    try {
      final offerings = await Purchases.getOfferings();
      _logOfferings(offerings);

      final current = offerings.current;
      if (current == null) {
        return _paywallUnavailable(
          'RevenueCat current offering bulunamadı. Dashboard > Product Catalog > Offerings içinde default offering oluştur ve current olarak seç.',
        );
      }

      if (current.identifier != offeringIdentifier) {
        _debugLog(
          'Current offering is "${current.identifier}", expected "$offeringIdentifier".',
        );
      }

      if (current.availablePackages.isEmpty) {
        return _paywallUnavailable(
          'RevenueCat current offering içinde package yok. all_vaults, 3_kasa, 5_vaults package olarak eklenmeli.',
        );
      }

      return true;
    } on PlatformException catch (error) {
      _logPlatformException('Purchases.getOfferings failed', error);
      return _paywallUnavailable(_platformExceptionDetails(error));
    } catch (error) {
      _debugLog('Purchases.getOfferings failed: $error');
      return _paywallUnavailable(
        'RevenueCat offering bilgileri alınamadı: $error',
      );
    }
  }

  Future<void> debugRevenueCatState() async {
    if (!kDebugMode) return;

    _debugLog('--- RevenueCat debug state ---');
    _debugLog('local configured: $_isConfigured');
    _debugLog('current user id: $_currentUserId');
    _debugLog('api key prefix: ${_apiKeyPrefix(apiKey)}');
    _debugLog('expected current offering identifier: $offeringIdentifier');

    if (isPlatformSupported) {
      await _logConfiguredStatus();
    }

    if (!isPlatformSupported || !_isConfigured) {
      _debugLog('RevenueCat debug skipped. supported=$isPlatformSupported');
      return;
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.active[entitlementId];
      final status = subscriptionStatusFromCustomerInfo(customerInfo);
      _debugLog('entitlement "$entitlementId" active: ${entitlement != null}');
      _debugLog('active subscriptions: ${customerInfo.activeSubscriptions}');
      _debugLog(
        'purchased products: ${customerInfo.allPurchasedProductIdentifiers}',
      );
      _debugLog('status hasVaultPro: ${status.hasVaultPro}');
      _debugLog('status unlimited: ${status.hasUnlimitedVaults}');
      _debugLog('status allowance: ${status.purchasedVaultAllowance}');
    } on PlatformException catch (error) {
      _logPlatformException('Purchases.getCustomerInfo failed', error);
    } catch (error) {
      _debugLog('Purchases.getCustomerInfo failed: $error');
    }

    try {
      final offerings = await Purchases.getOfferings();
      _logOfferings(offerings);
    } on PlatformException catch (error) {
      _logPlatformException('Purchases.getOfferings failed', error);
    } catch (error) {
      _debugLog('Purchases.getOfferings failed: $error');
    }

    try {
      final products = await Purchases.getProducts(productIds);
      _debugLog('requested products: $productIds');
      _debugLog(
        'returned products: ${products.map((product) => product.identifier).toList()}',
      );
    } on PlatformException catch (error) {
      _logPlatformException('Purchases.getProducts failed', error);
    } catch (error) {
      _debugLog('Purchases.getProducts failed: $error');
    }
  }

  Future<Map<String, String>> getProductPriceMap() async {
    if (!_isConfigured || !isPlatformSupported) return {};
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return {};
      return {
        for (final pkg in current.availablePackages)
          pkg.storeProduct.identifier: pkg.storeProduct.priceString,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> restorePurchases() async {
    if (!_isConfigured) {
      throw const RevenueCatServiceException('RevenueCat henüz başlatılmadı.');
    }

    try {
      await Purchases.restorePurchases();
      _debugLog('Restore purchases completed.');
    } catch (error) {
      throw _toServiceException(error);
    }
  }

  Future<PurchaseResult> purchasePackageByProductId(
    String productIdentifier,
  ) async {
    return purchasePackageByProductIds([productIdentifier]);
  }

  Future<PurchaseResult> purchasePackageByProductIds(
    List<String> productIdentifiers,
  ) async {
    if (!isPlatformSupported) {
      throw const RevenueCatServiceException(
        'Satın alma bu platformda desteklenmiyor.',
      );
    }

    if (!_isConfigured) {
      throw const RevenueCatServiceException('RevenueCat henüz başlatılmadı.');
    }

    try {
      final identifiers = productIdentifiers
          .map((identifier) => identifier.trim())
          .where((identifier) => identifier.isNotEmpty)
          .toSet();
      if (identifiers.isEmpty) {
        throw const RevenueCatServiceException(
          'Satın alma ürünü tanımlı değil.',
        );
      }

      final offerings = await Purchases.getOfferings();
      _logOfferings(offerings);

      final current = offerings.current;
      if (current == null) {
        throw const RevenueCatServiceException(
          'RevenueCat current offering bulunamadı.',
        );
      }

      Package? package;
      for (final candidate in current.availablePackages) {
        if (identifiers.contains(candidate.storeProduct.identifier) ||
            identifiers.contains(candidate.identifier)) {
          package = candidate;
          break;
        }
      }

      if (package == null) {
        throw RevenueCatServiceException(
          'RevenueCat paketi bulunamadı: ${identifiers.join(', ')}. Dashboard current offering içine bu ürünü package olarak ekle.',
        );
      }

      _debugLog(
        'Purchasing package=${package.identifier} product=${package.storeProduct.identifier}',
      );

      final result = await Purchases.purchase(PurchaseParams.package(package));
      _debugLog(
        'Purchase completed for product=${result.storeTransaction.productIdentifier}',
      );
      return result;
    } catch (error) {
      throw _toServiceException(error);
    }
  }

  RevenueCatServiceException _toServiceException(Object error) {
    if (error is RevenueCatServiceException) return error;

    if (error is PlatformException) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      return RevenueCatServiceException(_messageForErrorCode(code), error);
    }

    return RevenueCatServiceException(
      'Satın alma işlemi şu anda tamamlanamadı. Lütfen tekrar dene.',
      error,
    );
  }

  String _messageForErrorCode(PurchasesErrorCode code) {
    return switch (code) {
      PurchasesErrorCode.purchaseCancelledError =>
        'Satın alma işlemi iptal edildi.',
      PurchasesErrorCode.networkError ||
      PurchasesErrorCode.offlineConnectionError =>
        'Bağlantı sorunu nedeniyle işlem tamamlanamadı.',
      PurchasesErrorCode.storeProblemError ||
      PurchasesErrorCode.productNotAvailableForPurchaseError ||
      PurchasesErrorCode.configurationError ||
      PurchasesErrorCode.missingReceiptFileError =>
        'Mağaza bağlantısı şu anda hazır değil. Lütfen biraz sonra tekrar dene.',
      PurchasesErrorCode.paymentPendingError =>
        'Ödeme beklemede. Onaylandığında erişimin otomatik güncellenecek.',
      _ => 'Satın alma işlemi şu anda tamamlanamadı. Lütfen tekrar dene.',
    };
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[RevenueCat] $message');
    }
  }

  Future<void> _logConfiguredStatus() async {
    try {
      final sdkConfigured = await Purchases.isConfigured;
      _debugLog('Purchases.isConfigured=$sdkConfigured');
    } on PlatformException catch (error) {
      _logPlatformException('Purchases.isConfigured failed', error);
    }
  }

  void _logOfferings(Offerings offerings) {
    final current = offerings.current;
    final packages = current?.availablePackages ?? const [];

    _debugLog('offerings.all keys: ${offerings.all.keys.toList()}');
    _debugLog('current offering identifier: ${current?.identifier}');
    _debugLog(
      'available package identifiers: ${packages.map((package) => package.identifier).toList()}',
    );
    _debugLog(
      'store product identifiers: ${packages.map((package) => package.storeProduct.identifier).toList()}',
    );
  }

  String _apiKeyPrefix(String key) {
    if (key.isEmpty) return '<empty>';
    final visibleLength = key.length < 8 ? key.length : 8;
    return '${key.substring(0, visibleLength)}...';
  }

  bool _paywallUnavailable(String reason) {
    _lastPaywallUnavailableReason = reason;
    _debugLog('Paywall unavailable: $reason');
    return false;
  }

  void _logPlatformException(String label, PlatformException error) {
    _debugLog(
      '$label code=${error.code} message=${error.message} details=${error.details}',
    );
  }

  String _platformExceptionDetails(PlatformException error) {
    return [
      'RevenueCat hatası.',
      'code=${error.code}',
      'message=${error.message}',
      'details=${error.details}',
      'underlyingErrorMessage=${_underlyingErrorMessage(error.details)}',
    ].join(' ');
  }

  Object? _underlyingErrorMessage(Object? details) {
    if (details is Map) {
      return details['underlyingErrorMessage'] ??
          details['readableErrorCode'] ??
          details['message'];
    }

    return null;
  }
}
