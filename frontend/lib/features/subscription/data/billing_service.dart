import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// The RevenueCat entitlement that unlocks Premium features.
const premiumEntitlementId = 'premium';

/// What the store currently offers, shown on the paywall.
@immutable
class PremiumOffer {
  const PremiumOffer({required this.monthlyPrice, this.trialDays});

  /// Localised, e.g. "$0.99" or "£0.89".
  final String monthlyPrice;

  /// Length of the free trial for this user, or null if they don't get one
  /// (e.g. they've had a trial before).
  final int? trialDays;
}

enum PurchaseOutcome {
  /// Premium is active now.
  purchased,

  /// The user closed the store's payment sheet.
  cancelled,

  /// Paid with a method that takes time to clear; Premium unlocks when it does.
  pending,
}

/// The app store subscription, behind an interface so tests can use a fake.
abstract class BillingService {
  /// The monthly Premium subscription, or null if the store has none set up.
  Future<PremiumOffer?> getOffer();

  /// Opens the store's payment sheet. Throws if the store reports an error.
  Future<PurchaseOutcome> purchasePremium();

  /// Brings back a subscription bought earlier on this store account.
  /// Returns whether the user has Premium afterwards.
  Future<bool> restore();

  /// Links purchases to the signed-in SoulVerse account, so Premium follows
  /// the account across reinstalls and devices.
  Future<void> logIn(String userId);

  /// Unlinks the account after sign-out or account deletion.
  Future<void> logOut();

  /// Whether the user has Premium now, then again whenever it changes
  /// (purchase, renewal, cancellation running out, refund).
  Stream<bool> watchPremium();
}

// Public SDK keys from the RevenueCat dashboard, given at build time:
//   --dart-define=REVENUECAT_ANDROID_KEY=goog_... (and REVENUECAT_IOS_KEY=appl_...)
const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
const _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

class RevenueCatBillingService implements BillingService {
  bool _configured = false;

  String get _apiKey => Platform.isIOS ? _iosKey : _androidKey;

  /// Without a key (e.g. before RevenueCat is set up), nobody has Premium.
  bool get _available => _apiKey.isNotEmpty;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await Purchases.configure(PurchasesConfiguration(_apiKey));
    _configured = true;
  }

  @override
  Future<void> logIn(String userId) async {
    if (!_available) {
      debugPrint(
        'No RevenueCat API key in this build; Premium is unavailable.',
      );
      return;
    }
    await _ensureConfigured();
    await Purchases.logIn(userId);
  }

  @override
  Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } on PlatformException catch (e) {
      // Throws when there was no signed-in account; nothing to undo.
      debugPrint('RevenueCat logOut skipped: ${e.message}');
    }
  }

  @override
  Stream<bool> watchPremium() {
    if (!_available) return Stream.value(false);

    late final StreamController<bool> controller;
    void onUpdate(CustomerInfo info) => controller.add(_hasPremium(info));
    controller = StreamController<bool>(
      onListen: () async {
        try {
          await _ensureConfigured();
          Purchases.addCustomerInfoUpdateListener(onUpdate);
          controller.add(_hasPremium(await Purchases.getCustomerInfo()));
        } catch (e, st) {
          controller.addError(e, st);
        }
      },
      onCancel: () => Purchases.removeCustomerInfoUpdateListener(onUpdate),
    );
    return controller.stream;
  }

  static bool _hasPremium(CustomerInfo info) =>
      info.entitlements.active.containsKey(premiumEntitlementId);

  Package? _package;

  Future<Package?> _premiumPackage() async {
    if (_package != null) return _package;
    await _ensureConfigured();
    final offering = (await Purchases.getOfferings()).current;
    return _package =
        offering?.monthly ?? offering?.availablePackages.firstOrNull;
  }

  @override
  Future<PremiumOffer?> getOffer() async {
    if (!_available) return null;
    final product = (await _premiumPackage())?.storeProduct;
    if (product == null) return null;
    return PremiumOffer(
      monthlyPrice: product.priceString,
      trialDays: _trialDays(product),
    );
  }

  /// Google Play describes a free trial as a "free phase" of the subscription;
  /// the App Store as an introductory price of zero.
  static int? _trialDays(StoreProduct product) {
    final freePhase = product.defaultOption?.freePhase?.billingPeriod;
    if (freePhase != null) return _days(freePhase.unit, freePhase.value);
    final intro = product.introductoryPrice;
    if (intro != null && intro.price == 0) {
      return _days(intro.periodUnit, intro.periodNumberOfUnits);
    }
    return null;
  }

  static int? _days(PeriodUnit unit, int value) => switch (unit) {
    PeriodUnit.day => value,
    PeriodUnit.week => value * 7,
    PeriodUnit.month => value * 30,
    PeriodUnit.year => value * 365,
    PeriodUnit.unknown => null,
  };

  @override
  Future<PurchaseOutcome> purchasePremium() async {
    final package = await _premiumPackage();
    if (package == null) throw StateError('No Premium subscription is set up');
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _hasPremium(result.customerInfo)
          ? PurchaseOutcome.purchased
          : PurchaseOutcome.pending;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        return PurchaseOutcome.pending;
      }
      rethrow;
    }
  }

  @override
  Future<bool> restore() async {
    if (!_available) return false;
    await _ensureConfigured();
    return _hasPremium(await Purchases.restorePurchases());
  }
}
