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
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(eventId)
        .get();

    if (!attendanceSnapshot.exists) {
      return [];
    }

    // Get the list of attendees (contains maps with userId and timestamp)
    List<dynamic> attendees = attendanceSnapshot['attendees'] ?? [];
    if (attendees.isEmpty) return [];

    // Extract userIds from attendees
    List<String> userIds =
        attendees.map((attendee) => attendee['userId'] as String).toList();

    // Fetch user details for all IDs in a single batch
    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    // Map user details with their respective timestamps
    return userDocs.docs.map((userDoc) {
      final userId = userDoc.id;
      final attendeeInfo =
          attendees.firstWhere((attendee) => attendee['userId'] == userId);

      return {
        'name': userDoc['name'],
        'timestamp': attendeeInfo['timestamp'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchRegisteredButNoAttend() async {
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(eventId)
        .get();

    if (!attendanceSnapshot.exists) {
      return [];
    }

    // Get the list of registered users and attendees
    List<dynamic> registeredUsers = attendanceSnapshot['registeredUsers'] ?? [];
    List<dynamic> attendees = attendanceSnapshot['attendees'] ?? [];

    // Extract userIds from both lists
    List<String> attendeeUserIds =
        attendees.map((attendee) => attendee['userId'] as String).toList();
    List<String> registeredUserIds =
        registeredUsers.map((user) => user['userId'] as String).toList();

    // Filter registered users who haven't attended
    List<String> notAttendedUserIds = registeredUserIds
        .where((userId) => !attendeeUserIds.contains(userId))
        .toList();

    if (notAttendedUserIds.isEmpty) return [];

    // Fetch user details for not attended user IDs
    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: notAttendedUserIds)
        .get();

    // Map user details with null timestamp (no attendance)
    return userDocs.docs.map((userDoc) {
      final userId = userDoc.id;
      final attendeeInfo =
          registeredUsers.firstWhere((user) => user['userId'] == userId);
      return {
        'name': userDoc['name'],
        'timestamp': attendeeInfo['timestamp'],
      };
    }).toList();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final dateTime = timestamp.toDate();
    return DateFormat('HH:mm:ss a dd-MM-yyyy').format(dateTime);
  }

  Future<void> generateAndDownloadPdf(List<Map<String, dynamic>> attendees,
      List<Map<String, dynamic>> registeredButNoAttend) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$eventName - Attendance Report',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),

              // Attendees Table
              pw.Text(
                'Attendees:',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Name', 'Scanned Time'],
                data: attendees.map((attendee) {
                  return [
                    attendee['name'],
                    formatTimestamp(attendee['timestamp']),
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 12),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),

              // Registered but not attended Table
              pw.Text(
                'Registered but not attended:',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Name', 'Scanned Time'],
                data: registeredButNoAttend.map((user) {
                  return [
                    user['name'],
                    formatTimestamp(user['timestamp']),
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 12),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Attendance_Report_$eventName.pdf',
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$eventName',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.yellow,
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
              child: FutureBuilder(
                future: Future.wait([
                  fetchAttendees(),
                  fetchRegisteredButNoAttend(),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final attendees = snapshot.data![0];
                  final registeredButNoAttend = snapshot.data![1];

                  if (attendees.isEmpty && registeredButNoAttend.isEmpty) {
                    return const Text(
                        'No attendees or registered users available.');
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            const Text(
                              'Attendees:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...attendees.map((attendee) {
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(attendee['name']),
                                subtitle: Text(
                                    formatTimestamp(attendee['timestamp'])),
                              );
                            }),
                            const SizedBox(height: 20),
                            const Text(
                              'Registered but not attended:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...registeredButNoAttend.map((user) {
                              return ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(user['name']),
                                subtitle:
                                    Text(formatTimestamp(user['timestamp'])),
                              );
                            }),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final attendee = [
                            ...attendees,
                          ];
                          final registeredButNoAtten = [
                            ...registeredButNoAttend
                          ];
                          generateAndDownloadPdf(
                              attendee, registeredButNoAtten);
                        },
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
