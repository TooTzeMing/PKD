import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _icController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noTelController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _householdCategoryController =
      TextEditingController();
  final TextEditingController _ageLevelController = TextEditingController();
  final TextEditingController _serviceTypeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool _isEditing = false; // Controls edit mode

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _usernameController.text = userDoc['username'] ?? '';
          _nameController.text = userDoc['name'] ?? '';
          _icController.text = userDoc['ic'] ?? '';
          _addressController.text = userDoc['address'] ?? '';
          _noTelController.text = userDoc['no_tel'] ?? '';
          _genderController.text = userDoc['gender'] ?? '';
          _postcodeController.text = userDoc['postcode'] ?? '';
          _stateController.text = userDoc['state'] ?? '';
          _householdCategoryController.text =
              userDoc['household_category'] ?? '';
          _ageLevelController.text = userDoc['age_level'] ?? '';
          _serviceTypeController.text = userDoc['service_type'] ?? '';
        });
      } else {
        print('User document not found');
      }
    } else {
      print('No user signed in');
    }
  }

  Future<void> _updateUserData() async {
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'username': _usernameController.text,
        'name': _nameController.text,
        'ic': _icController.text,
        'address': _addressController.text,
        'no_tel': _noTelController.text,
        'gender': _genderController.text,
        'postcode': _postcodeController.text,
        'state': _stateController.text,
        'household_category': _householdCategoryController.text,
        'age_level': _ageLevelController.text,
        'service_type': _serviceTypeController.text,
      });
      Fluttertoast.showToast(
        msg: 'Profile updated successfully',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      setState(() {
        _isEditing = false; // Switch back to non-editable mode
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update profile: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(
                  _usernameController, 'Username', Icons.person, !_isEditing),
              _buildTextField(
                  _nameController, 'Name', Icons.text_fields, !_isEditing),
              _buildTextField(
                  _icController, 'IC', Icons.credit_card, !_isEditing),
              _buildTextField(
                  _addressController, 'Address', Icons.home, !_isEditing),
              _buildTextField(
                  _noTelController, 'Phone Number', Icons.phone, !_isEditing),
              _buildTextField(
                  _genderController, 'Gender', Icons.wc, !_isEditing),
              _buildTextField(_postcodeController, 'Postcode',
                  Icons.location_on, !_isEditing),
              _buildTextField(
                  _stateController, 'State', Icons.map, !_isEditing),
              _buildTextField(_householdCategoryController,
                  'Household Category', Icons.category, !_isEditing),
              _buildTextField(
                  _ageLevelController, 'Age Level', Icons.cake, !_isEditing),
              _buildTextField(_serviceTypeController, 'Service Type',
                  Icons.miscellaneous_services, !_isEditing),
              const SizedBox(height: 20),
              _isEditing
                  ? ElevatedButton(
                      onPressed: _updateUserData,
                      child: const Text('Save Changes'),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: const Text('Edit Profile'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
