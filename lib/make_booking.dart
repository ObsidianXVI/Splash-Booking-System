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
          disclaimer: activities[i].data()!['disclaimer'],
          activity: activities[i],
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
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'images/acsplash_white.png',
                width: MediaQuery.of(context).size.width * 0.7,
              ),
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
                          final bool isOwnBooking = hasBeenBooked
                              ? bookings[actId]!.data()!['userId'] == userId
                              : false;
                          final List<Widget> buttonContent = [
                            if (hasBeenBooked)
                              Text(
                                  "Booked ${isOwnBooking ? '' : "by team"} for ${slots[i][bookings[actId]!.data()!['slot']]}"),
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
                                          onPressed: () async {
                                            await loggingService.writeLog(
                                              level: Level.info,
                                              message:
                                                  "mb.226: Create booking requested",
                                            );

                                            bookingDialog(i);
                                          },
                                          child: const Text("Book This"),
                                        ),
                                      if (hasBeenBooked && isOwnBooking) ...[
                                        TextButton(
                                          style: splashButtonStyle(),
                                          onPressed: () async {
                                            await loggingService.writeLog(
                                              level: Level.info,
                                              message:
                                                  "mb.236: Edit booking requested",
                                            );
                                            await loggingService.writeLog(
                                              level: Level.info,
                                              message:
                                                  "Looking for booking of activity (${activities[i].id})",
                                            );
                                            final b =
                                                bookings[activities[i].id]!;

                                            await bookingDialog(
                                                i, b.data()!['slot']);
                                          },
                                          child: const Text("Edit booking"),
                                        ),
                                        const SizedBox(height: 10),
                                        TextButton(
                                          style: splashButtonStyle(),
                                          onPressed: () async {
                                            await loggingService.writeLog(
                                              level: Level.warning,
                                              message:
                                                  "mb.256: Remove booking requested",
                                            );

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
                                            await loggingService.writeLog(
                                              level: Level.info,
                                              message:
                                                  "mb.293: Removed booking",
                                            );
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
  final DocumentSnapshot<JSON> activity;
  final String? disclaimer;
  final List<List<String>> memberNames;

  const ManageBookingModal({
    required this.i,
    required this.oldSlot,
    required this.oldTeamId,
    required this.instance,
    required this.possibleTeams,
    required this.teamSize,
    required this.activity,
    required this.disclaimer,
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
    loggingService.writeLog(
      level: Level.info,
      message:
          "Showing BookingModal for activity (${widget.activity.id}) (${widget.activity.data()!['name']})",
    );

    chosenSlot = widget.oldSlot ?? 0;

    /**
     * for each slot, iterate over bookings
     * check if each booking's start time and end time overlap with this slot's start and end
     */

    for (int j = 0; j < widget.instance.slots[widget.i].length; j++) {
      bool overlapping = false;
      final bookingEntries = widget.instance.bookings.entries;
      for (int k = 0; k < widget.instance.bookings.length; k++) {
        if (bookingEntries.elementAt(k).value.data()!['activityId'] ==
            widget.activity.id) continue;
        if (dtFrom24H(widget.instance.slots[widget.i][j]).isBetweenOrOn(
                widget.instance.bookingStartTimes[k],
                widget.instance.bookingEndTimes[k]) ||
            dtFrom24H(widget.instance.slots[widget.i][j])
                .add(Duration(minutes: widget.activity.data()!['slotSize']))
                .isBetweenOrOn(widget.instance.bookingStartTimes[k],
                    widget.instance.bookingEndTimes[k])) {
          overlapping = true;
          loggingService.writeLog(
            level: Level.info,
            message:
                "mb.383: Overlaps with booking(${widget.instance.bookings.entries.elementAt(k).value.id})",
          );
          break;
        }
      }

      String? reason;
      final bool enbled;
      // there is a previous booking, and this slot is that previously booked one
      if (widget.oldSlot != null && widget.oldSlot == j) {
        enbled = true;
      } else {
        // there are remaining slots
        if (widget.instance.remaining[widget.i][j] > 0) {
          // there is no overlap
          if (!overlapping) {
            enbled = true;
          } else {
            enbled = false;
            reason = 'Overlaps with an existing booking';
            loggingService.writeLog(
              level: Level.warning,
              message: "mb.396: Disabled option $j >> Overlapping",
            );
          }
        } else {
          enbled = false;
          reason = 'No slots left';
          loggingService.writeLog(
            level: Level.warning,
            message: "mb.400: Disabled option $j >> No slots left",
          );
        }
      }

      items.add(
        DropdownMenuItem<int>(
          value: j,
          enabled: enbled,
          child: Text(
            widget.instance.slots[widget.i][j] +
                (reason != null ? ' ($reason)' : ''),
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
        if (!memDoc.data()!.containsKey('bookings')) continue;
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
              widget.activity.data()!['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.activity.data()!['description'],
            ),
            const SizedBox(height: 40),
            if (bottomHint != null)
              Text(
                bottomHint!,
                style: const TextStyle(color: red),
              ),
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
                          await loggingService.writeLog(
                            level: Level.info,
                            message: "mb.550: Modifying booking",
                          );
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
                            await loggingService.writeLog(
                              level: Level.warning,
                              message: "mb.517: Overlaps with $overlaps",
                            );
                            setState(() {
                              bottomHint =
                                  "${overlaps.length} members (${overlaps.join(', ')}) have bookings that overlap with these timings.";
                            });
                            await loggingService.writeLog(
                              level: Level.warning,
                              message:
                                  "mb.531: Aborting booking due to overlap",
                            );
                            return;
                          } else {
                            setState(() {
                              bottomHint = null;
                            });
                            await loggingService.writeLog(
                              level: Level.warning,
                              message: "mb.537: booking resumed",
                            );
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
                            await loggingService.writeLog(
                              level: Level.info,
                              message: "mb.539: Booking created in DB",
                            );
                            await propagateBookingToMembers(
                                memberCodes, dref.id);
                            await loggingService.writeLog(
                              level: Level.info,
                              message: "mb.542: Booking propagated to members",
                            );
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
                            await loggingService.writeLog(
                              level: Level.warning,
                              message: "mb.554: Booking updated in DB",
                            );
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
          ],
        ),
      ),
    );
  }
}
