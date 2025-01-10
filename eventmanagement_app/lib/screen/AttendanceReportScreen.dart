import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';

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

    List<dynamic> attendees = attendanceSnapshot['attendees'] ?? [];
    if (attendees.isEmpty) return [];

    List<String> userIds =
        attendees.map((attendee) => attendee['userId'] as String).toList();

    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    return userDocs.docs.map((userDoc) {
      final userId = userDoc.id;
      final attendeeInfo =
          attendees.firstWhere((attendee) => attendee['userId'] == userId);

      return {
        'name': userDoc['name'],
        'ic': userDoc['ic'],
        'gender': userDoc['gender'],
        'no_tel': userDoc['no_tel'],
        'address': userDoc['address'],
        'postcode': userDoc['postcode'],
        'state': userDoc['state'],
        'age_level': userDoc['age_level'],
        'household_category': userDoc['household_category'],
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

    List<dynamic> registeredUsers = attendanceSnapshot['registeredUsers'] ?? [];
    List<dynamic> attendees = attendanceSnapshot['attendees'] ?? [];

    List<String> attendeeUserIds =
        attendees.map((attendee) => attendee['userId'] as String).toList();
    List<String> registeredUserIds =
        registeredUsers.map((user) => user['userId'] as String).toList();

    List<String> notAttendedUserIds = registeredUserIds
        .where((userId) => !attendeeUserIds.contains(userId))
        .toList();

    if (notAttendedUserIds.isEmpty) return [];

    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: notAttendedUserIds)
        .get();

    return userDocs.docs.map((userDoc) {
      final userId = userDoc.id;
      return {
        'name': userDoc['name'],
        'ic': userDoc['ic'],
        'gender': userDoc['gender'],
        'no_tel': userDoc['no_tel'],
        'address': userDoc['address'],
        'postcode': userDoc['postcode'],
        'state': userDoc['state'],
        'age_level': userDoc['age_level'],
        'household_category': userDoc['household_category'],
        'timestamp': null,
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
        pageFormat: PdfPageFormat.a4.landscape,
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
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FixedColumnWidth(100),
                  2: const pw.FixedColumnWidth(57),
                  3: const pw.FixedColumnWidth(85),
                  4: const pw.FixedColumnWidth(100),
                  5: const pw.FixedColumnWidth(80),
                  6: const pw.FixedColumnWidth(80),
                  7: const pw.FixedColumnWidth(80),
                  8: const pw.FixedColumnWidth(100),
                  9: const pw.FixedColumnWidth(120),
                },
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('IC',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Gender',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('No Tel',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Address',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Postcode',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('State',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Age Level',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Household Category',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Scanned Time',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ],
                  ),
                  ...attendees.map((attendee) {
                    return pw.TableRow(
                      children: [
                        pw.Text(attendee['name']),
                        pw.Text(attendee['ic'] ?? "N/A"),
                        pw.Text(attendee['gender'] ?? "N/A"),
                        pw.Text(attendee['no_tel'] ?? "N/A"),
                        pw.Text(attendee['address'] ?? "N/A"),
                        pw.Text(attendee['postcode'] ?? "N/A"),
                        pw.Text(attendee['state'] ?? "N/A"),
                        pw.Text(attendee['age_level'] ?? "N/A"),
                        pw.Text(attendee['household_category'] ?? "N/A"),
                        pw.Text(formatTimestamp(attendee['timestamp'])),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Registered but not attended Table
              pw.Text(
                'Registered but not attended:',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FixedColumnWidth(100),
                  2: const pw.FixedColumnWidth(57),
                  3: const pw.FixedColumnWidth(85),
                  4: const pw.FixedColumnWidth(100),
                  5: const pw.FixedColumnWidth(80),
                  6: const pw.FixedColumnWidth(80),
                  7: const pw.FixedColumnWidth(80),
                  8: const pw.FixedColumnWidth(100),
                  9: const pw.FixedColumnWidth(120),
                },
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('IC',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Gender',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('No Tel',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Address',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Postcode',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('State',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Age Level',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Household Category',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                      pw.Text('Scanned Time',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ],
                  ),
                  ...registeredButNoAttend.map((user) {
                    return pw.TableRow(
                      children: [
                        pw.Text(user['name']),
                        pw.Text(user['ic'] ?? "N/A"),
                        pw.Text(user['gender'] ?? "N/A"),
                        pw.Text(user['no_tel'] ?? "N/A"),
                        pw.Text(user['address'] ?? "N/A"),
                        pw.Text(user['postcode'] ?? "N/A"),
                        pw.Text(user['state'] ?? "N/A"),
                        pw.Text(user['age_level'] ?? "N/A"),
                        pw.Text(user['household_category'] ?? "N/A"),
                        pw.Text(formatTimestamp(user['timestamp'])),
                      ],
                    );
                  }).toList(),
                ],
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
      body: SingleChildScrollView(
        // Added SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
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
                    const Text(
                      'Attendees:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...attendees.map((attendee) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(attendee['name']),
                        subtitle: Text(formatTimestamp(attendee['timestamp'])),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    const Text(
                      'Registered but not attended:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...registeredButNoAttend.map((user) {
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(user['name']),
                        subtitle: Text(formatTimestamp(user['timestamp'])),
                      );
                    }).toList(),
                    ElevatedButton(
                      onPressed: () {
                        generateAndDownloadPdf(
                            attendees, registeredButNoAttend);
                      },
                      child: const Text('Download PDF'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
