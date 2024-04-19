part of splash;

DateTime dtFrom24H(String timestamp) {
  final List<String> chunks = timestamp.split(':');
  return DateTime(2024, 5, 1, int.parse(chunks[0]), int.parse(chunks[1]));
}

String timestampFromDt(DateTime dt) {
  return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
}

extension DateTimeUtils on DateTime {
  bool isBetweenOrOn(DateTime a, DateTime b) =>
      ((isAfter(a) && isBefore(b)) || this == a || this == b);
}
