part of splash;

class MakeBooking extends StatefulWidget {
  const MakeBooking({super.key});

  @override
  State<StatefulWidget> createState() => MakeBookingState();
}

class MakeBookingState extends State<MakeBooking> {
  bool hasFetched = false;
  final List<DocumentSnapshot<Map<String, dynamic>>> activities = [];
  final List<List<String>> slots = [];
  final List<List<int>> remaining = [];
  final List<bool> hasBookedBefore = [];

  Future<List<String>> getBookedActivities() async {
    return [
      for (final x in (await db
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .get())
          .docs)
        x.data()['activityId'] as String
    ];
  }

  Future<void> getActivities() async {
    if (hasFetched) return;
    final booked = await getBookedActivities();
    int i = 0;
    for (final a in (await db.collection('activities').get()).docs) {
      activities.add(a);
      slots.add((a.data()['slots'] as List).cast<String>());
      remaining.add((a.data()['remaining'] as List).cast<int>());
      hasBookedBefore.add(booked.contains(a.id));
      i += 1;
    }
    hasFetched = true;
    return;
  }

  Future<String> oldBookingId(int i) async {
    final x = (await db
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .where('activityId', isEqualTo: activities[i].id)
            .get())
        .docs
        .first
        .id;
    return x;
  }

  Future<void> bookingDialog(int i, [int? oldSlot]) async {
    final List<DropdownMenuItem<int>> items = [];
    int chosenSlot = oldSlot ?? 0;
    for (int j = 0; j < slots[i].length; j++) {
      items.add(
        DropdownMenuItem<int>(
          value: j,
          enabled: remaining[i][j] > 0,
          child: Text(slots[i][j]),
        ),
      );
    }
    await showDialog(
      context: context,
      builder: (c) => Material(
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(oldSlot == null ? "Book Activity" : "Update Booking"),
              const SizedBox(height: 50),
              const Text("Select a slot:"),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: chosenSlot,
                items: items,
                onChanged: (x) => chosenSlot = x ?? chosenSlot,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      if (oldSlot == null) {
                        remaining[i][chosenSlot] -= 1;

                        await db.collection('bookings').add({
                          'userId': userId,
                          'activityId': activities[i].id,
                          'slot': chosenSlot,
                        });
                      } else {
                        remaining[i][chosenSlot] -= 1;
                        remaining[i][oldSlot] += 1;
                        final ob = await oldBookingId(i);
                        await db
                            .collection('bookings')
                            .doc(ob)
                            .update({'slot': chosenSlot});
                      }
                      await db
                          .collection('activities')
                          .doc(activities[i].id)
                          .update({'remaining': remaining[i]});

                      if (mounted) {
                        Navigator.of(context)
                          ..pop()
                          ..push(MaterialPageRoute(
                              builder: (_) => const ViewBookings()));
                      }
                    },
                    child: Text(oldSlot == null ? "Book" : "Update"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FutureBuilder(
        future: getActivities(),
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
            if (activities.isEmpty) return const Text("No activities!");
            return ListView.separated(
              itemBuilder: (ctx, i) {
                return Center(
                  child: Container(
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text("Name: ${activities[i].data()!['name']}"),
                            if (hasBookedBefore[i])
                              const Text("Already booked"),
                            if (!hasBookedBefore[i])
                              ...List<Text>.generate(slots[i].length, (int sl) {
                                return Text(
                                    "${slots[i][sl]}: ${remaining[i][sl]} slots left");
                              }),
                          ],
                        ),
                        Column(
                          children: [
                            if (!hasBookedBefore[i])
                              TextButton(
                                onPressed: () => bookingDialog(i),
                                child: const Text("Book This"),
                              ),
                            if (hasBookedBefore[i])
                              TextButton(
                                onPressed: () async {
                                  final b = (await db
                                          .collection('bookings')
                                          .where('userId', isEqualTo: userId)
                                          .where('activityId',
                                              isEqualTo: activities[i].id)
                                          .get())
                                      .docs
                                      .first;
                                  bookingDialog(i, b.data()['slot']);
                                },
                                child: const Text("Edit booking"),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 5),
              itemCount: activities.length,
            );
          }
        },
      ),
    );
  }
}

class ActivityBookingForm extends StatefulWidget {
  const ActivityBookingForm({super.key});

  @override
  State<StatefulWidget> createState() => ActivityBookingFormState();
}

class ActivityBookingFormState extends State<ActivityBookingForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          const Text("Activiy Booking"),
          DropdownButtonFormField(
            items: [],
            onChanged: (x) {},
          ),
        ],
      ),
    );
  }
}
