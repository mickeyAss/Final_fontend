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
    String personalDescription;
    List<int> categoryIds;

    RegisterUserRequest({
        required this.name,
        required this.email,
        required this.password,
        required this.personalDescription,
        required this.categoryIds,
    });

    factory RegisterUserRequest.fromJson(Map<String, dynamic> json) => RegisterUserRequest(
        name: json["name"],
        email: json["email"],
        password: json["password"],
        personalDescription: json["personal_description"],
        categoryIds: List<int>.from(json["category_ids"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "email": email,
        "password": password,
        "personal_description": personalDescription,
        "category_ids": List<dynamic>.from(categoryIds.map((x) => x)),
    };
}
