import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? department;
  final String? profileImageUrl;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.department,
    this.profileImageUrl,
    this.updatedAt,
  });

  // Create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      department: data['department'],
      profileImageUrl: data['profileImageUrl'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert UserModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only add non-null values to prevent overwriting with nulls
    if (phone != null) data['phone'] = phone;
    if (department != null) data['department'] = department;
    if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;

    return data;
  }

  // Create a copy of UserModel with modified fields
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? department,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      updatedAt: DateTime.now(),
    );
  }
}
