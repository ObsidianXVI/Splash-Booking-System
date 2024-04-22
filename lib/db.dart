part of splash;

typedef JSON = Map<String, dynamic>;

class DB {
  static Future<List<DocumentSnapshot<JSON>>> getBookings() async {
    final List<DocumentSnapshot<JSON>> bks = [];
    for (final bk in (await db.collection('codes').doc(userId).get())
        .data()!['bookings']) {
      bks.add(await db.collection('bookings').doc(bk).get());
    }
    return bks;
  }

  static Future<List<String>> getBookedActivityIds() async {
    return [
      for (final x in await getBookings()) x.data()!['activityId'] as String
    ];
  }

  static Future<List<QueryDocumentSnapshot<JSON>>> getTeams() async {
    return (await db.collection('teams').where('main', isEqualTo: userId).get())
        .docs;
  }

  static Future<DocumentSnapshot<JSON>?> getUserWithCode(
      String bookingCode) async {
    final snapshot = (await db.collection('codes').doc(bookingCode).get());
    return snapshot.exists ? snapshot : null;
  }
}
