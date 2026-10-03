import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulverse/features/prayers/data/models/prayer.dart';
import 'package:soulverse/features/prayers/presentation/widgets/create_prayer_dialog.dart';
import 'package:soulverse/features/prayers/presentation/widgets/prayer_card.dart';

void main() {
  group('Prayer Model Tests', () {
    test('SpiritualStatus fromJson and toJson', () {
      final json = {
        'level': 4,
        'title': 'Prayer Warrior',
        'emoji': '⚔️',
        'currentLikes': 55,
        'nextTitle': 'Intercessor',
        'nextThreshold': 100,
        'progress': 0.1,
      };

      final status = SpiritualStatus.fromJson(json);
      expect(status.level, 4);
      expect(status.title, 'Prayer Warrior');
      expect(status.emoji, '⚔️');
      expect(status.currentLikes, 55);
      expect(status.nextTitle, 'Intercessor');
      expect(status.nextThreshold, 100);
      expect(status.progress, 0.1);

      final encoded = status.toJson();
      expect(encoded['level'], 4);
      expect(encoded['title'], 'Prayer Warrior');
    });

    test('PrayerStats initial values and copyWith', () {
      const stats = PrayerStats.initial;
      expect(stats.prayersShared, 0);
      expect(stats.likesReceived, 0);
      expect(stats.status.level, 1);
      expect(stats.status.title, 'Seeker');

      final updated = stats.copyWith(
        likesReceived: 10,
        status: const SpiritualStatus(
          level: 2,
          title: 'Believer',
          emoji: '🕊️',
          currentLikes: 10,
          progress: 0.33,
        ),
      );

      expect(updated.likesReceived, 10);
      expect(updated.status.title, 'Believer');
    });

    test('Prayer fromJson and copyWith', () {
      final json = {
        'id': 'pry_123',
        'authorId': 'usr_456',
        'authorName': 'Grace Walker',
        'authorAvatar': 'https://example.com/avatar.jpg',
        'authorStatusLevel': 'Believer',
        'authorStatusEmoji': '🕊️',
        'isAnonymous': false,
        'title': 'Healing for grandmother',
        'content': 'Please keep my grandmother in your prayers as she recovers.',
        'category': 'Health & Healing',
        'likesCount': 12,
        'isLikedByMe': false,
        'isMine': true,
        'createdAt': '2026-10-02T10:00:00.000Z',
      };

      final prayer = Prayer.fromJson(json);
      expect(prayer.id, 'pry_123');
      expect(prayer.authorName, 'Grace Walker');
      expect(prayer.authorStatusLevel, 'Believer');
      expect(prayer.category, 'Health & Healing');
      expect(prayer.type, 'request');
      expect(prayer.typeBadgeShortLabel, 'Request');
      expect(prayer.likesCount, 12);
      expect(prayer.isLikedByMe, false);
      expect(prayer.isMine, true);

      final toggled = prayer.copyWith(isLikedByMe: true, likesCount: 13, type: 'praise');
      expect(toggled.isLikedByMe, true);
      expect(toggled.likesCount, 13);
      expect(toggled.type, 'praise');
      expect(toggled.typeBadgeShortLabel, 'Praise');
    });
  });

  group('Prayer Widgets Tests', () {
    testWidgets('PrayerCard renders prayer details, badge, and triggers onLike', (tester) async {
      bool liked = false;
      final prayer = Prayer(
        id: 'pry_1',
        authorId: 'usr_1',
        authorName: 'David S.',
        authorStatusLevel: 'Prayer Warrior',
        authorStatusEmoji: '⚔️',
        title: 'Strength during exams',
        content: 'Please pray for peace of mind during university finals.',
        category: 'Guidance & Wisdom',
        type: 'request',
        likesCount: 5,
        isLikedByMe: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerCard(
              prayer: prayer,
              onLike: () {
                liked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Strength during exams'), findsOneWidget);
      expect(find.text('Please pray for peace of mind during university finals.'), findsOneWidget);
      expect(find.text('David S.'), findsOneWidget);
      expect(find.text('⚔️ Prayer Warrior'), findsOneWidget);
      expect(find.text('Guidance & Wisdom'), findsOneWidget);
      expect(find.text('🙏 Request'), findsOneWidget);
      expect(find.text('Amen (5)'), findsOneWidget);

      await tester.tap(find.text('Amen (5)'));
      expect(liked, isTrue);
    });

    testWidgets('CreatePrayerDialog validates inputs before submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreatePrayerDialog(
              onSubmit: ({
                required String title,
                required String content,
                required String category,
                required String type,
                required bool isAnonymous,
              }) async {
                submitted = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Share Prayer Request'), findsOneWidget);

      // Attempt to submit empty form
      final submitFinder = find.text('Post Prayer Request');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('Title must be at least 3 characters'), findsOneWidget);

      // Enter valid title and short content
      await tester.enterText(find.byType(TextFormField).first, 'Need peace');
      await tester.enterText(find.byType(TextFormField).last, 'Short');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('Please provide more details (at least 10 characters)'), findsOneWidget);

      // Enter valid content
      await tester.enterText(
        find.byType(TextFormField).last,
        'Please pray for peace in my family this weekend.',
      );
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
    });
  });
}
