import 'dart:convert';
// To parse this JSON data, do
//
//     final registerUserRequest = registerUserRequestFromJson(jsonString);


RegisterUserRequest registerUserRequestFromJson(String str) => RegisterUserRequest.fromJson(json.decode(str));

String registerUserRequestToJson(RegisterUserRequest data) => json.encode(data.toJson());

class RegisterUserRequest {
    String name;
    String email;
    String password;
    String height;
    String weight;
    String shirtSize;
    String chest;
    String waistCircumference;
    String hip;

    RegisterUserRequest({
        required this.name,
        required this.email,
        required this.password,
        required this.height,
        required this.weight,
        required this.shirtSize,
        required this.chest,
        required this.waistCircumference,
        required this.hip,
    });

    factory RegisterUserRequest.fromJson(Map<String, dynamic> json) => RegisterUserRequest(
        name: json["name"],
        email: json["email"],
        password: json["password"],
        height: json["height"],
        weight: json["weight"],
        shirtSize: json["shirt_size"],
        chest: json["chest"],
        waistCircumference: json["waist_circumference"],
        hip: json["hip"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "email": email,
        "password": password,
        "height": height,
        "weight": weight,
        "shirt_size": shirtSize,
        "chest": chest,
        "waist_circumference": waistCircumference,
        "hip": hip,
    };
}
