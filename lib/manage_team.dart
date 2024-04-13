part of splash;

class ManageTeam extends StatefulWidget {
  const ManageTeam({super.key});

  @override
  State<StatefulWidget> createState() => ManageTeamState();
}

class ManageTeamState extends State<ManageTeam> {
  bool hasFetched = false;

  final Map<String, String> activityNames = {};
  final List<DocumentSnapshot<Map<String, dynamic>>?> bookings = [];
  final List<DocumentSnapshot<Map<String, dynamic>>> teams = [];

  void resetState() {
    hasFetched = false;
    teams.clear();
    bookings.clear();
    activityNames.clear();
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

  bool allMembersAreUnique(List<String> members) {
    for (int i = 0; i < members.length; i++) {
      for (int j = 0; j < members.length; j++) {
        if (i == j) continue;
        if (members[i] == members[j]) return false;
      }
    }
    return true;
  }

  Future<void> editTeamDialog(int i) async {
    final List<Widget> options = [];
    final List<String> members = (teams[i]['members'] as List).cast<String>();
    final List<String> newMembers = [];
    for (int j = 0; j < members.length; j++) {
      options.addAll([
        Text("Member $j"),
        const SizedBox(height: 5),
        TextField(
          controller: TextEditingController(text: members[j]),
          onSubmitted: (value) {
            newMembers[j] = value;
          },
        ),
      ]);
    }

    await showDialog(
      context: context,
      builder: (c) => Material(
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Members"),
              const SizedBox(height: 50),
              ...options,
              Row(
                children: [
                  TextButton(
                    style: splashButtonStyle(),
                    onPressed: allMembersAreUnique(newMembers)
                        ? () async {
                            db.collection('teams').doc(teams[i].id).update({
                              'members': newMembers,
                            });
                            setState(() {
                              resetState();
                            });
                          }
                        : null,
                    child: const Text("Update Team"),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: FutureBuilder(
          future: getTeams(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  const Text(
                      "View and manage the teams that you are a leader of."),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      child: const CircularProgressIndicator(),
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
                child: SizedBox(
                  width: 600,
                  child: ListView.separated(
                    itemBuilder: (ctx, i) {
                      bool hasBooking = bookings[i] != null;
                      return Center(
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasBooking)
                                    Text(
                                      "Activity: ${activityNames[bookings[i]!.id]}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  Text(
                                      "Members: ${teams[i].data()!['members'].join(', ')}"),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemCount: teams.length,
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
