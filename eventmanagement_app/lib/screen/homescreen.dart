import 'package:eventmanagement_app/screen/eventscreen.dart';
import 'package:eventmanagement_app/screen/loginscreen.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });

  if (index==1){
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => const EventScreen(),
      ));
    }

  if (index==3){
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Column(
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: const Text(
        'Welcome to PKD App',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold
        )
      ),
      centerTitle: true,
      backgroundColor: Colors.yellow,
      elevation: 0.0,
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Account',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.amber[800],
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }
}
