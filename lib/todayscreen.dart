import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:qr_att/model/user.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'dart:typed_data';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  _TodayScreenState createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late double screenHeight;
  late double screenWidth;

  String checkIn = "--/--";
  String scanResult = " ";
  String lectureCode = " ";
  Timer? timer;
  // Location
  String locationMessage = '';
  late String lat;
  late String long;
  // University location
  final double minUniversityLatitude = 47.926200;
  final double maxUniversityLatitude = 47.926668;
  final double minUniversityLongitude = 106.883102;
  final double maxUniversityLongitude = 106.885400;

  Color primary = const Color.fromRGBO(108, 53, 222, 1);

  void initState() {
    super.initState();
    _getRecord();
    _getLectureCode();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel(); // Add this line
    super.dispose();
  }

  // QR section
  Future<void> ScanQRandCheck() async {
    String result = " ";

    try {
      result = await FlutterBarcodeScanner.scanBarcode(
          "#FFFFFF", "Cancel", false, ScanMode.QR);
    } catch (e) {
      print("error");
    }
    setState(() {
      scanResult = result;
    });

    if (scanResult == lectureCode) {
      print("how?");
      _getCurrentLocation().then((value) {
        lat = '${value.latitude}';
        long = '${value.longitude}';
        setState(() {
          locationMessage = 'location - latitude: $lat, longtitude: $long';
        });
      });
      Position currentPosition = await _getCurrentLocation();
      bool isWithinUniversity =
          await _isLocationWithinBoundary(currentPosition);

      if (isWithinUniversity) {
        print('boltson');

        QuerySnapshot snap = await FirebaseFirestore.instance
            .collection("student")
            .where('id', isEqualTo: User.studentID)
            .get();

        DocumentSnapshot snap2 = await FirebaseFirestore.instance
            .collection("student")
            .doc(snap.docs[0].id)
            .collection("Record")
            .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
            .get();

        try {
          String checkIn = snap2['checkIn'];
          await FirebaseFirestore.instance
              .collection("student")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
              .update({
            'date': Timestamp.now(),
            'checkIn': checkIn,
            'location':
                GeoPoint(currentPosition.latitude, currentPosition.longitude),
          });
        } catch (e) {
          setState(() {
            checkIn = DateFormat('hh:mm').format(DateTime.now());
          });
          await FirebaseFirestore.instance
              .collection("student")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
              .set({
            'date': Timestamp.now(),
            'checkIn': DateFormat('hh:mm').format(
              DateTime.now(),
            ),
            'location':
                GeoPoint(currentPosition.latitude, currentPosition.longitude),
          });
        }
      } else {
        print("hud2");
        // Display an error message using a SnackBar
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in at your school.'),
          ),
        );
      }
    } else {
      print("bolku bna zda mine");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not working!'),
        ),
      );
    }
  }

  // Code generation
  void _getLectureCode() async {
    DocumentSnapshot snap = await FirebaseFirestore.instance
        .collection("lectures")
        .doc('Mobile Programming')
        .get();

    setState(() {
      lectureCode = snap['code'];
    });
  }

  // Key generation
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      print("check1");
      // Generating random key
      final key = generateRandomKey();

      FirebaseFirestore.instance
          .collection("lectures")
          .doc("Mobile Programming")
          .update({"code": key});
    });
    print("check2");
  }

  String generateRandomKey() {
    print("generate");
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = Random.secure().nextInt(256);
    }
    final hash = crypto.sha256.convert(bytes);
    return base64Encode(hash.bytes);
  }

  // Location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<bool> _isLocationWithinBoundary(Position currentPosition) async {
    double latitude = currentPosition.latitude;
    double longitude = currentPosition.longitude;

    // Check if latitude is within the defined range
    bool isLatitudeWithinRange = (latitude >= minUniversityLatitude &&
        latitude <= maxUniversityLatitude);
    print('Is latitude within range? $isLatitudeWithinRange');

    // Check if longitude is within the defined range
    bool isLongitudeWithinRange = (longitude >= minUniversityLongitude &&
        longitude <= maxUniversityLongitude);
    print('Is longitude within range? $isLongitudeWithinRange');

    // Return true if both latitude and longitude are within the defined range
    return isLatitudeWithinRange && isLongitudeWithinRange;
  }

  void _getRecord() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("student")
          .where('id', isEqualTo: User.studentID)
          .get();

      DocumentSnapshot snap2 = await FirebaseFirestore.instance
          .collection("student")
          .doc(snap.docs[0].id)
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .get();

      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          checkIn = snap2['checkIn'];
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          checkIn = "--/--";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: "NexaRegular",
                  fontSize: screenWidth / 20,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Text(
                "Student " + User.studentID,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Today's status",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Check In",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          checkIn,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Lecture Name",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: DateTime.now().day.toString(),
                      style: TextStyle(
                        color: primary,
                        fontFamily: "NexaBold",
                        fontSize: screenWidth / 18,
                      ),
                    ),
                    TextSpan(
                      text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: "NexaBold",
                        fontSize: screenWidth / 20,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('hh:mm:ss a').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: "NexaRegular",
                        fontSize: screenWidth / 20,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }),
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: Builder(
                builder: (context) {
                  return GestureDetector(
                    onTap: ScanQRandCheck,
                    child: Center(
                      child: Container(
                        height: screenWidth / 2,
                        width: screenWidth / 2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(2, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.expand,
                                    size: 70,
                                    color: primary,
                                  ),
                                  Icon(
                                    FontAwesomeIcons.camera,
                                    size: 25,
                                    color: primary,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: Text(
                                  "Scan to check in",
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontFamily: "NexaRegular",
                                      fontSize: screenWidth / 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
            // Text(locationMessage),
          ],
        ),
      ),
    );
  }
}
