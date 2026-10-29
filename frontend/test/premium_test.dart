import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soulverse/features/auth/application/auth_service.dart';
import 'package:soulverse/features/auth/data/models/user.dart';
import 'package:soulverse/features/subscription/application/premium_providers.dart';
import 'package:soulverse/features/subscription/data/app_config.dart';
import 'package:soulverse/features/subscription/data/billing_service.dart';

const _anna = User(
  id: 'usr_anna',
  email: 'anna@example.com',
  name: 'Anna',
  subscription: UserSubscription.free,
);

class _FakeAuth extends AuthNotifier {
  _FakeAuth(this._initial);

  final User? _initial;

  @override
  Future<User?> build() async => _initial;

  void setUser(User? user) => state = AsyncData(user);
}

class _FakeConfigApi implements AppConfigApi {
  _FakeConfigApi({this.billingEnabled = true, this.fails = false});

  final bool billingEnabled;
  final bool fails;

  @override
  Future<AppConfig> fetch() async {
    if (fails) throw Exception('offline');
    return AppConfig(billingEnabled: billingEnabled);
  }
}

class _FakeBilling implements BillingService {
  final calls = <String>[];
  final _premium = StreamController<bool>.broadcast();
  bool current = false;

  void setPremium(bool value) {
    current = value;
    _premium.add(value);
  }

  @override
  Future<void> logIn(String userId) async => calls.add('logIn:$userId');

  @override
  Future<void> logOut() async => calls.add('logOut');

  @override
  Stream<bool> watchPremium() async* {
    yield current;
    yield* _premium.stream;
  }

  @override
  Future<PremiumOffer?> getOffer() async => null;

  @override
  Future<PurchaseOutcome> purchasePremium() async => PurchaseOutcome.cancelled;

  @override
  Future<bool> restore() async => false;
}

void main() {
  late _FakeBilling billing;

  ProviderContainer containerWith({User? user, _FakeConfigApi? config}) {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _FakeAuth(user)),
        appConfigApiProvider.overrideWithValue(config ?? _FakeConfigApi()),
        billingServiceProvider.overrideWithValue(billing),
      ],
    );
    addTearDown(container.dispose);
    // Keep it running, as the app does from SoulVerseApp.
    container.listen(premiumEntitlementProvider, (_, _) {});
    return container;
  }

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() => billing = _FakeBilling());

  test(
    'billing switched off unlocks Premium without touching the store',
    () async {
      final container = containerWith(
        user: _anna,
        config: _FakeConfigApi(billingEnabled: false),
      );
      await settle();

      expect(container.read(billingEnabledProvider), isFalse);
      expect(container.read(isPremiumProvider), isTrue);
      expect(billing.calls, isEmpty, reason: 'RevenueCat is never started');
    },
  );

  test(
    'if the config can\'t load, billing stays on and Premium stays locked',
    () async {
      final container = containerWith(
        user: _anna,
        config: _FakeConfigApi(fails: true),
      );
      await settle();

      expect(container.read(billingEnabledProvider), isTrue);
      expect(container.read(isPremiumProvider), isFalse);
    },
  );

  test('guests never have Premium', () async {
    billing.current = true;
    final container = containerWith();
    await settle();

    expect(container.read(isPremiumProvider), isFalse);
    expect(billing.calls, ['logOut']);
  });

  test('Premium follows the signed-in account\'s subscription', () async {
    final container = containerWith(user: _anna);
    await settle();

    expect(billing.calls, ['logIn:usr_anna']);
    expect(container.read(isPremiumProvider), isFalse);

    // Buying (or a renewal) updates it straight away…
    billing.setPremium(true);
    await settle();
    expect(container.read(isPremiumProvider), isTrue);

    // …and so does the subscription running out.
    billing.setPremium(false);
    await settle();
    expect(container.read(isPremiumProvider), isFalse);
  });

  test('signing out unlinks the store account and locks Premium', () async {
    billing.current = true;
    final container = containerWith(user: _anna);
    await settle();
    expect(container.read(isPremiumProvider), isTrue);

    (container.read(authProvider.notifier) as _FakeAuth).setUser(null);
    await settle();

    expect(billing.calls, ['logIn:usr_anna', 'logOut']);
    expect(container.read(isPremiumProvider), isFalse);
  });
}
