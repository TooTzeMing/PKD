import 'package:flutter/material.dart';
import 'package:eventmanagement_app/screen/addevent.dart';
import 'package:eventmanagement_app/screen/homescreen.dart';
import 'package:eventmanagement_app/screen/loginscreen.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({Key? key}) : super(key: key);

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation or other interaction logic here if needed
    if (index==0){
      Navigator.push(context, MaterialPageRoute(
        builder: (context) =>  HomeScreen(),
      ));
    }

    if (index==2){
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        centerTitle: true,
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
      ),
      body: const Center(
        child: Text('Event Page Content Here'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  void handleMenuSelection(String value) {
    if (value == 'Add event') {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => const AddEventScreen(),
      ));
    }
  }
}
