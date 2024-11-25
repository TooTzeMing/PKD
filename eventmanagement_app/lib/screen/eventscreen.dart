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


  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd').format(dateTime);  // Formatting date
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      
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
       
    );
  }

  
}
