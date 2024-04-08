part of splash;

class MakeBooking extends StatefulWidget {
  const MakeBooking({super.key});

  @override
  State<StatefulWidget> createState() => MakeBookingState();
}

class MakeBookingState extends State<MakeBooking> {
  bool hasFetched = false;
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> bookings = {};
  final List<DocumentSnapshot<Map<String, dynamic>>> activities = [];

  /// The timestamp name of each slot for each activity
  final List<List<String>> slots = [];

  /// The number of slots remaining for each slot in each activity
  final List<List<int>> remaining = [];

  Future<void> getBookings() async {
    bookings.addEntries([
      for (final b in await DB.getBookings())
        MapEntry(b.data()['activityId'], b)
    ]);
  }

  Future<void> getActivities() async {
    if (hasFetched) return;
    await getBookings();
    for (final a in (await db.collection('activities').get()).docs) {
      activities.add(a);
      slots.add((a.data()['slots'] as List).cast<String>());
      remaining.add((a.data()['remaining'] as List).cast<int>());
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
                              builder: (_) => const MakeBooking()));
                      }
                    },
                    child: Text(oldSlot == null ? "Book" : "Update"),
                  ),
                  if (oldSlot != null)
                    TextButton(
                      onPressed: () async {
                        remaining[i][chosenSlot] += 1;
                        await db
                            .collection('bookings')
                            .doc(activities[i].id)
                            .delete();

                        await db
                            .collection('activities')
                            .doc(activities[i].id)
                            .update({'remaining': remaining[i]});

                        if (mounted) {
                          Navigator.of(context)
                            ..pop()
                            ..push(MaterialPageRoute(
                                builder: (_) => const MakeBooking()));
                        }
                      },
                      child: const Text("Remove booking"),
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
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
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
              return Center(
                child: SizedBox(
                  width: 600,
                  child: ListView.separated(
                    itemBuilder: (ctx, i) {
                      final String actId = activities[i].id;
                      final bool hasBeenBooked = bookings.containsKey(actId);
                      final List<Widget> buttonContent = [
                        if (hasBeenBooked)
                          Text(
                              "Booked for ${slots[i][bookings[actId]!.data()!['slot']]}"),
                        if (!hasBeenBooked)
                          ...List<Text>.generate(slots[i].length, (int sl) {
                            return Text(
                              "${slots[i][sl]}: ${remaining[i][sl]} slots left",
                              textAlign: TextAlign.right,
                            );
                          })
                      ];
                      return Center(
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${activities[i].data()!['name']}",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...buttonContent
                                  // ${slots[i][bookings[activities[i].id]!.data()!['slot']]}
                                  ,
                                ],
                              ),
                              const SizedBox(width: 5),
                              Column(
                                children: [
                                  if (!hasBeenBooked)
                                    TextButton(
                                      onPressed: () => bookingDialog(i),
                                      child: const Text("Book This"),
                                    ),
                                  if (hasBeenBooked)
                                    TextButton(
                                      onPressed: () async {
                                        final b = (await db
                                                .collection('bookings')
                                                .where('userId',
                                                    isEqualTo: userId)
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
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemCount: activities.length,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
