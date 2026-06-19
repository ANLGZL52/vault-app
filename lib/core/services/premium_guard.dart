import 'package:flutter/material.dart';

import '../../features/purchase/screens/purchase_page.dart';
import 'paywall_service.dart';
import 'revenuecat_service.dart';
import 'subscription_service.dart';
import 'vault_access_service.dart';

class PremiumGuard {
  PremiumGuard._();

  static final PremiumGuard instance = PremiumGuard._();

  Future<bool> requireVaultPro(BuildContext context) async {
    await SubscriptionService.instance.refresh();
    if (SubscriptionService.instance.hasVaultPro) {
      return true;
    }

    if (!context.mounted) return false;

    final canPresentPaywall = await RevenueCatService.instance
        .canPresentPaywall();
    if (!canPresentPaywall) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RevenueCatService.instance.lastPaywallUnavailableReason ??
                  'Satın alma seçenekleri şu anda hazırlanamadı. Lütfen daha sonra tekrar dene.',
            ),
          ),
        );
      }
      return false;
    }

    final result = await PaywallService.instance.presentPaywallIfNeeded();
    await SubscriptionService.instance.refresh();
    final allowed =
        PaywallService.instance.purchaseSucceeded(result) ||
        SubscriptionService.instance.hasVaultPro;

    if (!allowed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault Pro erişimi gerekli.')),
      );
    }

    return allowed;
  }

  Future<bool> canCreateVault({
    required BuildContext context,
    required int currentVaultCount,
    int freeVaultAllowance = 0,
  }) async {
    await SubscriptionService.instance.refresh();
    var status = SubscriptionService.instance.status;
    if (status.canUseVaultCount(
      currentVaultCount,
      freeVaultAllowance: freeVaultAllowance,
    )) {
      return true;
    }

    if (!context.mounted) return false;

    final canPresentPaywall = await RevenueCatService.instance
        .canPresentPaywall();
    if (!canPresentPaywall) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RevenueCatService.instance.lastPaywallUnavailableReason ??
                  'Satın alma seçenekleri şu anda hazırlanamadı. Lütfen daha sonra tekrar dene.',
            ),
          ),
        );
      }
      return false;
    }

    final result = await PaywallService.instance.presentPaywall();
    await SubscriptionService.instance.refresh();
    status = SubscriptionService.instance.status;

    final allowed =
        PaywallService.instance.purchaseSucceeded(result) &&
        status.canUseVaultCount(
          currentVaultCount,
          freeVaultAllowance: freeVaultAllowance,
        );

    if (!allowed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kasayı açmak için paket gerekli.')),
      );
    }

    return allowed;
  }

  Future<bool> canOpenVault({
    required BuildContext context,
    required int vaultId,
    VaultAccessService? vaultAccessService,
  }) async {
    final accessService = vaultAccessService ?? VaultAccessService();
    if (await accessService.canOpenVault(vaultId)) {
      return true;
    }

    if (!context.mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu kasayı açmak için kasa kredisi gerekiyor.'),
      ),
    );

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));

    if (!context.mounted) return false;
    return accessService.canOpenVault(vaultId);
  }
}
