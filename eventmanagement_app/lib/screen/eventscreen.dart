import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eventmanagement_app/screen/addevent.dart';
import 'package:eventmanagement_app/screen/eventdetail.dart';
import 'package:eventmanagement_app/screen/homescreen.dart';
import 'package:eventmanagement_app/screen/loginscreen.dart';
import 'package:intl/intl.dart'; 



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

  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd').format(dateTime);  // Formatting date
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
      
            body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error fetching data."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> event = document.data()! as Map<String, dynamic>;
              // Ensure the 'date' field exists and is a Timestamp
              String formattedDate = event['date'] != null && event['date'] is Timestamp 
                                      ? formatDate(event['date'] as Timestamp)
                                      : 'No date provided';
              return ListTile(
                title: Text(event['name'] ?? 'No name provided'),
                subtitle: Text(event['venue'] ?? 'No venue provided'),
                trailing: Text(formattedDate),
                onTap: () {
  // Obtain the document snapshot
 // Assuming index is available or use another method to identify the tapped document

  // Navigate to EventDetailScreen with the event ID
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EventDetailScreen(eventId: document.id), // Pass the event ID
    ),
  );
},
              );
            }).toList(),
          );
        },
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
