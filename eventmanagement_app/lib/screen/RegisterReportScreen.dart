import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class RegisterReportScreen extends StatelessWidget {
  final String eventId;
  final String eventName;

  const RegisterReportScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  Future<List<Map<String, dynamic>>> fetchRegisteredUsers(
      {bool detailed = false}) async {
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(eventId)
        .get();

    if (!attendanceSnapshot.exists) {
      return [];
    }

    // Get the list of registered users
    List<dynamic> registeredUsers = attendanceSnapshot['registeredUsers'] ?? [];

    // Extract userIds from registered users
    List<String> registeredUserIds =
        registeredUsers.map((user) => user['userId'] as String).toList();

    if (registeredUserIds.isEmpty) return [];

    // Fetch user details for registered user IDs
    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: registeredUserIds)
        .get();

    // Map user details with their respective timestamps
    return userDocs.docs.map((userDoc) {
      final userId = userDoc.id;
      final userInfo =
          registeredUsers.firstWhere((user) => user['userId'] == userId);

      if (detailed) {
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
          'timestamp': userInfo['timestamp'],
        };
      } else {
        return {
          'name': userDoc['name'],
          'timestamp': userInfo['timestamp'],
        };
      }
    }).toList();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final dateTime = timestamp.toDate();
    return DateFormat('HH:mm:ss a dd-MM-yyyy').format(dateTime);
  }

  Future<void> generateAndDownloadPdf() async {
    final registeredUsers =
        await fetchRegisteredUsers(detailed: true); // Fetch full details
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$eventName - Registration Report',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),

              // Registered Users Table
              pw.Text(
                'Registered Users:',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: [
                  'Name',
                  'IC',
                  'Gender',
                  'Phone',
                  'Address',
                  'Postcode',
                  'State',
                  'Age Level',
                  'Household Category',
                  'Registered Time'
                ],
                data: registeredUsers.map((user) {
                  return [
                    user['name'],
                    user['ic'],
                    user['gender'],
                    user['no_tel'],
                    user['address'],
                    user['postcode'],
                    user['state'],
                    user['age_level'],
                    user['household_category'],
                    formatTimestamp(user['timestamp']),
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Registration_Report_$eventName.pdf',
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow, // Set the background color
        title: Text(
          eventName, // Display the event name
          style: const TextStyle(
            color: Colors.black, // Set text color
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // Center the title
        iconTheme: const IconThemeData(
            color: Colors.black), // Change back button color
        elevation: 0, // Remove shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registered Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder(
                future: fetchRegisteredUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final registeredUsers = snapshot.data ?? [];

                  if (registeredUsers.isEmpty) {
                    return const Text('No registered users available.');
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            const Text(
                              'Registered:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...registeredUsers.map((user) {
                              return ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(user['name']),
                                subtitle: Text(
                                    'Registered: ${formatTimestamp(user['timestamp'])}'),
                              );
                            }),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          generateAndDownloadPdf();
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
