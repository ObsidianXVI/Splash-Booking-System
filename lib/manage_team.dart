part of splash;

class ManageTeam extends StatefulWidget {
  const ManageTeam({super.key});

  @override
  State<StatefulWidget> createState() => ManageTeamState();
}

class ManageTeamState extends State<ManageTeam> {
  bool hasFetched = false;

  final Map<String, String> activityNames = {};

  /// Maps a teamId to a bookingId
  final Map<String, String> bookings = {};

  /// Maps a teamId to team data
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> teamData = {};

  /// Maps a teamId to updated team data
  final Map<String, Map<String, dynamic>> updatedTeamData = {};

  /// Maps a bookingId to booking data
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> bookingData = {};

  /// Maps a teamId to member names
  final Map<String, List<String>> membersNames = {};

  Future<void> resetState() async {
    hasFetched = false;
    bookings.clear();
    activityNames.clear();
    updatedTeamData.clear();
    membersNames.clear();
    await getTeams();
  }

  Future<void> getTeams() async {
    if (hasFetched) return;

    // bookings under this user
    final bkData = await DB.getBookings();

    for (final bk in bkData) {
      // update the map of teamIds and booking ids
      if (bk.data()!.containsKey('teamId')) {
        bookings[bk.data()!['teamId']] = bk.id;
        bookingData[bk.id] = bk;
      }

      // create a map of activity id to activity name
      activityNames[bk.id] = ((await db
              .collection('activities')
              .doc(bk.data()!['activityId'])
              .get())
          .data()!['name']);
    }

    // teams under this user
    for (final te in await DB.getTeams()) {
      teamData[te.id] = te;

      membersNames[te.id] = [
        for (final mc in te.data()['members'])
          ((await db.collection('codes').doc(mc).get()).data()!['name'])
      ];
    }

    hasFetched = true;
  }

/*   Future<List<String>> getTeamDataFor(String id) async {
    final List<String> memNames = [];
    final List<String> memCodes = updatedTeamData.containsKey(id)
        ? updatedTeamData[id]!['members']
        : teamData[id]!.data()!['members']!;
    for (final mc in memCodes) {
      memNames
          .add((await db.collection('codes').doc(mc).get()).data()!['name']);
    }
    return memNames;
  } */

