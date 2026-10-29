import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_service.dart';
import '../data/app_config.dart';
import '../data/billing_service.dart';

final billingServiceProvider = Provider<BillingService>(
  (ref) => RevenueCatBillingService(),
);

/// Whether purchases are on. Off only on a QA/staging backend (BILLING_ENABLED=false).
/// Treated as on until the config has loaded.
final billingEnabledProvider = Provider<bool>(
  (ref) => ref.watch(appConfigProvider).value?.billingEnabled ?? true,
);

/// The signed-in user's Premium entitlement from the app store; false for
/// guests. Also keeps the store account in step with sign-in and sign-out.
/// When billing is off, RevenueCat isn't started at all.
final premiumEntitlementProvider = StreamProvider<bool>((ref) async* {
  final auth = ref.watch(
    authProvider.select(
      (auth) => (loading: auth.isLoading, id: auth.value?.id),
    ),
  );
  // Wait while signing in, out, or restoring the session at launch.
  if (auth.loading) return;
  final userId = auth.id;
  final config = await ref.watch(appConfigProvider.future);
  if (!config.billingEnabled) {
    yield false;
    return;
  }

  final billing = ref.read(billingServiceProvider);
  if (userId == null) {
    await billing.logOut();
    yield false;
    return;
  }
  await billing.logIn(userId);
  yield* billing.watchPremium();
});

/// Whether Premium features (your own photo, the image editor) are unlocked:
/// with an active subscription, or always when billing is switched off for QA.
final isPremiumProvider = Provider<bool>((ref) {
  if (!ref.watch(billingEnabledProvider)) return true;
  return ref.watch(premiumEntitlementProvider).value ?? false;
});
