part of splash;

class MakeBooking extends StatefulWidget {
  const MakeBooking({super.key});

  @override
  State<StatefulWidget> createState() => MakeBookingState();
}

class MakeBookingState extends State<MakeBooking> {
  bool hasFetched = false;
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> bookings = {};
  // final List<DocumentSnapshot<JSON>> involvedBookings = [];
  final List<DocumentSnapshot<Map<String, dynamic>>> activities = [];
  final List<DateTime> bookingStartTimes = [];
  final List<DateTime> bookingEndTimes = [];

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
                "Do look out for other non-registration games like ACquaslide, Paint Twister, Pose Splasher, Musical Cones and Dunk N Splash!",
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
    // involvedBookings.clear();
    bookingStartTimes.clear();
    bookingEndTimes.clear();
  }

  Future<void> getBookings() async {
    final bks = await DB.getBookings();
    for (final b in bks) {
      final String actId = b.data()!['activityId'];
      bookings.addEntries([MapEntry(actId, b)]);
      final act = activities.firstWhere((e) => e.id == actId);
      final DateTime start = dtFrom24H(act.data()!['slots'][b.data()!['slot']]);
      bookingStartTimes.add(start);
      bookingEndTimes
          .add(start.add(Duration(minutes: act.data()!['slotSize'])));
    }

    /* involvedBookings.addAll(
        (await db.collection('codes').doc(userId).get()).data()!['bookings']); */
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

    for (final a in (await db.collection('activities').get()).docs) {
      activities.add(a);
      slots.add((a.data()['slots'] as List).cast<String>());
      remaining.add((a.data()['remaining'] as List).cast<int>());
    }
    await getBookings();

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
    final List<List<String>> memberNames = [];
    for (final tm in t) {
      final List<String> tmp = [];
      for (final mmbr in tm.data()!['members']) {
        tmp.add((await db.collection('codes').doc(mmbr).get()).data()!['name']);
      }
      memberNames.add(tmp);
    }
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
          activityId: activities[i].id,
          memberNames: memberNames,
        ),
      );
    }

    resetState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 200,
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
                          final int ts =
                              activities[i].data()!['teamSize'] as int;
                          final String teamSizeLabel =
                              ts == 1 ? "Individual" : "$ts per team";
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
                                      if (hasBeenBooked) ...[
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
                                        const SizedBox(height: 10),
                                        TextButton(
                                          style: splashButtonStyle(),
                                          onPressed: () async {
                                            final bking =
                                                bookings[activities[i].id];
                                            remaining[i]
                                                [bking!.data()!['slot']] += 1;
                                            await db
                                                .collection('bookings')
                                                .doc(bookings[activities[i].id]!
                                                    .id)
                                                .delete();

                                            await db
                                                .collection('activities')
                                                .doc(activities[i].id)
                                                .update({
                                              'remaining': remaining[i]
                                            });
                                            final String? teamId =
                                                bking.data()!['teamId'];
                                            await propagateBookingToMembers(
                                              teamId != null
                                                  ? ((await db
                                                                  .collection(
                                                                      'teams')
                                                                  .doc(teamId)
                                                                  .get())
                                                              .data()![
                                                          'members'] as List)
                                                      .cast<String>()
                                                  : [userId],
                                              bking.id,
                                              false,
                                            );
                                            bookings.remove(activities[i].id);
                                            hasFetched = true;
                                            setState(() {});
                                          },
                                          child: const Text("Remove booking"),
                                        ),
                                      ],
                                      Text(
                                        teamSizeLabel,
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
                        separatorBuilder: (_, __) => const SizedBox(height: 30),
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
  final String activityId;
  final List<List<String>> memberNames;

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
    required this.activityId,
    required this.memberNames,
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
  String? bottomHint;

  @override
  void initState() {
    chosenSlot = widget.oldSlot ?? 0;
    for (int j = 0; j < widget.instance.slots[widget.i].length; j++) {
      bool overlapping = false;
      for (int k = 0; k < widget.instance.bookings.length; k++) {
        if (widget.instance.bookings.entries
                .elementAt(k)
                .value
                .data()!['activityId'] ==
            widget.activityId) continue;
        if (dtFrom24H(widget.instance.slots[widget.i][j]).isBetweenOrOn(
            widget.instance.bookingStartTimes[k],
            widget.instance.bookingEndTimes[k])) {
          overlapping = true;
          break;
        }
      }
      final bool enbled;
      if (widget.oldSlot != null && widget.oldSlot == j) {
        enbled = true;
      } else {
        enbled = widget.instance.remaining[widget.i][j] > 0 && !overlapping;
      }

      items.add(
        DropdownMenuItem<int>(
          value: j,
          enabled: enbled,
          child: Text(
            widget.instance.slots[widget.i][j],
            style: TextStyle(
              color: enbled ? yellow : yellow.withOpacity(0.4),
            ),
          ),
        ),
      );
    }
    if (widget.teamSize > 1) {
      if (widget.possibleTeams.isNotEmpty) {
        chosenTeam = widget.oldTeamId ?? widget.possibleTeams.first.id;
      }

      for (int k = 0; k < widget.possibleTeams.length; k++) {
        teamItems.add(
          DropdownMenuItem<String>(
            value: widget.possibleTeams[k].id,
            child: Text(
              widget.memberNames[k].join(', '),
            ),
          ),
        );
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> teamSelectWidgets = [];
    if (widget.teamSize > 1) {
      teamSelectWidgets.addAll([
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
      ]);
    }

    Future<List<String>> checkForOverlap(
        String slotStart, int slotSize, List<String> memCodes) async {
      final int thisStart = dtFrom24H(slotStart).millisecondsSinceEpoch;
      final int thisEnd = thisStart + slotSize * 60000;
      final List<String> memNames = [];
      memCodes[0] = userId;
      for (final memCode in memCodes) {
        if (memCode == userId) continue;
        final memDoc = await db.collection('codes').doc(memCode).get();
        for (final bkId in memDoc.data()!['bookings']) {
          final bking = await db.collection('bookings').doc(bkId).get();
          final act = await db
              .collection('activities')
              .doc(bking.data()!['activityId'])
              .get();
          final DateTime start =
              dtFrom24H(act.data()!['slots'][bking.data()!['slot']]);
          final DateTime end =
              start.add(Duration(minutes: act.data()!['slotSize']));
          if (dateRangesOverlap(start.millisecondsSinceEpoch,
              end.millisecondsSinceEpoch, thisStart, thisEnd)) {
            memNames.add(memDoc.data()!['name']);
          }
        }
      }

      return memNames;
    }

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
              value: items[chosenSlot].enabled ? chosenSlot : null,
              items: items,
              onChanged: (x) => chosenSlot = x ?? chosenSlot,
            ),
            if (widget.teamSize > 1) ...teamSelectWidgets,
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  style: splashButtonStyle(),
                  onPressed: (widget.teamSize == 1 || chosenTeam != null)
                      ? () async {
                          final act = widget.instance.activities[widget.i];
                          final List<String> memberCodes = chosenTeam != null
                              ? ((await db
                                          .collection('teams')
                                          .doc(chosenTeam)
                                          .get())
                                      .data()!['members'] as List)
                                  .cast<String>()
                              : [userId];
                          final overlaps = await checkForOverlap(
                            act.data()!['slots'][chosenSlot],
                            act.data()!['slotSize'] as int,
                            widget.teamSize == 1 ? [userId] : memberCodes,
                          );

                          if (overlaps.isNotEmpty) {
                            setState(() {
                              bottomHint =
                                  "${overlaps.length} members (${overlaps.join(', ')}) have bookings that overlap with these timings.";
                            });
                            return;
                          } else {
                            setState(() {
                              bottomHint = null;
                            });
                          }

                          if (widget.oldSlot == null) {
                            widget.instance.remaining[widget.i][chosenSlot] -=
                                1;

                            final dref = await db.collection('bookings').add({
                              'userId': userId,
                              'activityId': act.id,
                              'slot': chosenSlot,
                              if (widget.teamSize > 1) 'teamId': chosenTeam,
                            });
                            await propagateBookingToMembers(
                                memberCodes, dref.id);
                          } else {
                            widget.instance.remaining[widget.i][chosenSlot] -=
                                1;
                            widget.instance.remaining[widget.i]
                                [widget.oldSlot!] += 1;
                            final ob =
                                await widget.instance.oldBookingId(widget.i);
                            await db.collection('bookings').doc(ob).update({
                              'slot': chosenSlot,
                              if (widget.teamSize > 1) 'teamId': chosenTeam,
                            });
                          }
                          await db.collection('activities').doc(act.id).update({
                            'remaining': widget.instance.remaining[widget.i]
                          });

                          dismiss(context);
                        }
                      : null,
                  child: Text(widget.oldSlot == null ? "Book" : "Update"),
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
            if (bottomHint != null)
              Text(
                bottomHint!,
                style: const TextStyle(color: red),
              ),
          ],
        ),
      ),
    );
  }
}
