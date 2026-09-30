// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reminderService)
final reminderServiceProvider = ReminderServiceProvider._();

final class ReminderServiceProvider
    extends
        $FunctionalProvider<ReminderService, ReminderService, ReminderService>
    with $Provider<ReminderService> {
  ReminderServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderServiceHash();

  @$internal
  @override
  $ProviderElement<ReminderService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReminderService create(Ref ref) {
    return reminderService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderService>(value),
    );
  }
}

String _$reminderServiceHash() => r'6c37a4986c40d8bd1e98333de85072e14159f069';
