import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAccount extends StatefulWidget {
  const ViewAccount({super.key});

  @override
  State<ViewAccount> createState() => _ViewAccountState();
}

class _ViewAccountState extends State<ViewAccount> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _filterBy = "name"; // Default filter by first name

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

  List<Map<String, dynamic>> _filterUsers(
      List<Map<String, dynamic>> users, String query, String filterBy) {
    if (query.isEmpty) {
      return users;
    }
    return users.where((user) {
      final filterValue = user[filterBy]?.toLowerCase() ?? '';
      return filterValue.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View All Users'),
        backgroundColor: Colors.yellow, // Or your desired color
        elevation: 0.0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(17.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    setState(() {
                      _filterBy = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'name',
                      child: Text('Filter by First Name'),
                    ),
                    const PopupMenuItem(
                      value: 'username',
                      child: Text('Filter by Last Name'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                } else if (snapshot.hasData) {
                  final filteredUsers =
                      _filterUsers(snapshot.data!, _searchQuery, _filterBy);
                  if (filteredUsers.isEmpty) {
                    return const Center(
                        child: Text('No users match your search.'));
                  }
                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
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
          ),
        ],
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
