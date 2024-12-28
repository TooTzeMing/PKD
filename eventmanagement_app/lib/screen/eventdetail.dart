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

  Future<void> printQRCode(String qrData, String eventName) async {
    final pdf = pw.Document();

    // Generate a QR code image
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
                style:
                    pw.TextStyle(fontSize: 50, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Image(pw.MemoryImage(qrCodeImage), width: 550, height: 550),
            ],
          );
        },
      ),
    );

    // Trigger printing
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

    // Convert QR code to an image
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
    if (userRole != 'admin') {
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
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Description: ${event['description'] ?? 'No description provided'}',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      );
    } else {
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
            children: <Widget>[
              Center(
                child: QrImageView(
                  data: qrData,
                  size: 340.0,
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    printQRCode(qrData, event['name'] ?? 'Event');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(
                        255, 200, 88, 0.8), // Background color
                    foregroundColor: Colors.white, // Text color
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 24.0), // Padding
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30.0), // Rounded corners
                    ),
                    elevation: 5, // Shadow effect
                  ),
                  child: const Text(
                    'Print QR Code',
                    style: TextStyle(
                      fontSize: 16, // Font size
                      fontWeight: FontWeight.bold, // Font weight
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Description: ${event['description'] ?? 'No description provided'}',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              Text(
                'Maximum Participants: ${event['maxParticipants'].toString()}',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
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
              const SizedBox(height: 20), // Spacing between buttons
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
                child: const Text('View Registration Report'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
