import 'dart:convert';

RegisterUserRequest registerUserRequestFromJson(String str) => RegisterUserRequest.fromJson(json.decode(str));

String registerUserRequestToJson(RegisterUserRequest data) => json.encode(data.toJson());

class RegisterUserRequest {
    int? uid; // เพิ่ม uid สำหรับกรณีแก้ไขหรือรับข้อมูลจาก DB
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
    List<int> categoryIds;

    RegisterUserRequest({
        this.uid,
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
        required this.categoryIds,
    });

    factory RegisterUserRequest.fromJson(Map<String, dynamic> json) => RegisterUserRequest(
        uid: json["uid"],
        name: json["name"],
        email: json["email"],
        password: json["password"],
        personalDescription: json["personal_description"],
        profileImage: json["profile_image"],
        height: (json["height"] != null) ? json["height"].toDouble() : null,
        weight: (json["weight"] != null) ? json["weight"].toDouble() : null,
        shirtSize: json["shirt_size"],
        chest: (json["chest"] != null) ? json["chest"].toDouble() : null,
        waistCircumference: (json["waist_circumference"] != null) ? json["waist_circumference"].toDouble() : null,
        hip: (json["hip"] != null) ? json["hip"].toDouble() : null,
        categoryIds: List<int>.from(json["category_ids"]?.map((x) => x) ?? []),
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
        "category_ids": List<dynamic>.from(categoryIds.map((x) => x)),
    };
}
