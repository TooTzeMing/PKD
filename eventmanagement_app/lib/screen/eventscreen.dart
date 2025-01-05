// Highlighted changes with  <-- ADDED

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventmanagement_app/screen/eventdetail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eventmanagement_app/services/global.dart';

// If you have a global variable or method to get userRole, import or define it

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
              stream: _firestore
                  .collection('events')
                  .orderBy('date') // default ascending by date
                  .snapshots(),
              builder: (context, snapshot) {
                // Handle errors and loading states
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> documents = snapshot.data!.docs;

                if (userRole != 'admin') {
                  final now = DateTime.now();
                  documents = documents.where((doc) {
                    if (doc['date'] != null && doc['date'] is Timestamp) {
                      final DateTime eventDate =
                          (doc['date'] as Timestamp).toDate();
                      // Show only upcoming (non-expired) events
                      return eventDate.isAfter(now);
                    } else {
                      // If no date, treat it as no event or skip
                      return false;
                    }
                  }).toList();
                }

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

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: documents.map((DocumentSnapshot document) {
                    Map<String, dynamic> event =
                        document.data()! as Map<String, dynamic>;

                    String formattedDate =
                        event['date'] != null && event['date'] is Timestamp
                            ? formatDate(event['date'] as Timestamp)
                            : 'No date';

                    String eventId = document.id;
                    bool isRegistered = registeredEvents.containsKey(eventId);

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

  // Filter dialog, category date range, etc.
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

  void pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked.start.isBefore(picked.end)) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        isDateFilterActive = true;
      });
    } else if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid date range selected. Please try again.'),
        ),
      );
    }
  }

  // mok change
  // Build each event tile
  Widget buildEventTile(
    BuildContext context,
    Map<String, dynamic> event,
    String formattedDate,
    String eventId,
    bool isRegistered,
  ) {
    return GestureDetector(
      onTap: () {
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
              Text(
                event['venue'] ?? 'Venue',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8.0),

              // Fetch maxParticipants and registered users
              FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('events').doc(eventId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return const Text("Error fetching event data.");
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("Event not found.");
                  }

                  var eventData = snapshot.data!.data() as Map<String, dynamic>;

                  int maxParticipants = eventData['maxParticipants'] ?? 0;

                  // Get the count of registered users
                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        _firestore.collection('attendance').doc(eventId).get(),
                    builder: (context, attendanceSnapshot) {
                      if (attendanceSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (attendanceSnapshot.hasError) {
                        return const Text("Error fetching attendance data.");
                      }

                      int registeredUsersCount = 0;
                      if (attendanceSnapshot.hasData &&
                          attendanceSnapshot.data != null) {
                        registeredUsersCount = (attendanceSnapshot
                                .data!['registeredUsers'] as List)
                            .length;
                      }

                      bool isFull = registeredUsersCount >= maxParticipants;

                      return Row(
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
                                onConfirm: () =>
                                    unregisterFromEvent(event['name'], eventId),
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
                              onPressed: isFull
                                  ? null // Disable the button if event is full
                                  : () => showConfirmationDialog(
                                        context,
                                        title: 'Register for ${event['name']}?',
                                        content:
                                            'Are you sure you want to register for this event?',
                                        onConfirm: () => registerForEvent(
                                            event['name'], eventId),
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isFull ? Colors.grey : Colors.lightGreen,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(isFull ? 'Event Full' : 'Register'),
                            ),
                          const SizedBox(width: 8),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  } // mok change

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
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  void registerForEvent(String eventName, String eventId) async {
    final User? user = _auth.currentUser;
    if (user != null && !registeredEvents.containsKey(eventId)) {
      try {
        await _firestore.collection('registration').add({
          'registereduser': user.uid,
          'registeredevent': eventId,
        });

        final attendanceDoc = _firestore.collection('attendance').doc(eventId);
        await attendanceDoc.set({
          'registeredUsers': FieldValue.arrayUnion([
            {
              'userId': user.uid,
              'timestamp': DateTime.now(),
            }
          ]),
        }, SetOptions(merge: true));

        setState(() {
          registeredEvents[eventId] = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registered for $eventName')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $error')),
        );
      }
    }
  }

  void unregisterFromEvent(String eventName, String eventId) async {
    final User? user = _auth.currentUser;
    if (user != null && registeredEvents.containsKey(eventId)) {
      try {
        var registrations = await _firestore
            .collection('registration')
            .where('registereduser', isEqualTo: user.uid)
            .where('registeredevent', isEqualTo: eventId)
            .get();
        for (var doc in registrations.docs) {
          await _firestore.collection('registration').doc(doc.id).delete();
        }

        final attendanceDocRef =
            _firestore.collection('attendance').doc(eventId);
        final attendanceDoc = await attendanceDocRef.get();

        if (attendanceDoc.exists) {
          List<dynamic> registeredUsers =
              (attendanceDoc.data()?['registeredUsers'] as List<dynamic>?) ??
                  [];

          Map<String, dynamic>? userEntry = registeredUsers.firstWhere(
            (entry) => entry['userId'] == user.uid,
            orElse: () => null,
          );

          if (userEntry != null) {
            await attendanceDocRef.update({
              'registeredUsers': FieldValue.arrayRemove([userEntry]),
            });

            final updatedDoc = await attendanceDocRef.get();
            if (!updatedDoc.exists ||
                updatedDoc.data() == null ||
                updatedDoc.data()!.isEmpty) {
              await attendanceDocRef.delete();
            }
          }
        }

        setState(() {
          registeredEvents.remove(eventId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unregistered from $eventName')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unregistration failed: $error')),
        );
      }
    }
  }
}
