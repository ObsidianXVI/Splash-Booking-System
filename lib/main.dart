library splash;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:splash_booking/firebase_configs.dart';

part './bookings.dart';
part './make_booking.dart';

final db = FirebaseFirestore.instance
  ..useFirestoreEmulator(
    '127.0.0.1',
    8080,
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  bool enabled = false;
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          TextField(
            onSubmitted: (String teamsId) {
              setState(() {
                enabled = true;
                userId = teamsId.trim().toLowerCase();
              });
            },
          ),
          TextButton(
            onPressed: enabled
                ? () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ViewBookings()));
                  }
                : null,
            child: const Text("View bookings"),
          ),
          TextButton(
            onPressed: enabled
                ? () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => MakeBooking()));
                  }
                : null,
            child: const Text("Make booking"),
          ),
        ],
      ),
    );
  }
}
