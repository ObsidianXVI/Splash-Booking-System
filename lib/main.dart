library splash;

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:splash_booking/firebase_configs.dart';

part './make_booking.dart';
part './manage_team.dart';
part './modal_view.dart';
part './styles.dart';
part './db.dart';
part './utils.dart';

const Color blue = Color(0xFF111B2D);
const Color red = Color(0xFFF02D3A);
const Color yellow = Color(0xFFFFC233);
bool shownNonRegPromo = false;

final db = FirebaseFirestore.instance
  ..useFirestoreEmulator(
    '127.0.0.1',
    8082,
  );

late String userId;

void main() async {
  await Firebase.initializeApp(options: webOptions);
  runApp(const SplashApp());
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: blue,
          onPrimary: yellow,
          secondary: red,
          onSecondary: blue,
          error: red,
          onError: blue,
          background: blue,
          onBackground: yellow,
          surface: blue,
          onSurface: yellow,
        ),
        useMaterial3: true,
        fontFamily: 'IBMPlexSans',
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  late final TabController tabController;

  bool showBottomHint = false;
  bool enabled = false;
  bool showBottomErr = false;
  String? userName;

  @override
  void initState() {
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      if (!enabled) {
        setState(() {
          tabController.index = 0;
        });
      } else {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 14,
        shadowColor: Colors.black,
        title: const Text("ACSplash Booking System"),
        bottom: TabBar(
          controller: tabController,
          unselectedLabelColor: red.withOpacity(0.6),
          indicatorColor: red,
          labelColor: red,
          overlayColor: MaterialStatePropertyAll(red.withOpacity(0.1)),
          tabs: const [
            Tab(
              text: 'Account',
              icon: Icon(Icons.account_circle),
            ),
            Tab(
              text: 'Manage Bookings',
              icon: Icon(Icons.format_list_bulleted),
            ),
            Tab(
              text: 'Manage Teams',
              icon: Icon(Icons.groups),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          Stack(
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
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                      "Please login using your booking code.\nIf you don't have one, click the button below to fill out the form, and a code will be sent to you via Teams.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      style: splashButtonStyle(),
                      onPressed: () {
                        html.window.open(
                          "https://forms.office.com/r/Sczzgk4SqU?origin=lprLink",
                          'Get Booking Code',
                        );
                      },
                      child: const Text("Get booking code"),
                    ),
                    const SizedBox(height: 40),
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
                          final codeDoc = (await db
                              .collection('codes')
                              .doc(bookingId)
                              .get());
                          final bool codeIsValid = codeDoc.exists;
                          if (!codeIsValid) {
                            setState(() {
                              enabled = false;
                              showBottomHint = false;
                              showBottomErr = true;
                            });
                          } else {
                            setState(() {
                              enabled = true;
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
                    if (userName != null && showBottomHint)
                      Text("Hello $userName!"),
                    if (showBottomHint)
                      const Text(
                        "Please use the tabs above to create/view/edit bookings, and to choose team members to register with.",
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const MakeBooking(),
          const ManageTeam(),
        ],
      ),
    );
  }
}
