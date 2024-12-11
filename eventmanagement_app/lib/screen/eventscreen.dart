import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:eventmanagement_app/screen/eventdetail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({Key? key}) : super(key: key);

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> registeredEvents = {}; // Tracks registration status of events

  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('d MMM').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    fetchRegisteredEvents();
  }

   static const Color lightYellow = Color(0xFFFFF9C4);

  void fetchRegisteredEvents() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      var registrations = await _firestore.collection('registration')
        .where('registereduser', isEqualTo: user.uid)
        .get();
      var registeredEventIds = {
        for (var doc in registrations.docs) doc.data()['registeredevent'] as String: true
      };
      setState(() {
        registeredEvents = registeredEventIds;
      });
    }
  }

  void registerForEvent(String eventName, String eventId) async {
    final User? user = _auth.currentUser;
    if (user != null && !registeredEvents.containsKey(eventId)) {
      _firestore.collection('registration').add({
        'registereduser': user.uid,
        'registeredevent': eventId,
      }).then((value) {
        setState(() {
          registeredEvents[eventId] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registered for $eventName')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $error')),
        );
      });
    }
  }

  void unregisterFromEvent(String eventName, String eventId) async {
    final User? user = _auth.currentUser;
    if (user != null && registeredEvents.containsKey(eventId)) {
      var registrations = await _firestore.collection('registration')
        .where('registereduser', isEqualTo: user.uid)
        .where('registeredevent', isEqualTo: eventId)
        .get();
      for (var doc in registrations.docs) {
        await _firestore.collection('registration').doc(doc.id).delete();
      }
      setState(() {
        registeredEvents.remove(eventId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unregistered from $eventName')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text("Error: ${snapshot.error}");
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          return ListView(
            padding: EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> event = document.data()! as Map<String, dynamic>;
              String formattedDate = event['date'] != null && event['date'] is Timestamp
                  ? formatDate(event['date'] as Timestamp)
                  : 'No date';
              String eventId = document.id;
              bool isRegistered = registeredEvents.containsKey(eventId);

              return Container(
                margin: EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: lightYellow,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event['name'] ?? 'Event Name',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[850],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        event['venue'] ?? 'Venue',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        event['description'] ?? 'No description provided',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isRegistered)
                            ElevatedButton(
                              onPressed: () => unregisterFromEvent(event['name'], eventId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent, // Light red color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text('Remove'),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => registerForEvent(event['name'], eventId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightGreen, // light green color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text('Register'),
                            ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailScreen(eventId: document.id),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen, // light green color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text('More'),
                          ),
                        ],
                      ),
                    ],
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