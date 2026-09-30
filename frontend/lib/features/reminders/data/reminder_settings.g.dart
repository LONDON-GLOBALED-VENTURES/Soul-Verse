// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReminderSlot _$ReminderSlotFromJson(Map<String, dynamic> json) => ReminderSlot(
  enabled: json['enabled'] as bool,
  hour: (json['hour'] as num).toInt(),
  minute: (json['minute'] as num).toInt(),
);

Map<String, dynamic> _$ReminderSlotToJson(ReminderSlot instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'hour': instance.hour,
      'minute': instance.minute,
    };

ReminderSettings _$ReminderSettingsFromJson(Map<String, dynamic> json) =>
    ReminderSettings(
      morning: ReminderSlot.fromJson(json['morning'] as Map<String, dynamic>),
      evening: ReminderSlot.fromJson(json['evening'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReminderSettingsToJson(ReminderSettings instance) =>
    <String, dynamic>{
      'morning': instance.morning.toJson(),
      'evening': instance.evening.toJson(),
    };
