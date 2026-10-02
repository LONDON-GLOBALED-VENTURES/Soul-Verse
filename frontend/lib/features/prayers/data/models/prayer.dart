import 'package:flutter/foundation.dart';

@immutable
class SpiritualStatus {
  const SpiritualStatus({
    required this.level,
    required this.title,
    required this.emoji,
    required this.currentLikes,
    this.nextTitle,
    this.nextThreshold,
    required this.progress,
  });

  final int level;
  final String title;
  final String emoji;
  final int currentLikes;
  final String? nextTitle;
  final int? nextThreshold;
  final double progress;

  String get displayTitle => '$emoji $title';

  static const initial = SpiritualStatus(
    level: 1,
    title: 'Seeker',
    emoji: '🌱',
    currentLikes: 0,
    nextTitle: 'Believer',
    nextThreshold: 5,
    progress: 0.0,
  );

  factory SpiritualStatus.fromJson(Map<String, dynamic> json) {
    return SpiritualStatus(
      level: (json['level'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Seeker',
      emoji: json['emoji'] as String? ?? '🌱',
      currentLikes: (json['currentLikes'] as num?)?.toInt() ?? 0,
      nextTitle: json['nextTitle'] as String?,
      nextThreshold: (json['nextThreshold'] as num?)?.toInt(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'title': title,
    'emoji': emoji,
    'currentLikes': currentLikes,
    'nextTitle': nextTitle,
    'nextThreshold': nextThreshold,
    'progress': progress,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpiritualStatus &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          title == other.title &&
          currentLikes == other.currentLikes;

  @override
  int get hashCode => Object.hash(level, title, currentLikes);
}

@immutable
class PrayerStats {
  const PrayerStats({
    this.prayersShared = 0,
    this.likesReceived = 0,
    this.likesGiven = 0,
    this.status = SpiritualStatus.initial,
  });

  final int prayersShared;
  final int likesReceived;
  final int likesGiven;
  final SpiritualStatus status;

  static const initial = PrayerStats();

  factory PrayerStats.fromJson(Map<String, dynamic> json) {
    return PrayerStats(
      prayersShared: (json['prayersShared'] as num?)?.toInt() ?? 0,
      likesReceived: (json['likesReceived'] as num?)?.toInt() ?? 0,
      likesGiven: (json['likesGiven'] as num?)?.toInt() ?? 0,
      status: json['status'] is Map<String, dynamic>
          ? SpiritualStatus.fromJson(json['status'] as Map<String, dynamic>)
          : SpiritualStatus.initial,
    );
  }

  Map<String, dynamic> toJson() => {
    'prayersShared': prayersShared,
    'likesReceived': likesReceived,
    'likesGiven': likesGiven,
    'status': status.toJson(),
  };

  PrayerStats copyWith({
    int? prayersShared,
    int? likesReceived,
    int? likesGiven,
    SpiritualStatus? status,
  }) {
    return PrayerStats(
      prayersShared: prayersShared ?? this.prayersShared,
      likesReceived: likesReceived ?? this.likesReceived,
      likesGiven: likesGiven ?? this.likesGiven,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerStats &&
          runtimeType == other.runtimeType &&
          prayersShared == other.prayersShared &&
          likesReceived == other.likesReceived &&
          likesGiven == other.likesGiven &&
          status == other.status;

  @override
  int get hashCode => Object.hash(prayersShared, likesReceived, likesGiven, status);
}

@immutable
class Prayer {
  const Prayer({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = '',
    this.authorStatusLevel = 'Seeker',
    this.authorStatusEmoji = '🌱',
    this.isAnonymous = false,
    required this.title,
    required this.content,
    this.category = 'General',
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.isMine = false,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String authorStatusLevel;
  final String authorStatusEmoji;
  final bool isAnonymous;
  final String title;
  final String content;
  final String category;
  final int likesCount;
  final bool isLikedByMe;
  final bool isMine;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] as String,
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Believer',
      authorAvatar: json['authorAvatar'] as String? ?? '',
      authorStatusLevel: json['authorStatusLevel'] as String? ?? 'Seeker',
      authorStatusEmoji: json['authorStatusEmoji'] as String? ?? '🌱',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLikedByMe: json['isLikedByMe'] as bool? ?? false,
      isMine: json['isMine'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'authorStatusLevel': authorStatusLevel,
    'authorStatusEmoji': authorStatusEmoji,
    'isAnonymous': isAnonymous,
    'title': title,
    'content': content,
    'category': category,
    'likesCount': likesCount,
    'isLikedByMe': isLikedByMe,
    'isMine': isMine,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  Prayer copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorStatusLevel,
    String? authorStatusEmoji,
    bool? isAnonymous,
    String? title,
    String? content,
    String? category,
    int? likesCount,
    bool? isLikedByMe,
    bool? isMine,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prayer(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorStatusLevel: authorStatusLevel ?? this.authorStatusLevel,
      authorStatusEmoji: authorStatusEmoji ?? this.authorStatusEmoji,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isMine: isMine ?? this.isMine,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prayer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          likesCount == other.likesCount &&
          isLikedByMe == other.isLikedByMe;

  @override
  int get hashCode => Object.hash(id, likesCount, isLikedByMe);
}
