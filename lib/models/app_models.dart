class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // Customer, Driver, Admin
  final String? phoneNumber;
  final String? address;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.address,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'Customer',
      phoneNumber: map['phoneNumber'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}