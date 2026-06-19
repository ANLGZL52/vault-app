import '../../../core/services/revenuecat_service.dart';

enum VaultPackageType { threeVaults, fiveVaults, allVaults }

const packageCreditMap = {
  VaultPackageType.threeVaults: 3,
  VaultPackageType.fiveVaults: 5,
};

class VaultPackage {
  const VaultPackage({
    required this.type,
    required this.title,
    required this.description,
    required this.productIdentifier,
    required this.productIdentifiers,
  });

  final VaultPackageType type;
  final String title;
  final String description;
  final String productIdentifier;
  final List<String> productIdentifiers;

  static const threeVaultProductIds = [
    RevenueCatService.productThreeVaults,
    '3_vaults',
    'three_vaults',
  ];

  static const fiveVaultProductIds = [
    RevenueCatService.productFiveVaults,
    'five_vaults',
  ];

  static const allVaultProductIds = [
    RevenueCatService.productAllVaults,
    'all_vault',
  ];

  static const threeVaults = VaultPackage(
    type: VaultPackageType.threeVaults,
    title: '3 Kasa Paketi',
    description: 'Kilitli kasalardan 3 tanesini açmak için kredi ekler.',
    productIdentifier: RevenueCatService.productThreeVaults,
    productIdentifiers: threeVaultProductIds,
  );

  static const fiveVaults = VaultPackage(
    type: VaultPackageType.fiveVaults,
    title: '5 Kasa Paketi',
    description: 'Kilitli kasalardan 5 tanesini açmak için kredi ekler.',
    productIdentifier: RevenueCatService.productFiveVaults,
    productIdentifiers: fiveVaultProductIds,
  );

  static const allVaults = VaultPackage(
    type: VaultPackageType.allVaults,
    title: 'Tüm Kasalar',
    description: 'Kalan tüm kilitli kasalara kredi düşmeden erişim sağlar.',
    productIdentifier: RevenueCatService.productAllVaults,
    productIdentifiers: allVaultProductIds,
  );

  static const values = [threeVaults, fiveVaults, allVaults];
}
