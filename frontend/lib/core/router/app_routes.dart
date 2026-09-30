abstract final class AppRoutes {
  static const home = '/home';
  static const explore = '/explore';
  static const favourites = '/favourites';
  static const more = '/more';
  static const share = '/share';

  static String moodVerses(String moodId) => '$explore/mood/$moodId';
}
