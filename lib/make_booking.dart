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
                "Do look out for other non-registration games like ACquaslide, Paint Twister, Pose Splasher and Musical Cones!",
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

    for (final a in await DB.getActivities()) {
      activities.add(a);
      slots.add((a.data()!['slots'] as List).cast<String>());
      remaining.add((a.data()!['remaining'] as List).cast<int>());
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
                                            bookingDialog(i);
                                          },
                                          child: const Text("Book This"),
                                        ),
                                      if (hasBeenBooked && isOwnBooking) ...[
                                        TextButton(
                                          style: splashButtonStyle(),
                                          onPressed: () async {
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
                                              level: Level.info,
                                              message:
                                                  "booking.make_booking: Remove booking requested",
                                            );

                                            final bking =
                                                bookings[activities[i].id];
                                            remaining[i][bking!
                                                .data()!['slot']] = remaining[i]
                                                    [bking.data()!['slot']] +
                                                1;
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
                                                  "booking.make_booking: Removed booking successfully",
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
    chosenSlot = widget.oldSlot ?? 0;

    for (int j = 0; j < widget.instance.slots[widget.i].length; j++) {
      bool overlapping = false;
      final bookingEntries = widget.instance.bookings.entries;
      for (int k = 0; k < widget.instance.bookings.length; k++) {
        if (bookingEntries.elementAt(k).value.data()!['activityId'] ==
            widget.activity.id) continue;

        final DateTime dtStartA = dtFrom24H(widget.instance.slots[widget.i][j]);
        if (dateRangesOverlap(
            dtStartA.millisecondsSinceEpoch,
            dtStartA
                .add(Duration(minutes: widget.activity.data()!['slotSize']))
                .millisecondsSinceEpoch,
            widget.instance.bookingStartTimes[k].millisecondsSinceEpoch,
            widget.instance.bookingEndTimes[k].millisecondsSinceEpoch)) {
          overlapping = true;
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
          }
        } else {
          enbled = false;
          reason = 'No slots left';
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

  static Future<Map<String, List<String>>> checkForOverlap(
    String slotStart,
    int slotSize,
    List<String> memCodes, [
    String? activityIdToCheckDup,
  ]) async {
    await loggingService.writeLog(
        level: Level.info,
        message:
            "booking.booking_modal.overlap_checker: START >> slotStart($slotStart), slotSize($slotSize), members($memCodes)");
    final int thisStart = dtFrom24H(slotStart).millisecondsSinceEpoch;
    final int thisEnd = thisStart + slotSize * 60000;
    final List<String> memNames = [];
    final List<String> dupActNames = [];
    memCodes[0] = userId;
    for (final memCode in memCodes) {
      if (memCode == userId) continue;
      final memDoc = await db.collection('codes').doc(memCode).get();
/*         await loggingService.writeLog(
            level: Level.info, message: "OverlapChecker: NCO@513"); */

      if (!memDoc.data()!.containsKey('bookings')) continue;
/*         await loggingService.writeLog(
            level: Level.info, message: "OverlapChecker: NCO@517"); */

      for (final bkId in memDoc.data()!['bookings']) {
/*           await loggingService.writeLog(
              level: Level.info,
              message: "OverlapChecker: Reviewing booking ($bkId)"); */
        final bking = await db.collection('bookings').doc(bkId).get();
/*         await loggingService.writeLog(
            level: Level.info,
            message:
                "OverlapChecker: NCO@521 (${bking.data()}), (${bking.data()?['activityId']}), exists(${bking.exists})");
 */
        final act = await db
            .collection('activities')
            .doc(bking.data()!['activityId'])
            .get();
/*           await loggingService.writeLog(
              level: Level.info,
              message: "OverlapChecker: NCO@530 (${act.data()})"); */
        if (activityIdToCheckDup != null && activityIdToCheckDup == act.id) {
          dupActNames.add(memDoc.data()!['name']);
          await loggingService.writeLog(
            level: Level.info,
            message:
                "booking.booking_modal.overlap_checker: ACT_DUP >> activity($activityIdToCheckDup) for memberCode(${memDoc.id})",
          );
        }
        final DateTime start =
            dtFrom24H(act.data()!['slots'][bking.data()!['slot']]);
/*           await loggingService.writeLog(
              level: Level.info, message: "OverlapChecker: NCO@532"); */

        final DateTime end =
            start.add(Duration(minutes: act.data()!['slotSize']));
        if (dateRangesOverlap(start.millisecondsSinceEpoch,
            end.millisecondsSinceEpoch, thisStart, thisEnd)) {
          await loggingService.writeLog(
            level: Level.info,
            message:
                "booking.booking_modal.overlap_checker: OVERLAP >> activity(${act.id}) for memberCode(${memDoc.id})",
          );
/*           await loggingService.writeLog(
              level: Level.info,
              message:
                  "OverlapChecker: $memCode >> Overlap detected with booking($bkId)"); */
/*             await loggingService.writeLog(
                level: Level.info,
                message: "OverlapChecker: NCO@542 (${memDoc.data()})"); */

          memNames.add(memDoc.data()!['name']);
        } /*  else {
            await loggingService.writeLog(
                level: Level.info,
                message: "OverlapChecker: $memCode >> clear");
          } */
      }
    }
    await loggingService.writeLog(
        level: Level.info,
        message:
            "booking.booking_modal.overlap_checker: END >> ${memNames.length} overlaps ($memNames)");
    return {
      'bookingOverlaps': memNames,
      'activityDuplicates': dupActNames,
    };
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
                          /* await loggingService.writeLog(
                            level: Level.info,
                            message: "mb.550: Modifying booking",
                          ); */
                          final act = widget.instance.activities[widget.i];
                          final List<String> memberCodes = chosenTeam != null
                              ? ((await db
                                          .collection('teams')
                                          .doc(chosenTeam)
                                          .get())
                                      .data()!['members'] as List)
                                  .cast<String>()
                              : [userId];
                          await loggingService.writeLog(
                            level: Level.info,
                            message:
                                "booking.booking_modal.update_button: checking for overlap in activity(${act.id}), slot($chosenSlot), members($memberCodes)",
                          );
                          final overlaps = await checkForOverlap(
                            act.data()!['slots'][chosenSlot],
                            act.data()!['slotSize'] as int,
                            widget.teamSize == 1 ? [userId] : memberCodes,
                            act.id,
                          );

                          if (overlaps['bookingOverlaps']!.isNotEmpty) {
                            setState(() {
                              bottomHint =
                                  "${overlaps['bookingOverlaps']!.length} members (${overlaps['bookingOverlaps']!.join(', ')}) have bookings that overlap with these timings.";
                            });
                            await loggingService.writeLog(
                              level: Level.info,
                              message:
                                  "booking.booking_modal.update_button: Aborting booking due to overlap",
                            );
                            return;
                          } else if (overlaps['activityDuplicates']!
                              .isNotEmpty) {
                            setState(() {
                              bottomHint =
                                  "${overlaps['activityDuplicates']!.length} members (${overlaps['activityDuplicates']!.join(', ')}) have already booked this activity.";
                            });
                            await loggingService.writeLog(
                              level: Level.info,
                              message:
                                  "booking.booking_modal.update_button: Aborting booking due to activity duplicates",
                            );
                            return;
                          } else {
                            setState(() {
                              bottomHint = null;
                            });
                            await loggingService.writeLog(
                              level: Level.info,
                              message:
                                  "booking.booking_modal.update_button: Booking granted",
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
                              level: Level.warning,
                              message:
                                  "booking.booking_modal.update_button: Booking created (${dref.id}) activityId(${act.id}), slot($chosenSlot); propagating to members",
                            );

                            await propagateBookingToMembers(
                                memberCodes, dref.id);
                            await loggingService.writeLog(
                              level: Level.info,
                              message:
                                  "booking.booking_modal.update_button: Booking propagated (${dref.id}) to members($memberCodes)",
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
                              message:
                                  "booking.booking_modal.update_button: Booking updated ($ob) activityId(${act.id}), slot($chosenSlot), team($chosenTeam)",
                            );
                          }
                          await db.collection('activities').doc(act.id).update({
                            'remaining': widget.instance.remaining[widget.i]
                          });
                          await loggingService.writeLog(
                            level: Level.warning,
                            message:
                                "booking.booking_modal.update_button: Activity availability updated (${act.id}), remaining: ${widget.instance.remaining[widget.i]}",
                          );

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
