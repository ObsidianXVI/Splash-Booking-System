part of splash;

typedef JSON = Map<String, dynamic>;

class DB {
  static Future<List<QueryDocumentSnapshot<JSON>>> getBookings() async {
    return (await db
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .get())
        .docs;
  }

  static Future<List<String>> getBookedActivityIds() async {
    return [
      for (final x in await getBookings()) x.data()['activityId'] as String
    ];
  }
}
