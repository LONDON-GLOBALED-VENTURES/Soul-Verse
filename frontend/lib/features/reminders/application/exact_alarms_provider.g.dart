// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exact_alarms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether reminders can be delivered on time. Invalidate after the user may have
/// changed the system setting (e.g. when the app returns to the foreground).

@ProviderFor(exactAlarmsAllowed)
final exactAlarmsAllowedProvider = ExactAlarmsAllowedProvider._();

/// Whether reminders can be delivered on time. Invalidate after the user may have
/// changed the system setting (e.g. when the app returns to the foreground).

final class ExactAlarmsAllowedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether reminders can be delivered on time. Invalidate after the user may have
  /// changed the system setting (e.g. when the app returns to the foreground).
  ExactAlarmsAllowedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exactAlarmsAllowedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exactAlarmsAllowedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return exactAlarmsAllowed(ref);
  }
}

String _$exactAlarmsAllowedHash() =>
    r'1450f82002f487e0dfcdea056e8bd0a239845c25';
