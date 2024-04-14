part of splash;

class ManageTeam extends StatefulWidget {
  const ManageTeam({super.key});

  @override
  State<StatefulWidget> createState() => ManageTeamState();
}

class ManageTeamState extends State<ManageTeam> {
  bool hasFetched = false;

  final List<List<String>?> modifiedTeam = [];
  final Map<String, String> activityNames = {};
  final List<DocumentSnapshot<Map<String, dynamic>>?> bookings = [];
  final List<DocumentSnapshot<Map<String, dynamic>>> teams = [];

  Future<void> resetState() async {
    hasFetched = false;
    teams.clear();
    bookings.clear();
    activityNames.clear();
    modifiedTeam.clear();
    await getTeams();
  }

  Future<void> getTeams() async {
    if (hasFetched) return;

    final bookingData = await DB.getBookings();
    for (final bk in bookingData) {
      activityNames[bk.id] = ((await db
              .collection('activities')
              .doc(bk.data()['activityId'])
              .get())
          .data()!['name']);
    }
    for (final te in await DB.getTeams()) {
      modifiedTeam.add(null);
      teams.add(te);
      for (final bk in bookingData) {
        if (te.id == bk.data()['teamId']) {
          bookings.add(bk);
        } else {
          bookings.add(null);
        }
      }
    }

    hasFetched = true;
  }

  Future<void> editTeamDialog(int i) async {
    await showDialog(
      context: context,
      builder: (ctx) => EditTeamMembersModal(
        bookings: bookings,
        teams: teams,
        editingTeamIndex: i,
      ),
    );
    await resetState();
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
                  if (teams.isEmpty) {
                    return const Center(
                      child: Text("No teams!"),
                    );
                  }
                  return Center(
                      child: Column(
                    children: [
                      SizedBox(
                        width: 600,
                        height: 500,
                        child: ListView.separated(
                          itemBuilder: (ctx, i) {
                            bool hasBooking = bookings[i] != null;
                            return Center(
                              child: Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (hasBooking)
                                          Text(
                                            "Activity: ${activityNames[bookings[i]!.id]}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        Text(
                                            "Members: ${(teams[i].data()!['members']).join(', ')}"),
                                      ],
                                    ),
                                    TextButton(
                                      style: splashButtonStyle(),
                                      onPressed: () => editTeamDialog(i),
                                      child: const Text("Edit Team"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 20),
                          itemCount: teams.length,
                        ),
                      ),
                      TextButton(
                        style: splashButtonStyle(),
                        onPressed: () async {
                          final ref = await db.collection('teams').add({
                            'main': userId,
                            'members': [userId],
                          });
                          bookings.add(null);
                          teams.add(await ref.get());
                          modifiedTeam.add(null);
                          if (mounted) {
                            await showDialog(
                              context: context,
                              builder: (_) => EditTeamMembersModal(
                                bookings: bookings,
                                teams: teams,
                                editingTeamIndex: teams.length - 1,
                              ),
                            );
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
  final int editingTeamIndex;
  final List<DocumentSnapshot<Map<String, dynamic>>?> bookings;
  final List<DocumentSnapshot<Map<String, dynamic>>> teams;

  const EditTeamMembersModal({
    required this.bookings,
    required this.teams,
    required this.editingTeamIndex,
    super.key,
  }) : super(title: 'Edit Team Members');

  @override
  ModalViewState createState() => EditTeamMembersModalState();
}

class EditTeamMembersModalState extends ModalViewState<EditTeamMembersModal> {
  late final bool linkedToActivity;

  late final List<String> newMembers;

  @override
  void initState() {
    linkedToActivity = widget.bookings[widget.editingTeamIndex] != null;
    newMembers = (widget.teams[widget.editingTeamIndex]['members'] as List)
        .cast<String>();
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
            if (j != 0)
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

  @override
  Widget build(BuildContext context) {
    return modalScaffold(
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...generateOptions(),
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
                    if (allMembersAreUnique(newMembers)) {
                      await db
                          .collection('teams')
                          .doc(widget.teams[widget.editingTeamIndex].id)
                          .update({
                        'members': newMembers,
                      });

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
                await db
                    .collection('teams')
                    .doc(widget.teams[widget.editingTeamIndex].id)
                    .delete();

                dismiss(context);
              },
              child: const Text("Delete Team"),
            ),
          ],
        ),
      ),
    );
  }
}
