import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eventmanagement_app/screen/scansuccessscreen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false; // To prevent multiple scans

  // Function to handle the scan result
  void handleScanResult(
      BuildContext context, String scannedEventId, String userId) async {
    final attendanceRef = FirebaseFirestore.instance.collection('attendance');

    try {
      // Check if a document for the scannedEventId already exists
      DocumentReference eventDocRef = attendanceRef.doc(scannedEventId);
      DocumentSnapshot eventDocSnapshot = await eventDocRef.get();

      // Check if the document exists and has the 'attendees' field
      if (eventDocSnapshot.exists && eventDocSnapshot.data() != null) {
        Map<String, dynamic>? data =
            eventDocSnapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('attendees')) {
          // The 'attendees' field exists
          List<dynamic> attendees = data['attendees'] ?? [];

          if (attendees.any((attendee) => attendee['userId'] == userId)) {
            // User has already scanned for this event
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScanSuccessScreen(
                  eventId: scannedEventId,
                  isDuplicateScan: true, // Pass the duplicate scan flag
                ),
              ),
            );
          } else {
            // Add the userId to the attendees array
            await eventDocRef.update({
              'attendees': FieldValue.arrayUnion([
                {
                  'userId': userId,
                  'timestamp': DateTime.now(), // Generate timestamp locally
                },
              ]),
            });

            // Navigate to success screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => ScanSuccessScreen(
                  eventId: scannedEventId,
                  isDuplicateScan: false, // Pass the success flag
                ),
              ),
              (Route<dynamic> route) => false, // Remove all previous routes
            );
          }
        } else {
          // 'attendees' field does not exist; create and add the user
          await eventDocRef.update({
            'eventId': scannedEventId,
            'attendees': FieldValue.arrayUnion([
              {
                'userId': userId,
                'timestamp': DateTime.now(), // Generate timestamp locally
              },
            ]),
          });

          // Navigate to success screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ScanSuccessScreen(
                eventId: scannedEventId,
                isDuplicateScan: false, // Pass the success flag
              ),
            ),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        }
      } else {
        // The document does not exist; create it
        await eventDocRef.set({
          'eventId': scannedEventId,
        }, SetOptions(merge: true)); // This ensures merging with existing data

        await eventDocRef.update({
          'attendees': FieldValue.arrayUnion([
            {
              'userId': userId,
              'timestamp': DateTime.now(), // Generate timestamp locally
            },
          ]),
        });

        // Navigate to success screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ScanSuccessScreen(
              eventId: scannedEventId,
              isDuplicateScan: false, // Pass the success flag
            ),
          ),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Handle errors
      print('Error handling scan result: $e');
      setState(() {
        _isProcessing = false; // Reset the flag in case of an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
            ),
            onDetect: (capture) {
              if (!_isProcessing) {
                setState(() {
                  _isProcessing = true;
                });

                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    final scannedEventId = barcode.rawValue!;
                    final userId = _auth.currentUser?.uid ?? '';

                    // Handle the scan result
                    handleScanResult(context, scannedEventId, userId);

                    // After scanning, reset the processing flag
                    Future.delayed(const Duration(seconds: 2), () {
                      setState(() {
                        _isProcessing = false;
                      });
                    });
                    break;
                  }
                }
              }
            },
          ),
          // Camera overlay
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Instruction text
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align the QR code within the frame to scan',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
