import 'dart:convert';
// To parse this JSON data, do
//
//     final insertpost = insertpostFromJson(jsonString);


Insertpost insertpostFromJson(String str) => Insertpost.fromJson(json.decode(str));

String insertpostToJson(Insertpost data) => json.encode(data.toJson());

class Insertpost {
    String postTopic;
    String postDescription;
    String postFkUid;
    List<String> images;

    Insertpost({
        required this.postTopic,
        required this.postDescription,
        required this.postFkUid,
        required this.images,
    });

    factory Insertpost.fromJson(Map<String, dynamic> json) => Insertpost(
        postTopic: json["post_topic"],
        postDescription: json["post_description"],
        postFkUid: json["post_fk_uid"],
        images: List<String>.from(json["images"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_fk_uid": postFkUid,
        "images": List<dynamic>.from(images.map((x) => x)),
    };
}
