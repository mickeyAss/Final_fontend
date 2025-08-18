import 'dart:convert';
// To parse this JSON data, do
//
//     final getAllUser = getAllUserFromJson(jsonString);

List<GetAllUser> getAllUserFromJson(String str) => List<GetAllUser>.from(json.decode(str).map((x) => GetAllUser.fromJson(x)));

String getAllUserToJson(List<GetAllUser> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetAllUser {
  int uid;
  String name;
  String email;
  String password;
  String? personalDescription;
  String? profileImage;

  GetAllUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    this.personalDescription,
    this.profileImage,
  });

  factory GetAllUser.fromJson(Map<String, dynamic> json) => GetAllUser(
        uid: json["uid"] ?? 0,
        name: json["name"] ?? '',
        email: json["email"] ?? '',
        password: json["password"] ?? '',
        personalDescription: json["personal_description"] ?? '',
        profileImage: json["profile_image"] ?? '', 
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "password": password,
        "personal_description": personalDescription,
        "profile_image": profileImage,
      };
}
