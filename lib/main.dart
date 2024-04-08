library splash;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:splash_booking/firebase_configs.dart';

part './make_booking.dart';
part './manage_team.dart';
part './db.dart';

final db = FirebaseFirestore.instance
  ..useFirestoreEmulator(
    '127.0.0.1',
    8080,
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
          title: const Text("ACSplash Booking System"),
          bottom: const TabBar(tabs: [
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
          ]),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                    "Please enter using the first part of your Teams ID, so if your Teams account is 'hugh.jass@acsians.acsi.edu.sg', type 'hugh.jass'."),
                const SizedBox(height: 40),
                SizedBox(
                  width: 400,
                  child: TextField(
                    autofocus: true,
                    controller: controller,
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
            const MakeBooking(),
            const ManageTeam(),
          ],
        ),
      ),
    );
  }
}
