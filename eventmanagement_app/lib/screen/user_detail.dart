import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagement_app/screen/annoucement_management.dart';
import 'package:eventmanagement_app/screen/viewAccount.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:eventmanagement_app/services/global.dart';

class UserDetail extends StatefulWidget {
  const UserDetail({super.key});

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? _activeField;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _states = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu'
  ];
  final List<String> _householdCategories = ['Single', 'Couple', 'Family'];
  final List<String> _ageLevels = ['Child', 'Teen', 'Adult', 'Senior'];

  final Map<String, bool> _editingFields = {};

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
        });
      } else {
        print('User document not found');
      }
    }
  }

  Future<void> _saveField(
      String field, TextEditingController controller) async {
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        field: controller.text,
      });
      Fluttertoast.showToast(
        msg: 'Field updated successfully',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update field: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _activeField = null;
      });
    }
  }

  Widget _buildStylizedField(String label, String fieldKey,
      TextEditingController controller, List<String>? dropdownItems) {
    bool isEditing = _activeField == fieldKey;
    String selectedValue = controller.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isEditing ? Colors.lightBlue[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              border:
                  isEditing ? Border.all(color: Colors.blue, width: 2) : null,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isEditing ? Colors.blue : Colors.grey,
                    ),
                  ),
                  dropdownItems == null || !isEditing
                      ? TextField(
                          controller: controller,
                          readOnly: !isEditing,
                          style: const TextStyle(fontSize: 18),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        )
                      : DropdownButton<String>(
                          value: selectedValue.isEmpty
                              ? dropdownItems[0]
                              : selectedValue,
                          isExpanded: true,
                          items: dropdownItems.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item,
                                  style: const TextStyle(fontSize: 18)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedValue = newValue!;
                              controller.text = newValue;
                            });
                          },
                          underline: const SizedBox(),
                        ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                if (isEditing) {
                  _saveField(fieldKey, controller);
                  setState(() {
                    _activeField = null;
                  });
                } else {
                  setState(() {
                    _activeField = fieldKey;
                  });
                }
              },
              child: Icon(
                isEditing ? Icons.check : Icons.edit,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.yellow,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Column(
                children: [
                  _buildStylizedField(
                      'Username', 'username', _usernameController, null),
                  _buildStylizedField('Name', 'name', _nameController, null),
                  _buildStylizedField('IC', 'ic', _icController, null),
                  _buildStylizedField(
                      'Address', 'address', _addressController, null),
                  _buildStylizedField(
                      'Post Code', 'postcode', _postcodeController, null),
                  _buildStylizedField(
                      'Gender', 'gender', _genderController, _genders),
                  _buildStylizedField(
                      'State', 'state', _stateController, _states),
                  _buildStylizedField(
                      'Household Category',
                      'household_category',
                      _householdCategoryController,
                      _householdCategories),
                  _buildStylizedField('Age Level', 'age_level',
                      _ageLevelController, _ageLevels),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildIconWithLabel(IconData icon, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: Colors.black,
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
    ],
  );
}
