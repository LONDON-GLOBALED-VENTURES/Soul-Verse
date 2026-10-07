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

/// Daily verse reminder. Off by default: turning it on asks for permission.
@JsonSerializable(explicitToJson: true)
class ReminderSettings {
  final ReminderSlot daily;

  const ReminderSettings({required this.daily});

  static const defaults = ReminderSettings(
    daily: ReminderSlot(enabled: false, hour: 8, minute: 0),
  );

  bool get anyEnabled => daily.enabled;

  ReminderSettings copyWith({ReminderSlot? daily}) =>
      ReminderSettings(daily: daily ?? this.daily);

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('daily') && json['daily'] is Map<String, dynamic>) {
      return _$ReminderSettingsFromJson(json);
    }
    // Backward compatibility for legacy morning/evening settings
    if (json.containsKey('morning') && json['morning'] is Map<String, dynamic>) {
      final morning =
          ReminderSlot.fromJson(json['morning'] as Map<String, dynamic>);
      return ReminderSettings(daily: morning);
    }
    return defaults;
  }

  Map<String, dynamic> toJson() => _$ReminderSettingsToJson(this);
}
