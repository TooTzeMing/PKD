import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagement_app/screen/editevent.dart';


class EventDetailScreen extends StatefulWidget {
  final String eventId;
  EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late DocumentSnapshot eventDocument;

  @override
  void initState() {
    super.initState();
    fetchEvent();
  }

  void fetchEvent() async {
    eventDocument = await FirebaseFirestore.instance.collection('events').doc(widget.eventId).get();
    setState(() {});
  }

  void deleteEvent() async {
    await FirebaseFirestore.instance.collection('events').doc(widget.eventId).delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (eventDocument == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, dynamic> event = eventDocument.data()! as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(event['name'] ?? 'Event Details'),
        actions: [
          IconButton(
      icon: Icon(Icons.edit),
     onPressed: () {
      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventScreen(eventDocument: eventDocument),
      ),
    );
  },
),

IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => deleteEvent(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${event['description'] ?? 'No description provided'}', style: TextStyle(fontSize: 16, height: 1.5)),
            Text('Maximum Participants: ${event['maxParticipants'].toString()}', style: TextStyle(fontSize: 16, height: 1.5)),
            // Add more fields as necessary
          ],
        ),
      ),
    );
  }
}
