import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventmanagement_app/screen/eventdetail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

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

  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('d MMM').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    fetchRegisteredEvents();
    fetchCategories();
  }

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

  void showCategoryFilterDialog() {
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
                      Navigator.pop(context);
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Clear Filter'),
              onPressed: () {
                setState(() {
                  selectedCategory = null;
                  isFilterActive = false;
                });
                Navigator.pop(context);
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
              (attendanceDoc.data()?['registeredUsers'] as List<dynamic>?) ??
                  [];

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
            List<dynamic> updatedRegisteredUsers =
                updatedDoc.data()?['registeredUsers'] ?? [];

            // If 'registeredUsers' is empty, delete the document
            if (updatedRegisteredUsers.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Event Name',
                      suffixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: Icon(isFilterActive
                      ? Icons.filter_alt_off
                      : Icons.filter_list),
                  onPressed: showCategoryFilterDialog,
                  tooltip:
                      isFilterActive ? 'Clear Filter' : 'Filter by Category',
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('events').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> documents = snapshot.data!.docs;
                if (_searchController.text.isNotEmpty) {
                  documents = documents
                      .where((doc) => doc['name']
                          .toString()
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()))
                      .toList();
                }
                if (selectedCategory != null) {
                  documents = documents
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)
                              .containsKey('category') &&
                          doc['category'] == selectedCategory)
                      .toList();
                }

                if (documents.isEmpty) {
                  return const Center(
                      child:
                          Text("No event found. Please try another category."));
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
                        context, event, formattedDate, eventId, isRegistered);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEventTile(BuildContext context, Map<String, dynamic> event,
      String formattedDate, String eventId, bool isRegistered) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
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
            /* Text(
              event['description'] ?? 'No description provided',
              style: TextStyle(
                fontSize: 14.0,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),*/
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isRegistered)
                  ElevatedButton(
                    onPressed: () =>
                        unregisterFromEvent(event['name'], eventId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Remove'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => registerForEvent(event['name'], eventId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Register'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EventDetailScreen(eventId: eventId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('More'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
