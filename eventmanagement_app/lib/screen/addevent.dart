//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
//import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _maxParticipantsController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
 // final ImagePicker _picker = ImagePicker();
//  XFile? _imageFile;
  String? _selectedCategory;
  List<String> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  void _fetchCategories() async {
    try {
      var categoryCollection = await FirebaseFirestore.instance.collection('categories').get();
      var fetchedCategories = categoryCollection.docs.map((doc) => doc.data()['name'] as String).toList();
      setState(() {
        _categories = fetchedCategories;
        _categories.add('Add Custom Category'); // Add custom input option
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

/*  void _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected.'), backgroundColor: Colors.red),
      );
    }
  } 

  Future<String?> _uploadImage(XFile image) async {
    String fileName = 'events/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(File(image.path));
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  } */

  void _handleSubmit() async {
    if (_nameController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _venueController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _maxParticipantsController.text.isEmpty ||
        _selectedCategory == null //||
       // _imageFile == null
        ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    Timestamp eventDate;
    try {
      DateTime parsedDate = DateTime.parse(_dateController.text);
      eventDate = Timestamp.fromDate(parsedDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid date format. Please use YYYY-MM-DD.'), backgroundColor: Colors.red),
      );
      return;
    }

    int maxParticipants;
    try {
      maxParticipants = int.parse(_maxParticipantsController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid number for maximum participants.'), backgroundColor: Colors.red),
      );
      return;
    }

   /* String? imageUrl = await _uploadImage(_imageFile!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image.'), backgroundColor: Colors.red),
      );
      return;
    } */

    Map<String, dynamic> eventData = {
      'name': _nameController.text,
      'date': eventDate,
      'venue': _venueController.text,
      'description': _descriptionController.text,
      'maxParticipants': maxParticipants,
      'category': _selectedCategory,
  //    'imageUrl': imageUrl,
    };

    try {
      DocumentReference eventRef = await FirebaseFirestore.instance.collection('events').add(eventData);
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
                Navigator.of(context).pop(); // Optionally close the AddEventScreen after success
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Custom Category'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              hintText: 'Category Name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                String newCategory = _categoryController.text;
                if (newCategory.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('categories').add({'name': newCategory});
                  _categoryController.clear();
                  Navigator.of(context).pop();
                  _fetchCategories(); // Refresh categories
                }
              },
            ),
          ],
        );
      },
    );
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
            if (!_isLoadingCategories) ...[
              DropdownButton<String>(
                value: _selectedCategory,
                hint: const Text('Select Category'),
                items: _categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue == 'Add Custom Category') {
                    _showAddCategoryDialog();
                  } else {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
         /*   GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _imageFile == null
                    ? Icon(Icons.camera_alt, color: Colors.grey[800])
                    : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
              ),
            ), */
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
    _categoryController.dispose(); // Dispose the category controller
    super.dispose();
  }
}