import 'dart:convert';
// To parse this JSON data, do
//
//     final likePost = likePostFromJson(jsonString);


LikePost likePostFromJson(String str) => LikePost.fromJson(json.decode(str));

String likePostToJson(LikePost data) => json.encode(data.toJson());

class LikePost {
    int userId;
    int postId;

    LikePost({
        required this.userId,
        required this.postId,
    });

    factory LikePost.fromJson(Map<String, dynamic> json) => LikePost(
        userId: json["user_id"],
        postId: json["post_id"],
    );

    Map<String, dynamic> toJson() => {
        "user_id": userId,
        "post_id": postId,
    };
}
