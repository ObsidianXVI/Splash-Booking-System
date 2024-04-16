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

  Future<void> resetState() async {
    hasFetched = false;
    bookings.clear();
    activityNames.clear();
    updatedTeamData.clear();
    await getTeams();
  }

  Future<void> getTeams() async {
    if (hasFetched) return;

    // bookings under this user
    final bkData = await DB.getBookings();

    for (final bk in bkData) {
      // update the map of teamIds and booking ids
      bookings[bk.data()['teamId']] = bk.id;

      bookingData[bk.id] = bk;

      // create a map of activity id to activity name
      activityNames[bk.id] = ((await db
              .collection('activities')
              .doc(bk.data()['activityId'])
              .get())
          .data()!['name']);
    }

    // teams under this user
    for (final te in await DB.getTeams()) {
      teamData[te.id] = te;
    }

    hasFetched = true;
  }

  Map<String, dynamic> getTeamDataFor(String id) {
    if (updatedTeamData.containsKey(id)) {
      return updatedTeamData[id]!;
    } else {
      return teamData[id]!.data()!;
    }
  }

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
                  return Center(
                      child: Column(
                    children: [
                      teamData.isEmpty
                          ? const Text("No teams!")
                          : SizedBox(
                              width: 600,
                              height: 500,
                              child: ListView.separated(
                                itemBuilder: (ctx, i) {
                                  final String tid = teamData.keys.elementAt(i);
                                  bool hasBooking = bookings.containsKey(tid);
                                  return Center(
                                    child: Container(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (hasBooking)
                                                Text(
                                                  "Activity: ${activityNames[bookings[tid]]}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              Text(
                                                  "Members: ${(getTeamDataFor(tid)['members']).join(', ')}"),
                                            ],
                                          ),
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
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 20),
                                itemCount: teamData.length,
                              ),
                            ),
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
                              ),
                            );
                            setState(() {});
                          }
                        },
                        child: const Text('New Team'),
                      ),
                    ],
                  ));
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

  const EditTeamMembersModal({
    required this.booking,
    required this.teamData,
    required this.hasBooking,
    required this.viewState,
    super.key,
  }) : super(title: 'Edit Team Members');

  @override
  ModalViewState createState() => EditTeamMembersModalState();
}

class EditTeamMembersModalState extends ModalViewState<EditTeamMembersModal> {
  late final List<String> newMembers;

  @override
  void initState() {
    newMembers = widget.teamData != null
        ? (widget.teamData?.data()!['members'] as List).cast<String>()
        : ['You'];
    super.initState();
  }

  List<Widget> generateOptions() {
    final List<Widget> options = [];
    for (int j = 0; j < newMembers.length; j++) {
      options.addAll([
        Text(
          j == 0 ? "Member 1 (You, the team leader)" : "Member ${j + 1}",
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          children: [
            TextField(
              controller: TextEditingController(text: newMembers[j]),
              cursorColor: yellow,
              enabled: j != 0,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: yellow.withOpacity(0.3),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: yellow,
                  ),
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  newMembers[j] = value;
                });
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
                    if (allMembersAreUnique(newMembers) &&
                        noEmptyMembers(newMembers)) {
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
                        final newTeamData =
                            (await (await db.collection('teams').add({
                          'main': userId,
                          'members': newMembers,
                        }))
                                .get());
                        widget.viewState.teamData[newTeamData.id] = newTeamData;
                      }

                      dismiss(context);
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
                  "Note: You can't add or remove from this team because there is an activity registered for this team. Try creating another team or unbooking the activity instead."),
          ],
        ),
      ),
    );
  }
}
