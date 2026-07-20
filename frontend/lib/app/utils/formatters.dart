import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String date(DateTime value) => DateFormat('MMM d, yyyy').format(value);

  static String dateTime(DateTime value) =>
      DateFormat('MMM d, yyyy · h:mm a').format(value);

  static String relative(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(value);
  }

  static String currency(num amount, {String symbol = '\$'}) =>
      NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);

  static String percentage(num value) => '${value.round()}%';

  static String skillScore(num value) => '${value.round()} / 100';
}
