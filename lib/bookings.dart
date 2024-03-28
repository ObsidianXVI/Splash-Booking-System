part of splash;

class ViewBookings extends StatefulWidget {
  const ViewBookings({super.key});

  @override
  State<StatefulWidget> createState() => ViewBookingsState();
}

class ViewBookingsState extends State<ViewBookings> {
  bool hasFetched = false;
  final List<int> slots = [];
  final List<DocumentSnapshot<Map<String, dynamic>>> activities = [];

  Future<void> getBookings() async {
    if (hasFetched) return;
    final bookings = (await db
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .get())
        .docs;
    for (final booking in bookings) {
      final activity = await getActivity(booking.data()['activityId']);
      activities.add(activity);
      slots.add(booking.data()['slot']);
    }
    hasFetched = true;
    return;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getActivity(
      String activityId) async {
    return await db.collection('activities').doc(activityId).get();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              width: 100,
              height: 100,
              child: const CircularProgressIndicator(),
            ),
          );
        } else {
          if (activities.isEmpty) return const Text("No bookings!");
          return ListView.separated(
            itemBuilder: (ctx, i) {
              return Container(
                child: Column(
                  children: [
                    Text("Name: ${activities[i].data()!['name']}"),
                    Text(
                        "Slot: ${(activities[i].data()!['slots'] as List)[slots[i]]}"),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemCount: activities.length,
          );
        }
      },
    );
  }
}
