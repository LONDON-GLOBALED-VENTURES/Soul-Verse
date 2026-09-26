const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Formats as "12 December 2024".
String formatLongDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
