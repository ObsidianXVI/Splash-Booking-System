part of splash;

Future<void> propagateBookingToMembers(
    List<String> memberCodes, String bookingId,
    [bool creation = true]) async {
  memberCodes[0] = userId;
  for (final String memCode in memberCodes) {
    final doc = await db.collection('codes').doc(memCode).get();
    final newList = (doc.data()!['bookings'] as List).cast<String>();
    if (creation) {
      newList.add(bookingId);
    } else {
      newList.remove(bookingId);
    }
    await doc.reference.update({'bookings': newList});
  }
}

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

bool dateRangesOverlap(
  int startA,
  int endA,
  int startB,
  int endB,
) {
  if (endA <= startB || startA >= endB) {
    return false;
  } else {
    return true;
  }
}
