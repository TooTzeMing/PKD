import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagement_app/screen/homescreen.dart';

class ScanSuccessScreen extends StatelessWidget {
  final String eventId;
  final bool isDuplicateScan; // Add this parameter to the class

  const ScanSuccessScreen({
    super.key,
    required this.eventId,
    required this.isDuplicateScan, // Ensure it's marked as required
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return const Text('Error fetching event details.');
            }

            String eventName = snapshot.data!['name'] ?? 'Unnamed Event';

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDuplicateScan ? Icons.warning : Icons.check_circle,
                  color: isDuplicateScan ? Colors.red : Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 20),
                Text(
                  isDuplicateScan
                      ? 'You have already scanned for this event.'
                      : 'Successfully Scanned',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  'Event Name: $eventName',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(),
                      ),
                      (Route<dynamic> route) =>
                          false, // This clears the entire stack
                    );
                  },
                  child: const Text('Back to HomePage'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
