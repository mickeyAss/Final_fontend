import 'dart:convert';

// ฟังก์ชันสำหรับ parse JSON
GetComment getCommentFromJson(String str) => GetComment.fromJson(json.decode(str));
String getCommentToJson(GetComment data) => json.encode(data.toJson());

// ==================== GetComment ====================
class GetComment {
  List<Comment> comments;

  GetComment({required this.comments});

  factory GetComment.fromJson(Map<String, dynamic> json) => GetComment(
        comments: List<Comment>.from(json["comments"].map((x) => Comment.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "comments": List<dynamic>.from(comments.map((x) => x.toJson())),
      };
}

// ==================== Comment ====================
class Comment {
  int commentId;
  String commentText;
  DateTime createdAt;
  int uid;
  String name;
  String profileImage;

  // ✅ เพิ่มฟิลด์สำหรับ Like
  int amountOfLike; // จำนวนการถูกใจ
  bool isLikedByMe; // กดถูกใจแล้วหรือยัง

  Comment({
    required this.commentId,
    required this.commentText,
    required this.createdAt,
    required this.uid,
    required this.name,
    required this.profileImage,
    this.amountOfLike = 0,
    this.isLikedByMe = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        commentId: json["comment_id"],
        commentText: json["comment_text"],
        createdAt: DateTime.parse(json["created_at"]),
        uid: json["uid"],
        name: json["name"],
        profileImage: json["profile_image"],
        amountOfLike: json["amount_of_like"] ?? 0,
        isLikedByMe: json["is_liked_by_me"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "comment_id": commentId,
        "comment_text": commentText,
        "created_at": createdAt.toIso8601String(),
        "uid": uid,
        "name": name,
        "profile_image": profileImage,
        "amount_of_like": amountOfLike,
        "is_liked_by_me": isLikedByMe,
      };
}