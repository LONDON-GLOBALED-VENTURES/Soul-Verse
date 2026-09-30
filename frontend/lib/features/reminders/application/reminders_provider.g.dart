// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's reminder settings. Changes are saved and the app reschedules via main.dart.

@ProviderFor(Reminders)
final remindersProvider = RemindersProvider._();

/// The user's reminder settings. Changes are saved and the app reschedules via main.dart.
final class RemindersProvider
    extends $AsyncNotifierProvider<Reminders, ReminderSettings> {
  /// The user's reminder settings. Changes are saved and the app reschedules via main.dart.
  RemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remindersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remindersHash();

  @$internal
  @override
  Reminders create() => Reminders();
}

String _$remindersHash() => r'54d501ebcae524b5a37417ae2d36af931ebf15ef';

/// The user's reminder settings. Changes are saved and the app reschedules via main.dart.

abstract class _$Reminders extends $AsyncNotifier<ReminderSettings> {
  FutureOr<ReminderSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ReminderSettings>, ReminderSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ReminderSettings>, ReminderSettings>,
              AsyncValue<ReminderSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
