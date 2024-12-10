import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceReportScreen extends StatelessWidget {
  final String eventId;
  final String eventName;

  const AttendanceReportScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  Future<List<String>> fetchAttendees() async {
    final QuerySnapshot participantSnapshot = await FirebaseFirestore.instance
        .collection('eventParticipants')
        .where('eventId', isEqualTo: eventId)
        .get();

    List<String> attendeeNames = [];
    for (var doc in participantSnapshot.docs) {
      final userId = doc['userId'];

      // Fetch user details from users collection
      final DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        attendeeNames.add(userSnapshot['name']);
      }
    }
    return attendeeNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$eventName - Attendance Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Fetch and display attendees
            Expanded(
              child: FutureBuilder<List<String>>(
                future: fetchAttendees(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No attendees have checked in yet.');
                  }

                  final attendeeNames = snapshot.data!;
                  return ListView.builder(
                    itemCount: attendeeNames.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(attendeeNames[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
