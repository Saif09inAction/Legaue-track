import 'package:intl/intl.dart';

/// Kickoff labels for fixtures. Locale is fixed so the wording does not
/// change with the device language.
abstract final class DateFormatters {
  static final DateFormat _kickoff = DateFormat('EEE d MMM y, HH:mm', 'en_US');
  static final DateFormat _date = DateFormat('EEE d MMM y', 'en_US');
  static final DateFormat _matchDay = DateFormat('EEEE d MMMM', 'en_US');
  static final DateFormat _time = DateFormat('HH:mm', 'en_US');
  static final DateFormat _updated = DateFormat('d MMM, HH:mm', 'en_US');

  static String formatKickoff(DateTime dateTime) => _kickoff.format(dateTime);

  static String formatDate(DateTime dateTime) => _date.format(dateTime);

  static String formatMatchDay(DateTime dateTime) => _matchDay.format(dateTime);

  static String formatTime(DateTime dateTime) => _time.format(dateTime);

  static String formatUpdated(DateTime dateTime) => _updated.format(dateTime);
}
