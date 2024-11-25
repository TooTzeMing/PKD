import 'package:eventmanagement_app/screen/addevent.dart';
import 'package:eventmanagement_app/screen/eventscreen.dart';
import 'package:eventmanagement_app/screen/loginscreen.dart';
import 'package:eventmanagement_app/screen/scanscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel; // Correct aliased import

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

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
    final ThemeData theme = Theme.of(context);

    final List<Widget> pages = <Widget>[
      Column(
        children: [
          carousel.CarouselSlider(  // Note the usage of the 'carousel' prefix
            options: carousel.CarouselOptions(  // Note the usage of the 'carousel' prefix
              autoPlay: true,
              aspectRatio: 2.0,
              enlargeCenterPage: true,
            ),
            items: widget.imgList.map((item) => Container(
              child: Center(
                  child: Image.network(item, fit: BoxFit.cover, width: MediaQuery.of(context).size.width)
              ),
            )).toList(),
          ),
          // Additional content goes here
        ],
      ),
      const EventScreen(),
      const ScanScreen(),
    ];

    return Scaffold(
      appBar: _getAppBar(),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.event_available_outlined)),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.scanner_sharp),
            ),
            label: 'Messages',
          ),
        ],
      ), body: pages[selectedIndex],


      
    );

    
  }
  AppBar _getAppBar() {
    switch (selectedIndex) {
      case 1: // EventScreen
        return AppBar(
        title: const Text('Events',
        style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow,
        actions: <Widget>[
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
        ],
      );
      case 2: // ScanScreen
        return AppBar(
          title: const Text(
            "Scan QR Code",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          centerTitle: true,
          backgroundColor: Colors.yellow,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.popAndPushNamed(context, "/generate");
              },
              icon: Icon(Icons.qr_code),
            ),
          ],
        );
      default: // HomeScreen
        return AppBar(
          title: const Text(
            'Welcome to PKD App',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.yellow,
          elevation: 0.0,
        );
  
  
  }

}void handleMenuSelection(String value) {
    if (value == 'Add event') {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => const AddEventScreen(),
      ));
    }
  }

}
  

  