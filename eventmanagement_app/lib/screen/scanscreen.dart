import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = true;

  void _onScan(Barcode barcode) {
    final String? qrData = barcode.rawValue;

    if (qrData != null && _isScanning) {
      setState(() {
        _isScanning = false; // Prevent multiple scans
      });

      // Navigate back with scanned data or handle attendance here
      Navigator.pop(context, qrData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.popAndPushNamed(context, "/generate");
            }, 
            icon: Icon(
              Icons.qr_code,
            ),
          ),
        ],
      ),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          // `barcodeCapture` contains the list of barcodes detected
          final List<Barcode> barcodes = barcodeCapture.barcodes;
          for (final Barcode barcode in barcodes) {
            _onScan(barcode);
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isScanning = true; // Reset scanning state when the screen is created
  }
}
