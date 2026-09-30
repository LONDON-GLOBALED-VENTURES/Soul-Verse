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

/// Formats the local calendar date as "2024-12-12", as the API expects.
String formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Formats as "12 December 2024".
String formatLongDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
