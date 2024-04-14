library splash;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:splash_booking/firebase_configs.dart';

part './make_booking.dart';
part './manage_team.dart';
part './styles.dart';
part './db.dart';

const Color blue = Color(0xFF111B2D);
const Color red = Color(0xFFF02D3A);
const Color yellow = Color(0xFFFFC233);

final db = FirebaseFirestore.instance
  ..useFirestoreEmulator(
    '127.0.0.1',
    8082,
  );

/**
 * TODO:
 * - Booking.delete feature for bookings
 * - sign up in teams feature
 * - UI
 */
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

class LoginPageState extends State<LoginPage> {
  final TextEditingController controller = TextEditingController();
  bool showBottomHint = false;

  bool enabled = false;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 14,
          shadowColor: Colors.black,
          title: const Text("ACSplash Booking System"),
          bottom: TabBar(
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
          children: [
            Stack(
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
                Column(
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                        "Please enter using the first part of your Teams ID, so if your Teams account is 'hugh.jass@acsians.acsi.edu.sg', type 'hugh.jass'."),
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
                        onSubmitted: (String teamsId) {
                          setState(() {
                            enabled = true;
                            userId = teamsId.trim().toLowerCase();
                            showBottomHint = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (showBottomHint)
                      const Text(
                          "Now use the tabs above to create/view/edit bookings, and to choose team members to register with."),
                  ],
                ),
              ],
            ),
            const MakeBooking(),
            const ManageTeam(),
          ],
        ),
      ),
    );
  }
}
