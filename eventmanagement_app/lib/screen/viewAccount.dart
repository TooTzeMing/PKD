import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAccount extends StatefulWidget {
  const ViewAccount({super.key});

  @override
  State<ViewAccount> createState() => _ViewAccountState();
}

class _ViewAccountState extends State<ViewAccount> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all user documents
  Future<List<Map<String, dynamic>>> _fetchAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View All Users'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          } else if (snapshot.hasData) {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(user['name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: ${user['username'] ?? 'N/A'}'),
                        Text('Phone: ${user['no_tel'] ?? 'N/A'}'),
                        Text('Address: ${user['address'] ?? 'N/A'}'),
                        Text('State: ${user['state'] ?? 'N/A'}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        _showUserDetails(context, user);
                      },
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Unexpected error.'));
          }
        },
      ),
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${user['name'] ?? 'User Details'}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Username: ${user['username'] ?? 'N/A'}'),
                Text('Name: ${user['name'] ?? 'N/A'}'),
                Text('IC: ${user['ic'] ?? 'N/A'}'),
                Text('Phone: ${user['no_tel'] ?? 'N/A'}'),
                Text('Address: ${user['address'] ?? 'N/A'}'),
                Text('Postcode: ${user['postcode'] ?? 'N/A'}'),
                Text('State: ${user['state'] ?? 'N/A'}'),
                Text('Gender: ${user['gender'] ?? 'N/A'}'),
                Text(
                    'Household Category: ${user['household_category'] ?? 'N/A'}'),
                Text('Age Level: ${user['age_level'] ?? 'N/A'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
