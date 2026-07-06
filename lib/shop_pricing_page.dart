import 'package:car_washing_app/bundle_pricing_page.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

/// Merchant pricing: wash-credit bundles shown on the user Packages tab.
class ShopPricingPage extends StatelessWidget {
  const ShopPricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return BundlePricingPage(
      title: s.shopPricingTitle,
      description: s.shopPricingDesc,
      showStorePackageHint: true,
    );
  }
}
