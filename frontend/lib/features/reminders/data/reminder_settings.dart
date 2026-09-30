import 'package:json_annotation/json_annotation.dart';

part 'reminder_settings.g.dart';

@JsonSerializable()
class ReminderSlot {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSlot({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  ReminderSlot copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSlot(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  factory ReminderSlot.fromJson(Map<String, dynamic> json) =>
      _$ReminderSlotFromJson(json);
  Map<String, dynamic> toJson() => _$ReminderSlotToJson(this);
}

/// Morning and evening verse reminders. Off by default: turning one on asks for permission.
@JsonSerializable(explicitToJson: true)
class ReminderSettings {
  final ReminderSlot morning;
  final ReminderSlot evening;

  const ReminderSettings({required this.morning, required this.evening});

  static const defaults = ReminderSettings(
    morning: ReminderSlot(enabled: false, hour: 7, minute: 0),
    evening: ReminderSlot(enabled: false, hour: 20, minute: 0),
  );

  bool get anyEnabled => morning.enabled || evening.enabled;

  ReminderSettings copyWith({ReminderSlot? morning, ReminderSlot? evening}) =>
      ReminderSettings(
        morning: morning ?? this.morning,
        evening: evening ?? this.evening,
      );

  factory ReminderSettings.fromJson(Map<String, dynamic> json) =>
      _$ReminderSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$ReminderSettingsToJson(this);
}
