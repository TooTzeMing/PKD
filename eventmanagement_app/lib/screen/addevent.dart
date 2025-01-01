import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting the selected date

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({Key? key}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  // Controllers for event details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _maxParticipantsController =
      TextEditingController();

  // Controller for adding custom category
  final TextEditingController _customCategoryController =
      TextEditingController();

  // The list of category documents from Firestore
  // Each item is a map with { 'id': <docId>, 'name': <categoryName> }
  List<Map<String, dynamic>> _categoryDocs = [];

  // The name of the selected category from the dropdown
  String? _selectedCategoryName;

  // A flag to show progress when loading categories
  bool _isLoadingCategories = true;

  // The [DateTime] selected via the calendar date picker
  DateTime? _selectedDate;

  // The TimeOfDay for the event
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  /// Fetch categories from Firestore and store them in [_categoryDocs].
  /// We also add a sentinel "Add Custom Category" item for user convenience.
  Future<void> _fetchCategories() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      setState(() {
        _categoryDocs = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'] ?? '',
          };
        }).toList();

        // Add sentinel item for adding a custom category
        _categoryDocs.add({'id': 'custom', 'name': 'Add Custom Category'});
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  /// Open a native DatePicker for selecting [DateTime].
  /// Store the chosen date in [_selectedDate].
  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    // If user selected a date and didn't cancel
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Open a native TimePicker for selecting [TimeOfDay].
  /// Store the chosen time in [_selectedTime].
  Future<void> _pickTime() async {
    final TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// Validate and submit the new event to Firestore
  Future<void> _handleSubmit() async {
    // Basic field checks
    if (_nameController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _venueController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _maxParticipantsController.text.isEmpty ||
        _selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields, including date and time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate maxParticipants
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

    // Convert the selectedDate to a Firebase Timestamp
    // For the date portion only
    Timestamp eventDate = Timestamp.fromDate(_selectedDate!);

    // Format the TimeOfDay into a readable string (e.g., "10:30 AM")
    final String formattedTime = _selectedTime!.format(context);

    // Prepare the data for Firestore
    Map<String, dynamic> eventData = {
      'name': _nameController.text.trim(),
      'date': eventDate,
      'time': formattedTime, // Store the time as a string
      'venue': _venueController.text.trim(),
      'description': _descriptionController.text.trim(),
      'maxParticipants': maxParticipants,
      'category': _selectedCategoryName,
    };

    try {
      // Add event data to Firestore
      final eventRef =
          await FirebaseFirestore.instance.collection('events').add(eventData);
      final String eventId = eventRef.id;

      // Store the generated event ID back into Firestore (optional)
      await eventRef.update({'id': eventId});

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Event successfully added!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back from AddEventScreen
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

  /// Show a dialog to add a custom category to Firestore.
  /// After adding, we refresh the categories list.
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Custom Category'),
          content: TextField(
            controller: _customCategoryController,
            decoration: const InputDecoration(hintText: 'Category Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                String newCategory = _customCategoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  // Add new category to Firestore
                  await FirebaseFirestore.instance
                      .collection('categories')
                      .add({'name': newCategory});

                  _customCategoryController.clear();
                  Navigator.of(context).pop();
                  // Refresh categories
                  await _fetchCategories();
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Show a dialog where the user can remove (delete) a category from Firestore.
  /// We skip the sentinel "Add Custom Category".
  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final displayableCategories =
            _categoryDocs.where((cat) => cat['id'] != 'custom').toList();

        return AlertDialog(
          title: const Text('Manage Categories'),
          content: displayableCategories.isEmpty
              ? const Text('No categories available.')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: displayableCategories.map((cat) {
                      return ListTile(
                        title: Text(cat['name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool? confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text(
                                      'Are you sure you want to delete "${cat['name']}" category?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text('Delete'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              await _removeCategory(cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  /// Remove a category from Firestore by its document ID.
  /// Validation: If the category is still used by any event, disallow deletion.
  Future<void> _removeCategory(Map<String, dynamic> cat) async {
    final String docId = cat['id'] as String;
    final String catName = cat['name'] as String;

    try {
      final usedByEvents = await FirebaseFirestore.instance
          .collection('events')
          .where('category', isEqualTo: catName)
          .limit(1)
          .get();

      if (usedByEvents.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot delete "$catName". It\'s used by existing events.\n'
              'Delete those events or change their categories first.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('categories').doc(docId).delete();

      await _fetchCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$catName" removed successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main layout
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoadingCategories)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Manage Categories',
              onPressed: _showManageCategoriesDialog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Create a New Event',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 30, thickness: 1),

                if (_isLoadingCategories)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildLabel('Select Category'),
                  DropdownButton<String>(
                    value: _selectedCategoryName,
                    isExpanded: true,
                    hint: const Text('Choose a category'),
                    items: _categoryDocs.map<DropdownMenuItem<String>>((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['name'],
                        child: Text(cat['name']),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue == 'Add Custom Category') {
                        _showAddCategoryDialog();
                      } else {
                        setState(() {
                          _selectedCategoryName = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Event Name
                _buildLabel('Event Name'),
                TextField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Enter event name'),
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

                // Venue
                _buildLabel('Venue'),
                TextField(
                  controller: _venueController,
                  decoration: _buildInputDecoration('Enter venue'),
                ),
                const SizedBox(height: 20),

                // Description
                _buildLabel('Description'),
                TextField(
                  controller: _descriptionController,
                  decoration: _buildInputDecoration('Enter a brief description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Maximum Participants
                _buildLabel('Maximum Participants'),
                TextField(
                  controller: _maxParticipantsController,
                  decoration: _buildInputDecoration('Enter a number'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 40.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build consistent text labels
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

  /// Helper method to build consistent input decorations
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
    _venueController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }
}