  Future<void> editTeamDialog(
    DocumentSnapshot<Map<String, dynamic>>? booking,
    DocumentSnapshot<Map<String, dynamic>>? tData,
    bool hasBooking,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => EditTeamMembersModal(
        booking: booking,
        teamData: tData,
        hasBooking: hasBooking,
        memberNames: membersNames[tData!.id]!,
        viewState: this,
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
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
              future: getTeams(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    children: [
                      Text(
                          "View and manage the teams that you are a leader of."),
                      SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],
                  );
                } else {
                  final List<Widget> items = [];
                  for (int i = 0; i < teamData.length; i++) {
                    final String tid = teamData.keys.elementAt(i);
                    bool hasBooking = bookings.containsKey(tid);
                    items.addAll([
                      Center(
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (hasBooking)
                                    Text(
                                      activityNames[bookings[tid]]!,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  Text(membersNames[tid]!.join(', ')),
                                ],
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                style: splashButtonStyle(),
                                onPressed: () => editTeamDialog(
                                  bookingData[bookings[tid]],
                                  teamData[tid],
                                  hasBooking,
                                ),
                                child: const Text("Edit Team"),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ]);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: 20, right: 40),
                    child: SingleChildScrollView(
                      child: Center(
                        child: Column(
                          children: [
                            if (teamData.isEmpty)
                              const Text("No teams!")
                            else
                              ...items,
                            const SizedBox(height: 60),
                            TextButton(
                              style: splashButtonStyle(),
                              onPressed: () async {
                                if (mounted) {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => EditTeamMembersModal(
                                      booking: null,
                                      teamData: null,
                                      hasBooking: false,
                                      viewState: this,
                                      memberNames: const [],
                                    ),
                                  );
                                  setState(() {});
                                }
                              },
                              child: const Text('New Team'),
                            ),
                          ],
                        ),
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

class EditTeamMembersModal extends ModalView {
  final ManageTeamState viewState;
  final DocumentSnapshot<Map<String, dynamic>>? booking;
  final DocumentSnapshot<Map<String, dynamic>>? teamData;
  final bool hasBooking;
  final List<String> memberNames;

  const EditTeamMembersModal({
    required this.booking,
    required this.teamData,
    required this.hasBooking,
    required this.viewState,
    required this.memberNames,
    super.key,
  }) : super(
          title:
              'Edit Team Members\nAdd team members by typing in their booking codes.',
        );

  @override
  ModalViewState createState() => EditTeamMembersModalState();
}

class EditTeamMembersModalState extends ModalViewState<EditTeamMembersModal> {
  late final List<String> newMembers;
  bool warn = false;
  int errIndex = -1;

  @override
  void initState() {
    newMembers = widget.teamData != null
        ? (widget.teamData?.data()!['members'] as List).cast<String>()
        : ['You'];
    super.initState();
  }

  List<Widget> generateOptions() {
    final List<Widget> options = [];
    final List<TextEditingController> textControllers = [];
    for (int j = 0; j < newMembers.length; j++) {
      textControllers.add(TextEditingController(text: newMembers[j]));
      options.addAll([
        Text(
          j == 0
              ? "Member 1 (You, the team leader)"
              : "Member ${j + 1} (${widget.memberNames[j]})",
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          children: [
            TextField(
              controller: textControllers[j],
              cursorColor: yellow,
              enabled: j != 0,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: j == errIndex
                        ? red.withOpacity(0.6)
                        : yellow.withOpacity(0.3),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: yellow,
                  ),
                ),
              ),
              onChanged: (value) {
                newMembers[j] = textControllers[j].text;
              },
            ),
            if (!widget.hasBooking && j != 0)
              IconButton(
                onPressed: () {
                  setState(() {
                    newMembers.removeAt(j);
                  });
                },
                icon: const Icon(Icons.delete),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ]);
    }
    return options;
  }

  bool allMembersAreUnique(List<String> members) {
    for (int i = 0; i < members.length; i++) {
      if (members[i].isEmpty) return false;
      for (int j = 0; j < members.length; j++) {
        if (i == j) continue;
        if (members[i] == members[j]) return false;
      }
    }
    return true;
  }

  bool noEmptyMembers(List<String> members) {
    for (final member in members) {
      if (member == '') return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return modalScaffold(
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...generateOptions(),
            if (!widget.hasBooking)
              TextButton(
                style: splashButtonStyle(),
                onPressed: () {
                  setState(() {
                    newMembers.add('');
                  });
                },
                child: const Text("Add Member"),
              ),
            const SizedBox(height: 30),
            Row(
              children: [
                TextButton(
                  style: splashButtonStyle(),
                  onPressed: () async {
                    if (allMembersAreUnique([userId, ...newMembers]) &&
                        noEmptyMembers(newMembers)) {
                      int invalidMemIndex = -1;
                      for (int i = 1; i < newMembers.length; i++) {
                        final snap = await db
                            .collection('codes')
                            .doc(newMembers[i])
                            .get();
                        if (!snap.exists) {
                          invalidMemIndex = i;
                          break;
                        }
                      }
                      errIndex = invalidMemIndex;

                      if (invalidMemIndex != -1) {
                        setState(() {});
                        return;
                      } else {
                        setState(() {});
                      }

                      // have to update an existing team
                      newMembers[0] = userId;
                      if (widget.teamData != null) {
                        await db
                            .collection('teams')
                            .doc(widget.teamData!.id)
                            .update({
                          'members': newMembers,
                        });
                        widget.viewState.updatedTeamData[widget.teamData!.id] =
                            {
                          'main': userId,
                          'members': newMembers,
                        };
                      } else {
                        // create new team
                        final newTeamData =
                            (await (await db.collection('teams').add({
                          'main': userId,
                          'members': newMembers,
                        }))
                                .get());
                        widget.viewState.teamData[newTeamData.id] = newTeamData;
                      }
                      setState(() {
                        warn = false;
                      });
                      dismiss(context);
                    } else {
                      setState(() {
                        warn = true;
                      });
                    }
                  },
                  child: const Text("Update Team"),
                ),
                TextButton(
                  style: splashButtonStyle(),
                  onPressed: () => dismiss(context),
                  child: const Text("Cancel"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            TextButton(
              style: splashButtonStyle(),
              onPressed: () async {
                if (widget.hasBooking) {
                  final bool confirm = await showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (c) {
                      return Center(
                        child: Container(
                          width: 200,
                          height: 400,
                          child: Column(
                            children: [
                              const Text(
                                  "This team is registered for an activity. Deleting the team will remove that booking. Do you want to continue?"),
                              Row(
                                children: [
                                  TextButton(
                                    style: splashButtonStyle(),
                                    onPressed: () {
                                      Navigator.of(c).pop(true);
                                    },
                                    child: const Text('Yes'),
                                  ),
                                  TextButton(
                                    style: splashButtonStyle(),
                                    onPressed: () {
                                      Navigator.of(c).pop(false);
                                    },
                                    child: const Text('No'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  if (!confirm) {
                    dismiss(context);
                    return;
                  }

                  final rem = ((await db
                              .collection('activities')
                              .doc(widget.booking!.data()!['activityId'])
                              .get())
                          .data()!['remaining'] as List)
                      .cast<int>();
                  rem[widget.booking!.data()!['slot']] =
                      widget.booking!.data()!['slot'] + 1;
                  await db
                      .collection('activities')
                      .doc(widget.booking!.data()!['activityId'])
                      .update({
                    'remaining': rem,
                  });
                  await db
                      .collection('bookings')
                      .doc(widget.booking!.id)
                      .delete();
                  await propagateBookingToMembers(
                      widget.teamData != null
                          ? ((await db
                                      .collection('teams')
                                      .doc(widget.teamData!.id)
                                      .get())
                                  .data()!['members'] as List)
                              .cast<String>()
                          : [userId],
                      widget.booking!.id,
                      false);
                }
                if (widget.teamData != null) {
                  await db
                      .collection('teams')
                      .doc(widget.teamData!.id)
                      .delete();
                }

                widget.viewState.teamData.remove(widget.teamData!.id);
                dismiss(context);
              },
              child: const Text("Delete Team"),
            ),
            const SizedBox(height: 40),
            if (widget.hasBooking)
              const Text(
                  "Note: You can't add or remove members from this team because there is an activity registered for this team. Try creating another team or unbooking the activity instead."),
            if (warn)
              const Text(
                  "Error: You can't have duplicate members or empty member names."),
            if (errIndex != -1)
              Text(
                "Error: Booking code ${newMembers[errIndex]} not found.",
                style: const TextStyle(color: red),
              ),
          ],
        ),
      ),
    );
  }
}
