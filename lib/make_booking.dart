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
                return Container(
                  child: TextButton(
                    onPressed: hasBookedBefore[i]
                        ? () {}
                        : () async {
                            final List<DropdownMenuItem<int>> items = [];
                            int chosenSlot = 0;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Activiy Booking"),
                                      const SizedBox(height: 50),
                                      const Text("Select a slot:"),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField(
                                        value: 0,
                                        items: items,
                                        onChanged: (x) =>
                                            chosenSlot = x ?? chosenSlot,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () async {
                                              remaining[i][chosenSlot] -= 1;
                                              await db
                                                  .collection('activities')
                                                  .doc(activities[i].id)
                                                  .update({
                                                'remaining': remaining[i]
                                              });
                                              await db
                                                  .collection('bookings')
                                                  .add({
                                                'userId': userId,
                                                'activityId': activities[i].id,
                                                'slot': chosenSlot,
                                              });

                                              if (mounted) {
                                                Navigator.of(context)
                                                  ..pop()
                                                  ..push(MaterialPageRoute(
                                                      builder: (_) =>
                                                          const ViewBookings()));
                                              }
                                            },
                                            child: const Text("Book"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text("Cancel"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                    child: Column(
                      children: [
                        Text("Name: ${activities[i].data()!['name']}"),
                        if (hasBookedBefore[i]) const Text("Already booked"),
                        if (!hasBookedBefore[i])
                          ...List<Text>.generate(slots[i].length, (int sl) {
                            return Text(
                                "${slots[i][sl]}: ${remaining[i][sl]} slots left");
                          }),
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
