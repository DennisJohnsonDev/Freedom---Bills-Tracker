import 'package:intl/intl.dart';

/// Formats numbers using the Indian number system (lakhs / crores).
final NumberFormat _inrCompact = NumberFormat.compactCurrency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 1,
);

final NumberFormat _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

final NumberFormat _inrNoSymbol = NumberFormat.decimalPattern('en_IN');

class Money {
  Money._();

  static String inr(num value) => _inr.format(value);
  static String inrCompact(num value) =>
      value >= 100000 ? _inrCompact.format(value) : _inr.format(value);
  static String plain(num value) => _inrNoSymbol.format(value);
}

class Dates {
  Dates._();

  static final _dayShort = DateFormat('d MMM');
  static final _dayLong = DateFormat('d MMM yyyy');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _weekday = DateFormat('EEE');
  static final _fullWeekday = DateFormat('EEEE');

  static String dayShort(DateTime d) => _dayShort.format(d);
  static String dayLong(DateTime d) => _dayLong.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);
  static String weekday(DateTime d) => _weekday.format(d);
  static String fullWeekday(DateTime d) => _fullWeekday.format(d);

  /// "in 3 days" / "tomorrow" / "today" / "2 days ago"
  static String relative(DateTime d, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff == -1) return 'yesterday';
    if (diff > 0 && diff < 7) return 'in $diff days';
    if (diff > 0) return 'in $diff days';
    return '${-diff} days ago';
  }
}
