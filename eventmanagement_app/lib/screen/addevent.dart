import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({Key? key}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _maxParticipantsController = TextEditingController();

  void _handleSubmit() async {
  // Check if any field is empty
  if (_nameController.text.isEmpty ||
      _dateController.text.isEmpty ||
      _venueController.text.isEmpty ||
      _descriptionController.text.isEmpty ||
      _maxParticipantsController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please fill in all fields'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Attempt to parse date from input
  Timestamp eventDate;
  try {
    DateTime parsedDate = DateTime.parse(_dateController.text);
    eventDate = Timestamp.fromDate(parsedDate);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid date format. Please use YYYYMMDD.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Attempt to parse maximum participants
  int maxParticipants;
  try {
    maxParticipants = int.parse(_maxParticipantsController.text);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid number for maximum participants.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  Map<String, dynamic> eventData = {
    'name': _nameController.text,
    'date': eventDate,
    'venue': _venueController.text,
    'description': _descriptionController.text,
    'maxParticipants': maxParticipants,
  };

  try {
    await FirebaseFirestore.instance.collection('events').add(eventData);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text('Event successfully added!'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Optionally close the AddEventScreen after success
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to add event: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Event Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Event Date',
                hintText: 'e.g., YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _venueController,
              decoration: InputDecoration(
                labelText: 'Venue',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _maxParticipantsController,
              decoration: InputDecoration(
                labelText: 'Maximum Participants',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }
}
