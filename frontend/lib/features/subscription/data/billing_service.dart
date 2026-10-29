import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// The RevenueCat entitlement that unlocks Premium features.
const premiumEntitlementId = 'premium';

/// The app store subscription, behind an interface so tests can use a fake.
abstract class BillingService {
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
}
