import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _maxParticipantsController =
      TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  void _handleSubmit() async {
    // Check if any field is empty
    if (_nameController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _venueController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _maxParticipantsController.text.isEmpty ||
        _budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
        const SnackBar(
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
        const SnackBar(
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
      'budget': _budgetController.text,
    };

    try {
      DocumentReference eventRef =
          await FirebaseFirestore.instance.collection('events').add(eventData);

      String eventId = eventRef.id;

      await eventRef.update({'id': eventId});

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Event successfully added!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context)
                    .pop(); // Optionally close the AddEventScreen after success
              },
              child: const Text('OK'),
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
        title: const Text('Add Event'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Event Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Event Date',
                hintText: 'e.g., YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Venue',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _maxParticipantsController,
              decoration: const InputDecoration(
                labelText: 'Maximum Participants',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Budget',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: const Text('Submit'),
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
    _budgetController.dispose();
    super.dispose();
  }
}
