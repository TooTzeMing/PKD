import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class AttendanceReportScreen extends StatelessWidget {
  final String eventId;
  final String eventName;

  const AttendanceReportScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  Future<List<Map<String, dynamic>>> fetchAttendees() async {
    final QuerySnapshot participantSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('eventId', isEqualTo: eventId)
        .get();

    List<Map<String, dynamic>> attendees = [];
    for (var doc in participantSnapshot.docs) {
      final userId = doc['userId'];
      final timestamp = doc['timestamp']; // Assuming this field exists.

      // Fetch user details from users collection
      final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        attendees.add({
          'name': userSnapshot['name'],
          'timestamp': timestamp,
        });
      }
    }
    return attendees;
  }

  String formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat('HH:mm:ss a dd-MM-yyyy').format(dateTime);
  }

  Future<void> generateAndDownloadPdf(
      List<Map<String, dynamic>> attendees) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Attendance Report for $eventName',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Name', 'Scanned Time'],
                data: attendees.map((attendee) {
                  return [
                    attendee['name'],
                    formatTimestamp(attendee['timestamp']),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Attendance_Report.pdf',
    );
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
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
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

                  final attendees = snapshot.data!;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: attendees.length,
                          itemBuilder: (context, index) {
                            final attendee = attendees[index];
                            final formattedTime =
                                formatTimestamp(attendee['timestamp']);
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(attendee['name']),
                              subtitle: Text(formattedTime),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => generateAndDownloadPdf(attendees),
                        child: const Text('Download PDF'),
                      ),
                    ],
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
