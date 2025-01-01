import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class EditEventScreen extends StatefulWidget {
  final DocumentSnapshot eventDocument;

  const EditEventScreen({Key? key, required this.eventDocument})
      : super(key: key);

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _maxParticipantsController;

  // We'll store the event's existing date as a DateTime
  DateTime? _selectedDate;

  // We'll store the event's existing time as a TimeOfDay
  TimeOfDay? _selectedTime;

  // The category user selects
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();

    // Initialize text controllers with existing data
    _nameController = TextEditingController(text: widget.eventDocument['name']);
    _descriptionController =
        TextEditingController(text: widget.eventDocument['description']);
    _venueController =
        TextEditingController(text: widget.eventDocument['venue']);
    _maxParticipantsController = TextEditingController(
      text: widget.eventDocument['maxParticipants'].toString(),
    );

    // Initialize category
    _selectedCategory = widget.eventDocument['category'];

    // Convert the existing timestamp to DateTime, if available
    if (widget.eventDocument['date'] != null &&
        widget.eventDocument['date'] is Timestamp) {
      Timestamp existingDate = widget.eventDocument['date'] as Timestamp;
      _selectedDate = existingDate.toDate();
    }

    // Retrieve existing time if available (stored as a String, e.g. "10:30 AM")
    if (widget.eventDocument.data() is Map &&
        (widget.eventDocument.data() as Map).containsKey('time')) {
      final String? timeString = widget.eventDocument['time'];
      if (timeString != null && timeString.isNotEmpty) {
        _selectedTime = _parseTimeOfDay(timeString);
      }
    }
  }

  /// Attempt to parse a time string (e.g. "10:30 AM") into a TimeOfDay
  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final format = DateFormat.jm(); // e.g. "h:mm a"
      final DateTime dateTime = format.parse(timeString);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      // If parsing fails, return null
      return null;
    }
  }

  /// Pick a new date from a calendar
  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedDate ?? now;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Pick a new time from the native time picker
  Future<void> _pickTime() async {
    final TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  /// Update the existing event in Firestore
  Future<void> updateEvent() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _venueController.text.trim().isEmpty ||
        _maxParticipantsController.text.trim().isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields, including date and time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate max participants
    int maxParticipants;
    try {
      maxParticipants = int.parse(_maxParticipantsController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid number for maximum participants.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert selected date to timestamp
    Timestamp eventDate = Timestamp.fromDate(_selectedDate!);

    // Format the selected time as a String (e.g. "10:30 AM")
    final String formattedTime = _selectedTime!.format(context);

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventDocument.id)
          .update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'venue': _venueController.text.trim(),
        'maxParticipants': maxParticipants,
        'category': _selectedCategory,
        'date': eventDate,
        'time': formattedTime, // <-- store the updated time
      });
      Navigator.pop(context); // Go back after successful update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Checks if current category is valid; if not, reselect
  bool _selectedCategoryIsValid(List<String> categories) {
    return _selectedCategory != null && categories.contains(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        // Card to style the form
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Edit Event',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 30, thickness: 1),

                // Category
                _buildLabel('Category'),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    final categories =
                        docs.map((doc) => doc['name'] as String).toList();

                    // Ensure selected category is valid or fall back
                    if (!_selectedCategoryIsValid(categories)) {
                      _selectedCategory =
                          categories.isNotEmpty ? categories.first : null;
                    }

                    return DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Event Name
                _buildLabel('Event Name'),
                TextField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Enter event name'),
                ),
                const SizedBox(height: 20),

                // Description
                _buildLabel('Description'),
                TextField(
                  controller: _descriptionController,
                  decoration: _buildInputDecoration('Enter description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Venue
                _buildLabel('Venue'),
                TextField(
                  controller: _venueController,
                  decoration: _buildInputDecoration('Enter venue'),
                ),
                const SizedBox(height: 20),

                // Maximum Participants
                _buildLabel('Maximum Participants'),
                TextField(
                  controller: _maxParticipantsController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('Enter a number'),
                ),
                const SizedBox(height: 20),

                // Event Date
                _buildLabel('Event Date'),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: IgnorePointer(
                          ignoring: true,
                          child: TextField(
                            decoration: _buildInputDecoration(
                              _selectedDate == null
                                  ? 'Select event date'
                                  : DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate!),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                      tooltip: 'Select Date',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Event Time
                _buildLabel('Event Time'),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        child: IgnorePointer(
                          ignoring: true,
                          child: TextField(
                            decoration: _buildInputDecoration(
                              _selectedTime == null
                                  ? 'Select event time'
                                  : _selectedTime!.format(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: _pickTime,
                      tooltip: 'Select Time',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Save button at the bottom
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 30.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: updateEvent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to show consistent labels
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Helper method for consistent input decorations
  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 12.0,
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
