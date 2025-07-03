import 'dart:convert';

GetUserUid getUserUidFromJson(String str) => GetUserUid.fromJson(json.decode(str));

String getUserUidToJson(GetUserUid data) => json.encode(data.toJson());

class GetUserUid {
  int uid;
  String name;
  String email;
  String password;
  String? height;
  String? weight;
  String? shirtSize;
  String? chest;
  String? waistCircumference;
  String? hip;
  String? personalDescription;
  String? profileImage;

  GetUserUid({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    this.height,
    this.weight,
    this.shirtSize,
    this.chest,
    this.waistCircumference,
    this.hip,
    this.personalDescription,
    this.profileImage,
  });

  factory GetUserUid.fromJson(Map<String, dynamic> json) => GetUserUid(
        uid: json["uid"],
        name: json["name"],
        email: json["email"],
        password: json["password"],
        height: json["height"],
        weight: json["weight"],
        shirtSize: json["shirt_size"],
        chest: json["chest"],
        waistCircumference: json["waist_circumference"],
        hip: json["hip"],
        personalDescription: json["personal_description"],
        profileImage: json["profile_image"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "password": password,
        "height": height,
        "weight": weight,
        "shirt_size": shirtSize,
        "chest": chest,
        "waist_circumference": waistCircumference,
        "hip": hip,
        "personal_description": personalDescription,
        "profile_image": profileImage,
      };
}
