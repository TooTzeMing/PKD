import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to create a new user document
  Future<void> createUserData({
    required String userId,
    required String username,
    required String name,
    required String ic,
    required String address,
    required String noTel,
    required String gender,
    required String postcode,
    required String state,
    required String householdCategory,
    required String ageLevel,
    required String serviceType,
  }) async {
    try {
      await _firestore.collection("users").doc(userId).set({
        'username': username,
        "name": name,
        "ic": ic,
        "address": address,
        "no_tel": noTel,
        "gender": gender,
        "postcode": postcode,
        "state": state,
        "household_category": householdCategory,
        "age_level": ageLevel,
        "service_type": serviceType,
      });
      print("User data added successfully for userId: $userId");
    } catch (e) {
      print("Error: $e");
    }
  }
}
