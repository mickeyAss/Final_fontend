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
    String height;
    String weight;
    String shirtSize;
    String chest;
    String waistCircumference;
    String hip;
    String? personalDescription;
    String? profileImage;

    GetAllUser({
        required this.uid,
        required this.name,
        required this.email,
        required this.password,
        required this.height,
        required this.weight,
        required this.shirtSize,
        required this.chest,
        required this.waistCircumference,
        required this.hip,
        required this.personalDescription,
        required this.profileImage,
    });

    factory GetAllUser.fromJson(Map<String, dynamic> json) => GetAllUser(
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
