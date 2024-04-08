part of splash;

class ManageTeam extends StatefulWidget {
  const ManageTeam({super.key});

  @override
  State<StatefulWidget> createState() => ManageTeamState();
}

class ManageTeamState extends State<ManageTeam> {
  bool hasFetched = false;
  final List<String> activityNames = [];
  final List<DocumentSnapshot<Map<String, dynamic>>> teams = [];
  Future<void> getTeams() async {
    if (hasFetched) return;

    final bookings = await DB.getBookings();
    for (final bk in bookings) {
      activityNames.add(
          (await db.collection('activities').doc(bk.data()['activityId']).get())
              .data()!['name']);
      teams.add(await db.collection('teams').doc(bk.data()['teamId']).get());
    }

    hasFetched = true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            const Text("View and manage the teams that you are a leader of."),
            const SizedBox(height: 20),
            FutureBuilder(
              future: getTeams(),
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
                  if (teams.isEmpty) return const Text("No teams!");
                  return Center(
                    child: SizedBox(
                      width: 600,
                      child: ListView.separated(
                        itemBuilder: (ctx, i) {
                          return Center(
                            child: Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "Acitivity: ${activityNames[i]}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                          "Members: ${teams[i].data()!['members'].join(', ')}"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemCount: activityNames.length,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
