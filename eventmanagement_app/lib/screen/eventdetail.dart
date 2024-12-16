import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagement_app/screen/editevent.dart';
import 'package:eventmanagement_app/screen/AttendanceReportScreen.dart'; // Import the new screen
import 'package:pretty_qr_code/pretty_qr_code.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late DocumentSnapshot eventDocument;
  bool isEventFetched = false;

  @override
  void initState() {
    super.initState();
    fetchEvent();
  }

  void fetchEvent() async {
    eventDocument = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get();

    setState(() {
      isEventFetched = true;
    });
  }

  void deleteEvent() async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String qrData = widget.eventId;

    if (!isEventFetched) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, dynamic> event = eventDocument.data()! as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(event['name'] ?? 'Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditEventScreen(eventDocument: eventDocument),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => deleteEvent(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            PrettyQrView.data(data: qrData),
            const SizedBox(height: 20),
            Text(
                'Description: ${event['description'] ?? 'No description provided'}',
                style: const TextStyle(fontSize: 16, height: 1.5)),
            Text('Maximum Participants: ${event['maxParticipants'].toString()}',
                style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceReportScreen(
                      eventId: widget.eventId,
                      eventName: event['name'] ?? 'Event',
                    ),
                  ),
                );
              },
              child: const Text('View Attendance Report'),
            ),
          ],
        ),
      ),
    );
  }
}
