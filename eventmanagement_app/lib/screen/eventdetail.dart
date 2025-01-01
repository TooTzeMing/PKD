import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagement_app/screen/editevent.dart';
import 'package:eventmanagement_app/screen/AttendanceReportScreen.dart';
import 'package:eventmanagement_app/screen/RegisterReportScreen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:eventmanagement_app/services/global.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;
import 'package:intl/intl.dart'; // Make sure to import intl

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

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

  Future<void> printQRCode(String qrData, String eventName) async {
    final pdf = pw.Document();

    final qrCodeImage = await _generateQRCodeImage(qrData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                eventName,
                style: pw.TextStyle(
                  fontSize: 50,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Image(pw.MemoryImage(qrCodeImage), width: 300, height: 300),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<Uint8List> _generateQRCodeImage(String qrData) async {
    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );

    final image = await qrPainter.toImage(200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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

    // Prepare date display (if 'date' is a valid Timestamp)
    String eventDateString = 'No date provided';
    if (event.containsKey('date') && event['date'] is Timestamp) {
      DateTime dateTime = (event['date'] as Timestamp).toDate();
      eventDateString = DateFormat('d MMM, yyyy').format(dateTime);
    }

    // ADDED FOR TIME (Check if the "time" field exists)
    String eventTimeString = 'No time provided';
    if (event.containsKey('time') && event['time'] != null) {
      eventTimeString = event['time'] as String;
    }

    // Category
    String eventCategory = 'No category provided';
    if (event.containsKey('category')) {
      eventCategory = event['category'] ?? 'No category provided';
    }

    // ================
    // Non-admin UI
    // ================
    if (userRole != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            event['name'] ?? 'Event Details',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.yellow,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event['name'] ?? 'Event Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date
                  Row(
                    children: [
                      const Text(
                        'Date: ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        eventDateString,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ADDED FOR TIME
                  Row(
                    children: [
                      const Text(
                        'Time: ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        eventTimeString,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category: ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          eventCategory,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    event['description'] ?? 'No description provided',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  if (event.containsKey('maxParticipants')) ...[
                    Text(
                      'Maximum Participants:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event['maxParticipants'].toString(),
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ================
    // Admin UI
    // ================
    else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            event['name'] ?? 'Event Details',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.yellow,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventScreen(
                      eventDocument: eventDocument,
                    ),
                  ),
                ).then((_) {
<<<<<<< HEAD
=======
                  // Refresh the event details after returning
>>>>>>> f19444cbed532ed0724968100af35caad10ac4ca
                  fetchEvent();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteEvent(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // QR code card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      QrImageView(
                        data: qrData,
                        size: 300.0,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          printQRCode(qrData, event['name'] ?? 'Event');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F8695),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 24.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Print QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Event details card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['name'] ?? 'Event Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Date
                      Row(
                        children: [
                          const Text(
                            'Date: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            eventDateString,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ADDED FOR TIME
                      Row(
                        children: [
                          const Text(
                            'Time: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            eventTimeString,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Category
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              eventCategory,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        event['description'] ?? 'No description provided',
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      // Maximum Participants
                      if (event.containsKey('maxParticipants')) ...[
                        Text(
                          'Maximum Participants:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          event['maxParticipants'].toString(),
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Attendance Report
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F8695),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 24.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'View Attendance Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

<<<<<<< HEAD
              // Registration Report button
=======
              // Registration Report
>>>>>>> f19444cbed532ed0724968100af35caad10ac4ca
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterReportScreen(
                        eventId: widget.eventId,
                        eventName: event['name'] ?? 'Event',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F8695),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 24.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'View Registration Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
