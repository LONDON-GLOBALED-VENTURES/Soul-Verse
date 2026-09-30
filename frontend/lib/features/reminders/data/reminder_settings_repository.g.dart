// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reminderSettingsRepository)
final reminderSettingsRepositoryProvider =
    ReminderSettingsRepositoryProvider._();

final class ReminderSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          ReminderSettingsRepository,
          ReminderSettingsRepository,
          ReminderSettingsRepository
        >
    with $Provider<ReminderSettingsRepository> {
  ReminderSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReminderSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReminderSettingsRepository create(Ref ref) {
    return reminderSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderSettingsRepository>(value),
    );
  }
}

String _$reminderSettingsRepositoryHash() =>
    r'ae77eb170074117cd198d246d96f94da45b5ddb5';
