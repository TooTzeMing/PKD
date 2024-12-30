import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnnouncementManagement extends StatefulWidget {
  const AnnouncementManagement({super.key});

  @override
  State<AnnouncementManagement> createState() => _AnnouncementManagementState();
}

class _AnnouncementManagementState extends State<AnnouncementManagement> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isTitleEmpty = true;
  bool _isContentEmpty = true;

  @override
  void initState() {
    super.initState();
    // Add listeners to controllers to update icon visibility
    _titleController.addListener(() {
      setState(() {
        _isTitleEmpty = _titleController.text.isEmpty;
      });
    });
    _contentController.addListener(() {
      setState(() {
        _isContentEmpty = _contentController.text.isEmpty;
      });
    });
  }

  void _addAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('announcements').add({
          'title': _titleController.text,
          'content': _contentController.text,
          'timestamp': Timestamp.now(),
        });

        _titleController.clear();
        _contentController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Announcement added successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding announcement: $e')));
        }
      }
    }
  }

  void _showEditDialog(DocumentSnapshot doc) {
    final editTitleController = TextEditingController(text: doc['title']);
    final editContentController = TextEditingController(text: doc['content']);
    bool isEditTitleEmpty = editTitleController.text.isEmpty;
    bool isEditContentEmpty = editContentController.text.isEmpty;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Add listeners for edit dialog controllers
          editTitleController.addListener(() {
            setState(() {
              isEditTitleEmpty = editTitleController.text.isEmpty;
            });
          });
          editContentController.addListener(() {
            setState(() {
              isEditContentEmpty = editContentController.text.isEmpty;
            });
          });

          return AlertDialog(
            title: const Text('Edit Announcement'),
            content: SingleChildScrollView(
              child: Form(
                key: GlobalKey<FormState>(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: editTitleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: const OutlineInputBorder(),
                        suffixIcon: isEditTitleEmpty
                            ? const Icon(Icons.warning_amber_rounded,
                                color: Colors.red)
                            : null,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: editContentController,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        border: const OutlineInputBorder(),
                        suffixIcon: isEditContentEmpty
                            ? const Icon(Icons.warning_amber_rounded,
                                color: Colors.red)
                            : null,
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Content is required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('announcements')
                        .doc(doc.id)
                        .update({
                      'title': editTitleController.text,
                      'content': editContentController.text,
                      'timestamp': Timestamp.now(),
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Announcement updated successfully')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error updating announcement: $e')));
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        backgroundColor: Colors.yellow,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isTitleEmpty
                          ? const Icon(Icons.warning_amber_rounded,
                              color: Colors.red)
                          : null,
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isContentEmpty
                          ? const Icon(Icons.warning_amber_rounded,
                              color: Colors.red)
                          : null,
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? 'Content is required' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text(
                      'Add Announcement',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No announcements yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          doc['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              doc['content'],
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            if (doc['timestamp'] != null)
                              Text(
                                'Posted: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['timestamp'] as Timestamp).toDate().toLocal())}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Announcement'),
                                  content: const Text(
                                      'Are you sure you want to delete this announcement?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('announcements')
                                              .doc(doc.id)
                                              .delete();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Announcement deleted successfully')));
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Error deleting announcement: $e')));
                                          }
                                        }
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
