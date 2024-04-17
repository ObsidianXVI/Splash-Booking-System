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

  @override
  void initState() {
    if (!shownNonRegPromo) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 6),
              content: Text(
                "Do look out for other non-registration games like Slip N Slide, Paint Twister, Pose Splasher, Musical Cones and Dunk N Splash!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          shownNonRegPromo = true;
        }
      });
    }
    super.initState();
  }

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

  Future<List<DocumentSnapshot<JSON>>> getTeams(int minMemberCount) async {
    final List<DocumentSnapshot<JSON>> possibleTeams = [];
    final teams = await DB.getTeams();
    for (int i = 0; i < teams.length; i++) {
      if ((teams[i].data()['members'] as List).length == minMemberCount) {
        possibleTeams.add(teams[i]);
      }
    }
    return possibleTeams;
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

  Future<void> bookingDialog(int i, [int? oldSlot, String? oldTeamId]) async {
    final tsize = activities[i].data()!['teamSize'];
    final t = await getTeams(tsize);
    if (mounted) {
      await showDialog(
        context: context,
        builder: (_) => ManageBookingModal(
          i: i,
          oldSlot: oldSlot,
          oldTeamId: oldTeamId,
          instance: this,
          possibleTeams: t,
          teamSize: tsize,
          activityName: activities[i].data()!['name'],
          activityDesc: activities[i].data()!['description'],
          disclaimer: activities[i].data()!['disclaimer'],
        ),
      );
    }
    setState(() {
      resetState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                                      ...buttonContent,
                                    ],
                                  ),
                                  const SizedBox(width: 10),
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
                                      Text(
                                        "${activities[i].data()!['teamSize']} per team",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: yellow.withOpacity(0.6),
                                          fontStyle: FontStyle.italic,
                                        ),
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

class ManageBookingModal extends ModalView {
  final int? oldSlot;
  final int i;
  final List<DocumentSnapshot<JSON>> possibleTeams;
  final MakeBookingState instance;
  final int teamSize;
  final String? oldTeamId;
  final String activityName;
  final String activityDesc;
  final String? disclaimer;

  const ManageBookingModal({
    required this.i,
    required this.oldSlot,
    required this.oldTeamId,
    required this.instance,
    required this.possibleTeams,
    required this.teamSize,
    required this.activityName,
    required this.activityDesc,
    required this.disclaimer,
    super.key,
  }) : super(title: 'Manage Booking');

  @override
  ModalViewState createState() => ManageBookingModalState();
}

class ManageBookingModalState extends ModalViewState<ManageBookingModal> {
  final List<DropdownMenuItem<int>> items = [];
  final List<DropdownMenuItem<String>> teamItems = [];
  late int chosenSlot;
  String? chosenTeam;

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
    if (widget.possibleTeams.isNotEmpty) {
      chosenTeam = widget.oldTeamId ?? widget.possibleTeams.first.id;
    }

    for (int k = 0; k < widget.possibleTeams.length; k++) {
      teamItems.add(
        DropdownMenuItem<String>(
          value: widget.possibleTeams[k].id,
          child: Text(
            (widget.possibleTeams[k].data()!['members'] as List).join(', '),
          ),
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
            Text(
              widget.activityName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.activityDesc,
            ),
            const SizedBox(height: 40),
            const Text("Select a slot:"),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: chosenSlot,
              items: items,
              onChanged: (x) => chosenSlot = x ?? chosenSlot,
            ),
            const SizedBox(height: 20),
            const Text("Select a team:"),
            const SizedBox(height: 10),
            if (widget.possibleTeams.isEmpty)
              Text(
                  "You do not currently have teams with exactly ${widget.teamSize} members. Create one using the Manage Teams tab, and then try booking this activity."),
            if (widget.possibleTeams.isNotEmpty)
              DropdownButtonFormField<String>(
                value: teamItems.first.value,
                items: teamItems,
                onChanged: (x) => chosenTeam = x ?? chosenTeam,
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  style: splashButtonStyle(),
                  onPressed: chosenTeam != null
                      ? () async {
                          if (widget.oldSlot == null) {
                            widget.instance.remaining[widget.i][chosenSlot] -=
                                1;

                            await db.collection('bookings').add({
                              'userId': userId,
                              'activityId':
                                  widget.instance.activities[widget.i].id,
                              'slot': chosenSlot,
                              'teamId': chosenTeam,
                            });
                          } else {
                            widget.instance.remaining[widget.i][chosenSlot] -=
                                1;
                            widget.instance.remaining[widget.i]
                                [widget.oldSlot!] += 1;
                            final ob =
                                await widget.instance.oldBookingId(widget.i);
                            await db.collection('bookings').doc(ob).update({
                              'slot': chosenSlot,
                              'teamId': chosenTeam,
                            });
                          }
                          await db
                              .collection('activities')
                              .doc(widget.instance.activities[widget.i].id)
                              .update({
                            'remaining': widget.instance.remaining[widget.i]
                          });

                          dismiss(context);
                        }
                      : null,
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
            const SizedBox(height: 40),
            if (widget.disclaimer != null)
              Text("Disclaimer: ${widget.disclaimer}"),
          ],
        ),
      ),
    );
  }
}
