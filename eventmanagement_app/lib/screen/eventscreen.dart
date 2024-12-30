import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventmanagement_app/screen/eventdetail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({Key? key}) : super(key: key);

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();

  Map<String, bool> registeredEvents = {};
  List<String> categories = [];

  String? selectedCategory;
  bool isFilterActive = false;

  // Variables for date range filtering
  bool isDateFilterActive = false;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    fetchRegisteredEvents();
    fetchCategories();
  }

  // Fetch the events user has registered for
  void fetchRegisteredEvents() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      var registrations = await _firestore
          .collection('registration')
          .where('registereduser', isEqualTo: user.uid)
          .get();

      var registeredEventIds = {
        for (var doc in registrations.docs)
          doc.data()['registeredevent'] as String: true
      };

      setState(() {
        registeredEvents = registeredEventIds;
      });
    }
  }

  // Fetch the categories from Firestore
  Future<void> fetchCategories() async {
    try {
      var snapshot = await _firestore.collection('categories').get();
      var fetchedCategories =
          snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
      setState(() {
        categories = fetchedCategories;
      });
    } catch (e) {
      print("Failed to fetch categories: $e");
    }
  }

  // Format a Firestore Timestamp to a readable date string
  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('d MMM, yyyy').format(dateTime);
  }

  // Main build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar and filter icon
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Search text field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Event Name',
                      suffixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                // Filter icon button
                IconButton(
                  icon: Icon(
                    (isFilterActive || isDateFilterActive)
                        ? Icons.filter_alt_off
                        : Icons.filter_list,
                  ),
                  onPressed: showFilterDialog,
                  tooltip: (isFilterActive || isDateFilterActive)
                      ? 'Clear Filter'
                      : 'Filter by Category or Date',
                ),
              ],
            ),
          ),

          // Display the list of events
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('events').orderBy('date').snapshots(),
              builder: (context, snapshot) {
                // Handle errors and loading states
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Convert snapshot data to a list of documents
                List<DocumentSnapshot> documents = snapshot.data!.docs;

                // Filter by search text (event name)
                if (_searchController.text.isNotEmpty) {
                  documents = documents
                      .where((doc) => doc['name']
                          .toString()
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()))
                      .toList();
                }

                // Filter by category if active
                if (isFilterActive && selectedCategory != null) {
                  documents = documents
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)
                              .containsKey('category') &&
                          doc['category'] == selectedCategory)
                      .toList();
                }

                // Filter by date range if active
                if (isDateFilterActive &&
                    selectedStartDate != null &&
                    selectedEndDate != null) {
                  documents = documents.where((doc) {
                    DateTime eventDate = (doc['date'] as Timestamp).toDate();

                    // Filter only events within the chosen date range
                    // Subtract 1 day from start, add 1 day to end to make it inclusive
                    return eventDate.isAfter(
                          selectedStartDate!.subtract(const Duration(days: 1)),
                        ) &&
                        eventDate.isBefore(
                          selectedEndDate!.add(const Duration(days: 1)),
                        );
                  }).toList();
                }

                // If no events match the filters, display a message
                if (documents.isEmpty) {
                  return const Center(
                    child: Text("No event found. Please try another filter."),
                  );
                }

                // Display the list of filtered events
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: documents.map((DocumentSnapshot document) {
                    Map<String, dynamic> event =
                        document.data()! as Map<String, dynamic>;

                    // Format the event date
                    String formattedDate =
                        event['date'] != null && event['date'] is Timestamp
                            ? formatDate(event['date'] as Timestamp)
                            : 'No date';

                    String eventId = document.id;
                    bool isRegistered = registeredEvents.containsKey(eventId);

                    // Build each event tile
                    return buildEventTile(
                      context,
                      event,
                      formattedDate,
                      eventId,
                      isRegistered,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Shows the main filter dialog (category or date)
  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Events'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  title: const Text('Sort by category'),
                  onTap: () {
                    Navigator.pop(context);
                    showCategorySelection();
                  },
                ),
                ListTile(
                  title: const Text('Sort by date'),
                  onTap: () {
                    Navigator.pop(context);
                    pickDateRange();
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Clear Filter'),
              onPressed: () {
                setState(() {
                  selectedCategory = null;
                  selectedStartDate = null;
                  selectedEndDate = null;
                  isFilterActive = false;
                  isDateFilterActive = false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Shows the category selection dialog
  void showCategorySelection() async {
    await fetchCategories();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort by category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: categories.map((String category) {
                return ListTile(
                  title: Text(category),
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      isFilterActive = true;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Picks a date range using Flutter's built-in showDateRangePicker
  void pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    // Validate the picked date range
    if (picked != null && picked.start.isBefore(picked.end)) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        isDateFilterActive = true;
      });
    } else if (picked != null) {
      // If the user selects a range but the start date is not before the end date,
      // show a Snackbar with an error message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid date range selected. Please try again.'),
        ),
      );
    }
  }

  // Builds each event tile in the list
  Widget buildEventTile(
    BuildContext context,
    Map<String, dynamic> event,
    String formattedDate,
    String eventId,
    bool isRegistered,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to a detail screen for the selected event
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(eventId: eventId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.0,
              spreadRadius: 2.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Name & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event['name'] ?? 'Event Name',
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[850],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              // Venue
              Text(
                event['venue'] ?? 'Venue',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8.0),

              // Register / Unregister Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isRegistered)
                    ElevatedButton(
                      onPressed: () => showConfirmationDialog(
                        context,
                        title:
                            'Remove Registration for ${event['name']}?',
                        content:
                            'Are you sure you want to remove your registration for this event?',
                        onConfirm: () => unregisterFromEvent(
                          event['name'],
                          eventId,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Remove'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => showConfirmationDialog(
                        context,
                        title: 'Register for ${event['name']}?',
                        content:
                            'Are you sure you want to register for this event?',
                        onConfirm: () => registerForEvent(
                          event['name'],
                          eventId,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.black, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show a confirmation dialog for registering or unregistering
  void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onConfirm(); // Perform the action (register/unregister)
              },
            ),
          ],
        );
      },
    );
  }

  // Register for an event
  void registerForEvent(String eventName, String eventId) async {
    final User? user = _auth.currentUser;
    if (user != null && !registeredEvents.containsKey(eventId)) {
      try {
        // Add the registration to the 'registration' collection
        await _firestore.collection('registration').add({
          'registereduser': user.uid,
          'registeredevent': eventId,
        });

        // Update the 'attendance' collection
        final attendanceDoc = _firestore.collection('attendance').doc(eventId);
        await attendanceDoc.set({
          'registeredUsers': FieldValue.arrayUnion([
            {
              'userId': user.uid,
              'timestamp': DateTime.now(), // Add timestamp
            }
          ]),
        }, SetOptions(merge: true));

        // Update the local state
        setState(() {
          registeredEvents[eventId] = true;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registered for $eventName')),
        );
      } catch (error) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $error')),
        );
      }
    }
  }

  // Unregister from an event
  void unregisterFromEvent(String eventName, String eventId) async {
    final User? user = _auth.currentUser;
    if (user != null && registeredEvents.containsKey(eventId)) {
      try {
        // Remove the registration from the 'registration' collection
        var registrations = await _firestore
            .collection('registration')
            .where('registereduser', isEqualTo: user.uid)
            .where('registeredevent', isEqualTo: eventId)
            .get();
        for (var doc in registrations.docs) {
          await _firestore.collection('registration').doc(doc.id).delete();
        }

        // Fetch the attendance document to find the exact entry for this user
        final attendanceDocRef =
            _firestore.collection('attendance').doc(eventId);
        final attendanceDoc = await attendanceDocRef.get();

        if (attendanceDoc.exists) {
          List<dynamic> registeredUsers =
              (attendanceDoc.data()?['registeredUsers'] as List<dynamic>?) ?? [];

          Map<String, dynamic>? userEntry = registeredUsers.firstWhere(
            (entry) => entry['userId'] == user.uid,
            orElse: () => null,
          );

          if (userEntry != null) {
            // Remove the user's entry from the 'registeredUsers' array
            await attendanceDocRef.update({
              'registeredUsers': FieldValue.arrayRemove([userEntry]),
            });

            // After removing the user, check if 'registeredUsers' is empty
            final updatedDoc = await attendanceDocRef.get();

            if (!updatedDoc.exists ||
                updatedDoc.data() == null ||
                updatedDoc.data()!.isEmpty) {
              // If the document data is empty, delete the document
              await attendanceDocRef.delete();
            }
          }
        }

        // Update the local state
        setState(() {
          registeredEvents.remove(eventId);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unregistered from $eventName')),
        );
      } catch (error) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unregistration failed: $error')),
        );
      }
    }
  }
}
