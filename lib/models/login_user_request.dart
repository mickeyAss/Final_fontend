import 'dart:convert';
// To parse this JSON data, do
//
//     final loginUserRequest = loginUserRequestFromJson(jsonString);


LoginUserRequest loginUserRequestFromJson(String str) => LoginUserRequest.fromJson(json.decode(str));

String loginUserRequestToJson(LoginUserRequest data) => json.encode(data.toJson());

class LoginUserRequest {
    String email;
    String password;

    LoginUserRequest({
        required this.email,
        required this.password,
    });

    factory LoginUserRequest.fromJson(Map<String, dynamic> json) => LoginUserRequest(
        email: json["email"],
        password: json["password"],
    );

    Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
    };
}
