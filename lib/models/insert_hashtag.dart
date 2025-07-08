import 'dart:convert';
// To parse this JSON data, do
//
//     final insertHashtag = insertHashtagFromJson(jsonString);


InsertHashtag insertHashtagFromJson(String str) => InsertHashtag.fromJson(json.decode(str));

String insertHashtagToJson(InsertHashtag data) => json.encode(data.toJson());

class InsertHashtag {
    String tagName;

    InsertHashtag({
        required this.tagName,
    });

    factory InsertHashtag.fromJson(Map<String, dynamic> json) => InsertHashtag(
        tagName: json["tag_name"],
    );

    Map<String, dynamic> toJson() => {
        "tag_name": tagName,
    };
}
