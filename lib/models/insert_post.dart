import 'dart:convert';
// To parse this JSON data, do
//
//     final insertpost = insertpostFromJson(jsonString);


Insertpost insertpostFromJson(String str) => Insertpost.fromJson(json.decode(str));

String insertpostToJson(Insertpost data) => json.encode(data.toJson());

class Insertpost {
    String postTopic;
    String postDescription;
    int postFkUid;
    List<String> images;
    List<int> categoryIdFk;
    List<int> hashtags;
    String postStatus;

    Insertpost({
        required this.postTopic,
        required this.postDescription,
        required this.postFkUid,
        required this.images,
        required this.categoryIdFk,
        required this.hashtags,
        required this.postStatus,
    });

    factory Insertpost.fromJson(Map<String, dynamic> json) => Insertpost(
        postTopic: json["post_topic"],
        postDescription: json["post_description"],
        postFkUid: json["post_fk_uid"],
        images: List<String>.from(json["images"].map((x) => x)),
        categoryIdFk: List<int>.from(json["category_id_fk"].map((x) => x)),
        hashtags: List<int>.from(json["hashtags"].map((x) => x)),
        postStatus: json["post_status"],
    );

    Map<String, dynamic> toJson() => {
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_fk_uid": postFkUid,
        "images": List<dynamic>.from(images.map((x) => x)),
        "category_id_fk": List<dynamic>.from(categoryIdFk.map((x) => x)),
        "hashtags": List<dynamic>.from(hashtags.map((x) => x)),
        "post_status": postStatus,
    };
}
