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

    // Check if the user has already scanned for this event
    QuerySnapshot existingRecord = await attendanceRef
        .where('eventId', isEqualTo: scannedEventId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existingRecord.docs.isNotEmpty) {
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
      // Add new record to the attendance database
      await attendanceRef.add({
        'eventId': scannedEventId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Navigate to success screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanSuccessScreen(
            eventId: scannedEventId,
            isDuplicateScan: false, // Pass the success flag
          ),
        ),
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
                    Future.delayed(Duration(seconds: 2), () {
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
          Positioned(
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
