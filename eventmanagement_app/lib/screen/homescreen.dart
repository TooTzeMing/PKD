import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:eventmanagement_app/screen/addevent.dart';
import 'package:eventmanagement_app/screen/eventscreen.dart';
import 'package:eventmanagement_app/screen/scanscreen.dart';
import 'package:eventmanagement_app/screen/profilescreen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:eventmanagement_app/services/global.dart';
import 'package:eventmanagement_app/services/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagement_app/screen/eventdetail.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final List<String> imgList = [
    'https://www.rurallink.gov.my/wp-content/uploads/2021/05/BILANGAN-PKD-02-scaled.jpg',
    'https://www.malaysia.gov.my/media/uploads/32e3439d-5926-4a8b-9827-aec338fe445e.png',
    'https://www.rurallink.gov.my/wp-content/uploads/2020/09/FUNGSI-PUSAT-KOMUNITI-DESA-1-1024x652.png',
  ];

  HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  void refreshHomePage() {
    setState(() {
      print("Homepage refreshed!");
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      SingleChildScrollView(
        child: Column(
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

            // Announcements Section
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Announcements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 12.0),
                          scrollDirection: Axis.horizontal,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final announcement = snapshot.data!.docs[index];
                            return Container(
                              width: 300,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Text(
                                      announcement['content'],
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (announcement['timestamp'] != null)
                                    Text(
                                      'Posted: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((announcement['timestamp'] as Timestamp).toDate().toLocal())}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color.fromARGB(255, 54, 54, 54),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Title for the Registered Events section
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Registered Events",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // StreamBuilder for registered events
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance
                      .collection('registration')
                      .where('registereduser',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .snapshots()
                  : null,
              builder: (context, registrationSnapshot) {
                if (!registrationSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<String> registeredEventIds = registrationSnapshot
                    .data!.docs
                    .map((doc) => doc['registeredevent'] as String)
                    .toList();

                if (registeredEventIds.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No registered events',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .where(FieldPath.documentId, whereIn: registeredEventIds)
                      .snapshots(),
                  builder: (context, eventSnapshot) {
                    if (!eventSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var events = eventSnapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        var event = events[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(event['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event['description']),
                                const SizedBox(height: 4),
                                Text(
                                  'Venue: ${event['venue']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (event['date'] != null)
                                  Text(
                                    'Date: ${DateFormat('yyyy-MM-dd').format((event['date'] as Timestamp).toDate())}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventDetailScreen(
                                      eventId: event.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
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
          Icon(Icons.home, color: Colors.black),
          Icon(Icons.event, color: Colors.black),
          Icon(Icons.qr_code_scanner, color: Colors.black),
          Icon(Icons.people, color: Colors.black),
        ],
        inactiveIcons: const [
          Text(
            "Home",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "Events",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "Scan",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "Profile",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
        color: Colors.yellow,
        circleWidth: 55,
        height: 60,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
      body: pages[selectedIndex],
    );
  }

  AppBar? _getAppBar() {
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
          actions: userRole == 'admin'
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
                    icon: const Icon(Icons.settings),
                  ),
                ]
              : null,
        );
      case 2:
        return null;
      case 3:
        return AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.yellow,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () {
                _showLogoutConfirmation(context);
              },
            ),
          ],
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
      ).then((_) => refreshHomePage());
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                AuthService().signout(context: context);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
