import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/legal_links.dart';
import '../application/premium_providers.dart';

/// Whether the signed-in user is paying for Premium right now. Unlike
/// [isPremiumProvider], false when Premium is only unlocked because billing
/// is switched off for QA.
bool hasActiveSubscription(WidgetRef ref) =>
    ref.watch(billingEnabledProvider) &&
    (ref.watch(premiumEntitlementProvider).value ?? false);

/// Opens the store page where the user manages or cancels their subscription.
Future<void> openManageSubscription(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    final url = await ref.read(billingServiceProvider).managementUrl();
    opened = await openExternalUrl(url);
  } catch (_) {
    // e.g. no browser on the device.
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Couldn\'t open your subscriptions.')),
    );
  }
}

/// Restores a subscription bought earlier on this store account.
Future<void> restorePurchases(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  try {
    final restored = await ref.read(billingServiceProvider).restore();
    say(
      restored
          ? 'Your SoulVerse Premium is restored.'
          : 'No Premium subscription was found for this account.',
    );
  } catch (_) {
    say('Couldn\'t restore purchases. Please try again.');
  }
}
