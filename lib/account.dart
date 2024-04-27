part of splash;

class AccountView extends StatefulWidget {
  const AccountView({
    super.key,
  });
  @override
  State<StatefulWidget> createState() => AccountViewState();
}

class AccountViewState extends State<AccountView> {
  int item = 0;

  @override
  Widget build(BuildContext context) {
    final Widget displayItem;
    if (item == 1) {
      displayItem = const BookingCodeEntry();
    } else if (item == 2) {
      displayItem = const BookingCodeGenerator();
    } else {
      displayItem = Column(
        children: [
          TextButton(
            style: splashButtonStyle().copyWith(
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                item = 1;
              });
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 60,
              height: 120,
              child: const Center(
                child: Text("I have a booking code"),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            style: splashButtonStyle().copyWith(
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                item = 2;
              });
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 60,
              height: 120,
              child: const Center(
                child: Text("I need to generate a booking code"),
              ),
            ),
          )
        ],
      );
    }
    return Stack(
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
          padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
          child: displayItem,
        ),
      ],
    );
  }
}

class BookingCodeEntry extends StatefulWidget {
  const BookingCodeEntry({super.key});

  @override
  State<StatefulWidget> createState() => BookingCodeEntryState();
}

class BookingCodeEntryState extends State<BookingCodeEntry> {
  final TextEditingController controller = TextEditingController();

  bool showBottomErr = false;
  String? userName;
  bool showBottomHint = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 400,
          child: TextField(
            cursorColor: yellow,
            autofocus: true,
            controller: controller,
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
            onSubmitted: (String bookingId) async {
              bookingId = bookingId.trim().toLowerCase();
              final codeDoc =
                  (await db.collection('codes').doc(bookingId).get());
              final bool codeIsValid = codeDoc.exists;
              if (!codeIsValid) {
                setState(() {
                  LoginPageState.enabled = false;
                  showBottomHint = false;
                  showBottomErr = true;
                });
              } else {
                setState(() {
                  LoginPageState.enabled = true;
                  userId = bookingId;
                  userName = codeDoc.data()!['name'];
                  showBottomHint = true;
                  showBottomErr = false;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 30),
        if (showBottomErr) const Text("Booking code not found."),
        if (userName != null && showBottomHint) Text("Hello $userName!"),
        if (showBottomHint)
          const Text(
            "Please use the tabs above to create/view/edit bookings, and to choose team members to register with.",
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class BookingCodeGenerator extends StatefulWidget {
  const BookingCodeGenerator({super.key});

  @override
  State<StatefulWidget> createState() => BookingCodeGeneratorState();
}

class BookingCodeGeneratorState extends State<BookingCodeGenerator> {
  final ExpansionTileController expansionController1 =
      ExpansionTileController();
  final ExpansionTileController expansionController2 =
      ExpansionTileController();
  final ExpansionTileController expansionController3 =
      ExpansionTileController();
  final TextEditingController teamsIdController = TextEditingController();
  bool step2Err = false;
  int activeTile = 1;
  String? code;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IgnorePointer(
          ignoring: activeTile != 1,
          child: ExpansionTile(
            collapsedTextColor: yellow.withOpacity(0.4),
            collapsedIconColor: yellow.withOpacity(0.4),
            iconColor: yellow,
            controller: expansionController1,
            initiallyExpanded: true,
            leading: const Icon(Icons.looks_one),
            title: const Text(
              'Request Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            children: [
              const SizedBox(height: 20),
              const Text(
                """Click on the button below to fill out the form and generate a booking code.""",
                //"Please login using your booking code.\nIf you don't have one, click the button below to fill out the form, and a code will be sent to you via Teams.",
              ),
              const SizedBox(height: 20),
              TextButton(
                style: splashButtonStyle(),
                onPressed: () {
                  expansionController1.collapse();
                  expansionController2.expand();
                  setState(() {
                    activeTile += 1;
                  });
                  html.window.open(
                    "https://forms.office.com/r/C3HzgSVVLD",
                    'Get Booking Code',
                  );
                },
                child: const Text("Get booking code"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        IgnorePointer(
          ignoring: activeTile != 2,
          child: ExpansionTile(
            collapsedTextColor: yellow.withOpacity(0.4),
            collapsedIconColor: yellow.withOpacity(0.4),
            iconColor: yellow,
            controller: expansionController2,
            leading: const Icon(Icons.looks_two),
            title: const Text(
              'Enter Teams ID',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            children: [
              const SizedBox(height: 20),
              const Text(
                """Enter your Teams username. For example, the username for '69ben.dover@acsians.acsi.edu.sg' is '69ben.dover'.""",
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 400,
                child: TextField(
                  cursorColor: yellow,
                  autofocus: true,
                  controller: teamsIdController,
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
                  onSubmitted: (String teamsId) async {
                    teamsId = teamsId.trim().toLowerCase();
                    final codeDoc =
                        (await db.collection('requests').doc(teamsId).get());
                    final bool idIsValid = codeDoc.exists;
                    if (!idIsValid) {
                      setState(() {
                        step2Err = true;
                        code = null;
                      });
                    } else {
                      setState(() {
                        activeTile += 1;
                        step2Err = false;
                        userId = code = codeDoc.data()!['code'];
                        LoginPageState.enabled = true;
                      });
                      await db.collection('requests').doc(teamsId).delete();
                      await db.collection('codes').doc(userId).set({
                        'name': teamsId,
                        'bookings': [],
                      });

                      expansionController2.collapse();
                      expansionController3.expand();
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
              if (step2Err)
                const SelectableText(
                  "This Teams ID has not requested for a code. Ensure there are no typos and the form has been submitted.",
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        IgnorePointer(
          ignoring: activeTile != 3,
          child: ExpansionTile(
            collapsedTextColor: yellow.withOpacity(0.4),
            collapsedIconColor: yellow.withOpacity(0.4),
            iconColor: yellow,
            controller: expansionController3,
            leading: const Icon(Icons.looks_3),
            title: const Text(
              'Complete!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            children: [
              const SizedBox(height: 20),
              const Text(
                """Your booking code is (please note it down):""",
              ),
              const SizedBox(height: 20),
              Text(
                code ?? 'Please complete the previous steps',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Please use the tabs above to create/view/edit bookings, and to choose team members to register with.",
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
      /* children: [
        const SizedBox(height: 50),
        const Text(
          """Click on the button below to fill out the form and generate a booking code.""",
          //"Please login using your booking code.\nIf you don't have one, click the button below to fill out the form, and a code will be sent to you via Teams.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        TextButton(
          style: splashButtonStyle(),
          onPressed: () {
            html.window.open(
              "https://forms.office.com/r/C3HzgSVVLD",
              'Get Booking Code',
            );
          },
          child: const Text("Get booking code"),
        ),
      ], */
    );
  }
}
