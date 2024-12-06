import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:eventmanagement_app/screen/addevent.dart';
import 'package:eventmanagement_app/screen/eventscreen.dart';
import 'package:eventmanagement_app/screen/scanscreen.dart';
import 'package:eventmanagement_app/screen/profilescreen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:eventmanagement_app/services/global.dart';


class HomeScreen extends StatefulWidget {

  final List<String> imgList = [
    'https://www.rurallink.gov.my/wp-content/uploads/2021/05/BILANGAN-PKD-02-scaled.jpg',
    'https://www.malaysia.gov.my/media/uploads/32e3439d-5926-4a8b-9827-aec338fe445e.png',
    'https://www.rurallink.gov.my/wp-content/uploads/2020/09/FUNGSI-PUSAT-KOMUNITI-DESA-1-1024x652.png',
  ];

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      Column(
        children: [
          carousel.CarouselSlider(
            options: carousel.CarouselOptions(
              autoPlay: true,
              aspectRatio: 2.0,
              enlargeCenterPage: true,
            ),
            items: widget.imgList
                .map((item) => Container(
                      child: Center(
                        child: Image.network(
                          item,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      const EventScreen(),
      const ScanScreen(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: _getAppBar(),
      bottomNavigationBar: CircleNavBar(
        activeIndex: selectedIndex,
        activeIcons: const [
          Icon(Icons.home, color: Colors.deepPurple),
          Icon(Icons.event, color: Colors.deepPurple),
          Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
          Icon(Icons.people, color: Colors.deepPurple),
        ],
        inactiveIcons: const [
          Text("Home"),
          Text("Events"),
          Text("Scan"),
          Text("Profile"),
        ],
        color: Colors.white,
        circleWidth: 60,
        height: 70,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        shadowColor: Colors.grey,
        elevation: 5,
      ),
      body: pages[selectedIndex],
    );
  }

  AppBar _getAppBar() {
    switch (selectedIndex) {
      case 1:
        return AppBar(
          title: const Text(
            'Events',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.yellow,
          actions: userRole == 'admin' // Check if user role is 'admin'
              ? <Widget>[
                  PopupMenuButton<String>(
                    onSelected: handleMenuSelection,
                    itemBuilder: (BuildContext context) {
                      return {'Add event'}.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                    icon: const Icon(Icons.menu),
                  ),
                ]
              : null, // No actions for non-admin users
        );
      case 2:
        return AppBar(
          title: const Text(
            "Scan QR Code",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.yellow,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.popAndPushNamed(context, "/generate");
              },
              icon: const Icon(Icons.qr_code),
            ),
          ],
        );
      case 3:
        return AppBar(
          title: const Text('Profile'),
        );
      default:
        return AppBar(
          title: const Text(
            'Welcome to PKD App',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.yellow,
          elevation: 0.0,
        );
    }
  }

  void handleMenuSelection(String value) {
    if (value == 'Add event') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddEventScreen(),
        ),
      );
    }
  }
}
