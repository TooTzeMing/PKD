import 'package:eventmanagement_app/services/userinfo_service.dart';
import 'package:flutter/material.dart';

class AdditionalData extends StatefulWidget {
  final String userId;
  final String username;

  const AdditionalData({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<AdditionalData> createState() => _AdditionalDataState();
}

class _AdditionalDataState extends State<AdditionalData> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _addressController = TextEditingController();
  final _noTelController = TextEditingController();
  final _genderController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _householdCategoryController = TextEditingController();
  final _ageLevelController = TextEditingController();
  final _serviceTypeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _addressController.dispose();
    _noTelController.dispose();
    _genderController.dispose();
    _postcodeController.dispose();
    _stateController.dispose();
    _householdCategoryController.dispose();
    _ageLevelController.dispose();
    _serviceTypeController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownSelector({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label.';
          }
          return null;
        },
      ),
    );
  }

  String? _selectedGender;
  String? _selectedState;
  String? _selectedHouseholdCategory;
  String? _selectedAgeLevel;
  String? _selectedServiceType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Personal Information Form",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "Name",
                hint: "Please enter your full name.",
                icon: Icons.person,
                controller: _nameController,
              ),
              _buildTextField(
                label: "IC",
                hint: "Please enter your identification number.",
                icon: Icons.badge,
                controller: _icController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: "Address",
                hint: "Please enter your full address.",
                icon: Icons.home,
                controller: _addressController,
              ),
              _buildTextField(
                label: "Phone Number",
                hint: "Please enter a valid phone number.",
                icon: Icons.phone,
                controller: _noTelController,
                keyboardType: TextInputType.phone,
              ),
              _buildDropdownSelector(
                label: "Gender",
                hint: "Please select your gender.",
                icon: Icons.transgender,
                items: ["Male", "Female"],
                selectedValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              _buildTextField(
                label: "Postcode",
                hint: "Please enter your postcode.",
                icon: Icons.location_on,
                controller: _postcodeController,
                keyboardType: TextInputType.number,
              ),
              _buildDropdownSelector(
                label: "State",
                hint: "Please select your state.",
                icon: Icons.map,
                items: [
                  "Johor",
                  "Kelantan",
                  "Negeri Sembilan",
                  "Kedah",
                  "Perlis",
                  "Terengganu",
                  "Pahang",
                  "Selangor",
                  "Kuala Lumpur",
                  "Penang",
                  "Sabah",
                  "Sarawak",
                  "Perak",
                  "Melaka"
                ],
                selectedValue: _selectedState,
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                  });
                },
              ),
              _buildDropdownSelector(
                label: "Household Category",
                hint: "Please select your household category.",
                icon: Icons.group,
                items: ["Single", "Married", "Family"],
                selectedValue: _selectedHouseholdCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedHouseholdCategory = value;
                  });
                },
              ),
              _buildDropdownSelector(
                label: "Age Level",
                hint: "Please select your age level.",
                icon: Icons.calendar_today,
                items: ["Child", "Teen", "Adult", "Senior"],
                selectedValue: _selectedAgeLevel,
                onChanged: (value) {
                  setState(() {
                    _selectedAgeLevel = value;
                  });
                },
              ),
              _buildDropdownSelector(
                label: "Service Type",
                hint: "Please select your service type.",
                icon: Icons.build,
                items: ["Plumbing", "Electrician", "Carpentry", "Cleaning"],
                selectedValue: _selectedServiceType,
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      try {
                        // Save data to Firebase
                        await DatabaseService().createUserData(
                          userId: widget.userId,
                          username: widget.username,
                          name: _nameController.text,
                          ic: _icController.text,
                          address: _addressController.text,
                          noTel: _noTelController.text,
                          gender: _selectedGender ?? "",
                          postcode: _postcodeController.text,
                          state: _selectedState ?? "",
                          householdCategory: _selectedHouseholdCategory ?? "",
                          ageLevel: _selectedAgeLevel ?? "",
                          serviceType: _selectedServiceType ?? "",
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Data saved successfully!")),
                        );

                        // Log in user (optional, depending on your auth flow)
                        // Assuming user credentials are already verified or logged in via FirebaseAuth
                        // Redirect to the home page
                        Navigator.pushReplacementNamed(context, '/home');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
