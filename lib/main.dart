library splash;

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:splash_booking/configs.dart';
import 'package:googleapis/logging/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logger/logger.dart';

part './account.dart';
part './make_booking.dart';
part './manage_team.dart';
part './modal_view.dart';
part './styles.dart';
part './db.dart';
part './utils.dart';
part './logging.dart';

const Color blue = Color(0xFF111B2D);
const Color red = Color(0xFFF02D3A);
const Color yellow = Color(0xFFFFC233);
bool shownNonRegPromo = false;

final db = FirebaseFirestore.instance
  ..useFirestoreEmulator(
    '127.0.0.1',
    8082,
  );

final GoogleCloudLoggingService loggingService = GoogleCloudLoggingService();
final Logger logger = Logger();

late String userId;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: webOptions);
  await loggingService.setupLoggingApi();
  Logger.addOutputListener((event) {
    loggingService.writeLog(
      level: event.level,
      message: event.lines.join('\n'),
    );
    debugPrint('App will log output to Cloud Logging');
  });
  FlutterError.onError = ((details) {
    FlutterError.presentError(details);
    logger.e(
      "ERR: ${details.summary} (${details.exception})",
      stackTrace: details.stack,
    );
  });
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
        primaryColor: blue,
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
  late final TabController tabController;

  static bool enabled = false;

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
              icon: Icon(Icons.list),
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
        children: const [
          AccountView(),
          MakeBooking(),
          ManageTeam(),
        ],
      ),
    );
  }
}
