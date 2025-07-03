import 'dart:convert';
// To parse this JSON data, do
//
//     final likePost = likePostFromJson(jsonString);


LikePost likePostFromJson(String str) => LikePost.fromJson(json.decode(str));

String likePostToJson(LikePost data) => json.encode(data.toJson());

class LikePost {
    int postId;

    LikePost({
        required this.postId,
    });

    factory LikePost.fromJson(Map<String, dynamic> json) => LikePost(
        postId: json["post_id"],
    );

    Map<String, dynamic> toJson() => {
        "post_id": postId,
    };
}
