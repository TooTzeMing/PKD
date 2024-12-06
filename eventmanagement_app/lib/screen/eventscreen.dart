import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eventmanagement_app/screen/addevent.dart';
import 'package:eventmanagement_app/screen/eventdetail.dart';
import 'package:eventmanagement_app/screen/homescreen.dart';
import 'package:eventmanagement_app/screen/loginscreen.dart';
import 'package:intl/intl.dart'; 
import 'package:eventmanagement_app/services/global.dart';



class EventScreen extends StatefulWidget {
  const EventScreen({Key? key}) : super(key: key);

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventScreen> {
  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd').format(dateTime); // Formatting date
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
              padding: EdgeInsets.all(16.0), // Add padding to the ListView
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> event =
                    document.data()! as Map<String, dynamic>;

                String formattedDate =
                    event['date'] != null && event['date'] is Timestamp
                        ? formatDate(event['date'] as Timestamp)
                        : 'No date provided';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EventDetailScreen(eventId: document.id),
                      ),
                    );
                  },
                  child: Container(
                    margin:
                        EdgeInsets.only(bottom: 16.0), // Space between cards
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0), // Inner padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['name'] ?? 'No name provided',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            event['venue'] ?? 'No venue provided',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14.0, color: Colors.grey[700]),
                              SizedBox(width: 4.0),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            event['description'] ?? 'No description provided',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8.0),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
    }
}


