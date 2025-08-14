import 'dart:convert';

// To parse this JSON data, do
//
//     final getUserUid = getUserUidFromJson(jsonString);

GetUserUid getUserUidFromJson(String str) => GetUserUid.fromJson(json.decode(str));

String getUserUidToJson(GetUserUid data) => json.encode(data.toJson());

class GetUserUid {
  int uid;
  String name;
  String email;
  String password;
  String? personalDescription;
  String? profileImage;
  double? height;
  double? weight;
  String? shirtSize;
  double? chest;
  double? waistCircumference;
  double? hip;

  GetUserUid({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    this.personalDescription,
    this.profileImage,
    this.height,
    this.weight,
    this.shirtSize,
    this.chest,
    this.waistCircumference,
    this.hip,
  });

  factory GetUserUid.fromJson(Map<String, dynamic> json) => GetUserUid(
        uid: json["uid"],
        name: json["name"],
        email: json["email"],
        password: json["password"],
        personalDescription: json["personal_description"],
        profileImage: json["profile_image"],
        height: (json["height"] != null) ? (json["height"] as num).toDouble() : null,
        weight: (json["weight"] != null) ? (json["weight"] as num).toDouble() : null,
        shirtSize: json["shirt_size"],
        chest: (json["chest"] != null) ? (json["chest"] as num).toDouble() : null,
        waistCircumference: (json["waist_circumference"] != null)
            ? (json["waist_circumference"] as num).toDouble()
            : null,
        hip: (json["hip"] != null) ? (json["hip"] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "password": password,
        "personal_description": personalDescription,
        "profile_image": profileImage,
        "height": height,
        "weight": weight,
        "shirt_size": shirtSize,
        "chest": chest,
        "waist_circumference": waistCircumference,
        "hip": hip,
      };
}
