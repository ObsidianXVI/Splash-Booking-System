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

  void resetState() {
    hasFetched = false;
    bookings.clear();
    activities.clear();
    slots.clear();
    remaining.clear();
  }

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
    await showDialog(
      context: context,
      builder: (_) => ManageBookingModal(
        i: i,
        oldSlot: oldSlot,
        instance: this,
        returnValue: (_) {},
      ),
    );
    setState(() {
      resetState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 100,
            child: Image.asset(
              'images/acsplash_white.png',
              width: MediaQuery.of(context).size.width * 0.7,
              opacity: const AlwaysStoppedAnimation(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: FutureBuilder(
              future: getActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(color: red),
                    ),
                  );
                } else {
                  if (activities.isEmpty) {
                    return const Center(
                      child: Text("No activities!"),
                    );
                  }
                  return Center(
                    child: SizedBox(
                      width: 600,
                      child: ListView.separated(
                        itemBuilder: (ctx, i) {
                          final String actId = activities[i].id;
                          final bool hasBeenBooked =
                              bookings.containsKey(actId);
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
                                          style: splashButtonStyle(),
                                          onPressed: () => bookingDialog(i),
                                          child: const Text("Book This"),
                                        ),
                                      if (hasBeenBooked)
                                        TextButton(
                                          style: splashButtonStyle(),
                                          onPressed: () async {
                                            final b = (await db
                                                    .collection('bookings')
                                                    .where('userId',
                                                        isEqualTo: userId)
                                                    .where('activityId',
                                                        isEqualTo:
                                                            activities[i].id)
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
        ],
      ),
    );
  }
}

class ManageBookingModal extends ModalView<void> {
  final int? oldSlot;
  final int i;
  final MakeBookingState instance;

  const ManageBookingModal({
    required this.i,
    required this.oldSlot,
    required this.instance,
    required super.returnValue,
    super.key,
  }) : super(title: 'Manage Booking');

  @override
  ModalViewState createState() => ManageBookingModalState();
}

class ManageBookingModalState extends ModalViewState<ManageBookingModal> {
  final List<DropdownMenuItem<int>> items = [];
  late int chosenSlot;

  @override
  void initState() {
    chosenSlot = widget.oldSlot ?? 0;
    for (int j = 0; j < widget.instance.slots[widget.i].length; j++) {
      items.add(
        DropdownMenuItem<int>(
          value: j,
          enabled: widget.instance.remaining[widget.i][j] > 0,
          child: Text(widget.instance.slots[widget.i][j]),
        ),
      );
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return modalScaffold(
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  style: splashButtonStyle(),
                  onPressed: () async {
                    if (widget.oldSlot == null) {
                      widget.instance.remaining[widget.i][chosenSlot] -= 1;

                      await db.collection('bookings').add({
                        'userId': userId,
                        'activityId': widget.instance.activities[widget.i].id,
                        'slot': chosenSlot,
                      });
                    } else {
                      widget.instance.remaining[widget.i][chosenSlot] -= 1;
                      widget.instance.remaining[widget.i][widget.oldSlot!] += 1;
                      final ob = await widget.instance.oldBookingId(widget.i);
                      await db
                          .collection('bookings')
                          .doc(ob)
                          .update({'slot': chosenSlot});
                    }
                    await db
                        .collection('activities')
                        .doc(widget.instance.activities[widget.i].id)
                        .update(
                            {'remaining': widget.instance.remaining[widget.i]});

                    dismiss(context);
                  },
                  child: Text(widget.oldSlot == null ? "Book" : "Update"),
                ),
                if (widget.oldSlot != null)
                  TextButton(
                    style: splashButtonStyle(),
                    onPressed: () async {
                      widget.instance.remaining[widget.i][chosenSlot] += 1;
                      await db
                          .collection('bookings')
                          .doc(widget
                              .instance
                              .bookings[
                                  widget.instance.activities[widget.i].id]!
                              .id)
                          .delete();

                      await db
                          .collection('activities')
                          .doc(widget.instance.activities[widget.i].id)
                          .update({
                        'remaining': widget.instance.remaining[widget.i]
                      });

                      dismiss(context);
                    },
                    child: const Text("Remove booking"),
                  ),
                TextButton(
                  style: splashButtonStyle(),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
