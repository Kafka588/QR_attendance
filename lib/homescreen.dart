import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_att/calendarscreen.dart';
import 'package:qr_att/model/user.dart';
import 'package:qr_att/profilescreen.dart';
import 'package:qr_att/todayscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late double screenHeight;
  late double screenWidth;

  String id = '';

  Color primary = const Color.fromRGBO(108, 53, 222, 1);

  int currentIndex = 1;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarAlt,
    FontAwesomeIcons.check,
    FontAwesomeIcons.user,
  ];

  @override
  void initState() {
    super.initState();
    getId();
  }

  void getId() async {
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection("student")
        .where('id', isEqualTo: User.studentID)
        .get();

    setState(() {
      User.id = snap.docs[0].id;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        // ignore: prefer_const_literals_to_create_immutables
        children: [
          new CalendarScreen(),
          new TodayScreen(),
          new ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: navigationIcons.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentIndex = index;
                  });
                },
                child: Container(
                  width: screenWidth / navigationIcons.length,
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        navigationIcons[index],
                        color: index == currentIndex ? primary : Colors.black54,
                        size: index == currentIndex ? 30 : 26,
                      ),
                      if (index == currentIndex)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          height: 3,
                          width: 22,
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(40)),
                            color: primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
