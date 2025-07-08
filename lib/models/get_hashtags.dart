import 'dart:convert';
// To parse this JSON data, do
//
//     final getHashtags = getHashtagsFromJson(jsonString);


GetHashtags getHashtagsFromJson(String str) => GetHashtags.fromJson(json.decode(str));

String getHashtagsToJson(GetHashtags data) => json.encode(data.toJson());

class GetHashtags {
    bool isNew;
    List<Datum> data;

    GetHashtags({
        required this.isNew,
        required this.data,
    });

    factory GetHashtags.fromJson(Map<String, dynamic> json) => GetHashtags(
        isNew: json["isNew"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "isNew": isNew,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    int tagId;
    String tagName;

    Datum({
        required this.tagId,
        required this.tagName,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        tagId: json["tag_id"],
        tagName: json["tag_name"],
    );

    Map<String, dynamic> toJson() => {
        "tag_id": tagId,
        "tag_name": tagName,
    };
}
