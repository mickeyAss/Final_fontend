import 'dart:convert';
// To parse this JSON data, do
//
//     final getComment = getCommentFromJson(jsonString);


GetComment getCommentFromJson(String str) => GetComment.fromJson(json.decode(str));

String getCommentToJson(GetComment data) => json.encode(data.toJson());

class GetComment {
    List<Comment> comments;

    GetComment({
        required this.comments,
    });

    factory GetComment.fromJson(Map<String, dynamic> json) => GetComment(
        comments: List<Comment>.from(json["comments"].map((x) => Comment.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "comments": List<dynamic>.from(comments.map((x) => x.toJson())),
    };
}

class Comment {
    int commentId;
    String commentText;
    DateTime createdAt;
    int uid;
    String name;
    String profileImage;

    Comment({
        required this.commentId,
        required this.commentText,
        required this.createdAt,
        required this.uid,
        required this.name,
        required this.profileImage,
    });

    factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        commentId: json["comment_id"],
        commentText: json["comment_text"],
        createdAt: DateTime.parse(json["created_at"]),
        uid: json["uid"],
        name: json["name"],
        profileImage: json["profile_image"],
    );

    Map<String, dynamic> toJson() => {
        "comment_id": commentId,
        "comment_text": commentText,
        "created_at": createdAt.toIso8601String(),
        "uid": uid,
        "name": name,
        "profile_image": profileImage,
    };
}
