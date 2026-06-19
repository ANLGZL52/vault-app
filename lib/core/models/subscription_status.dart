enum VaultPurchaseProduct { threeVaults, fiveVaults, allVaults }

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.hasVaultPro,
    required this.hasUnlimitedVaults,
    required this.purchasedVaultAllowance,
    required this.activeProducts,
  });

  const SubscriptionStatus.free()
    : hasVaultPro = false,
      hasUnlimitedVaults = false,
      purchasedVaultAllowance = 0,
      activeProducts = const {};

  final bool hasVaultPro;
  final bool hasUnlimitedVaults;
  final int purchasedVaultAllowance;
  final Set<VaultPurchaseProduct> activeProducts;

  bool canUseVaultCount(int currentVaultCount, {int freeVaultAllowance = 0}) {
    if (hasUnlimitedVaults) return true;
    return currentVaultCount < freeVaultAllowance + purchasedVaultAllowance;
  }
}

extension VaultPurchaseProductLabel on VaultPurchaseProduct {
  String get label {
    return switch (this) {
      VaultPurchaseProduct.threeVaults => '3 Kasa',
      VaultPurchaseProduct.fiveVaults => '5 Vaults',
      VaultPurchaseProduct.allVaults => 'All Vaults',
    };
  }
}
