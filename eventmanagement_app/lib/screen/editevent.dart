import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventScreen extends StatefulWidget {
  final DocumentSnapshot eventDocument;
  const EditEventScreen({super.key, required this.eventDocument});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _maxParticipantsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.eventDocument['name']);
    _descriptionController =
        TextEditingController(text: widget.eventDocument['description']);
    _venueController =
        TextEditingController(text: widget.eventDocument['venue']);
    _maxParticipantsController = TextEditingController(
        text: widget.eventDocument['maxParticipants'].toString());
  }

  void updateEvent() async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventDocument.id)
        .update({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'venue': _venueController.text,
      'maxParticipants': int.parse(_maxParticipantsController.text)
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: updateEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(labelText: 'Venue'),
            ),
            TextField(
              controller: _maxParticipantsController,
              decoration:
                  const InputDecoration(labelText: 'Maximum Participants'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }
}
