import 'package:flutter/foundation.dart';
import '../../../prayers/data/models/prayer.dart';

@immutable
class UserSubscription {
  const UserSubscription({
    required this.status,
    required this.tier,
    this.expiresAt,
  });

  final String status; // 'free' | 'active' | 'cancelled'
  final String tier; // 'none' | 'premium'
  final DateTime? expiresAt;

  bool get isPremium => status == 'active' || tier == 'premium';

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      status: json['status'] as String? ?? 'free',
      tier: json['tier'] as String? ?? 'none',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'tier': tier,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };

  static const free = UserSubscription(status: 'free', tier: 'none');
}

@immutable
class User {
  const User({
    required this.id,
    required this.email,
    this.name = '',
    this.avatarUrl = '',
    this.subscription = UserSubscription.free,
    this.prayerStats = PrayerStats.initial,
  });

  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final UserSubscription subscription;
  final PrayerStats prayerStats;

  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      subscription: json['subscription'] is Map<String, dynamic>
          ? UserSubscription.fromJson(json['subscription'] as Map<String, dynamic>)
          : UserSubscription.free,
      prayerStats: json['prayerStats'] is Map<String, dynamic>
          ? PrayerStats.fromJson(json['prayerStats'] as Map<String, dynamic>)
          : PrayerStats.initial,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatarUrl': avatarUrl,
    'subscription': subscription.toJson(),
    'prayerStats': prayerStats.toJson(),
  };

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    UserSubscription? subscription,
    PrayerStats? prayerStats,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscription: subscription ?? this.subscription,
      prayerStats: prayerStats ?? this.prayerStats,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode => Object.hash(id, email, name, avatarUrl);
}

@immutable
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final User user;
  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
