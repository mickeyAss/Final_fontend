import 'dart:convert';

// To parse this JSON data:
// final getPostHashtags = getPostHashtagsFromJson(jsonString);

List<GetPostHashtags> getPostHashtagsFromJson(String str) =>
    List<GetPostHashtags>.from(
        json.decode(str).map((x) => GetPostHashtags.fromJson(x)));

String getPostHashtagsToJson(List<GetPostHashtags> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetPostHashtags {
  int tagId;
  String tagName;
  final int usageCount; // เพิ่มตรงนี้
  List<Post> posts;

  GetPostHashtags({
    required this.tagId,
    required this.tagName,
    required this.usageCount,
    required this.posts,
  });

  factory GetPostHashtags.fromJson(Map<String, dynamic> json) =>
      GetPostHashtags(
        tagId: json["tag_id"],
        tagName: json["tag_name"],
        usageCount: json['usage_count'] ?? 0,
        posts: (json["posts"] as List<dynamic>?)
                ?.map((x) => Post.fromJson(x))
                .toList() ??
            [], // <-- ป้องกัน null
      );

  Map<String, dynamic> toJson() => {
        "tag_id": tagId,
        "tag_name": tagName,
        "posts": List<dynamic>.from(posts.map((x) => x.toJson())),
      };
}

class Post {
  int postId;
  String postTopic;
  String postDescription;
  int postFkUid;
  DateTime postDate;
  User user;
  List<String> images;

  Post({
    required this.postId,
    required this.postTopic,
    required this.postDescription,
    required this.postFkUid,
    required this.postDate,
    required this.user,
    required this.images,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"],
        postTopic: json["post_topic"] ?? '',
        postDescription: json["post_description"] ?? '',
        postFkUid: json["post_fk_uid"],
        postDate: DateTime.parse(json["post_date"]),
        user: User.fromJson(json["user"]),
        images: (json["images"] as List<dynamic>?)
                ?.map((x) => x.toString())
                .toList() ??
            [], // <-- ป้องกัน null
      );

  Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_fk_uid": postFkUid,
        "post_date": postDate.toIso8601String(),
        "user": user.toJson(),
        "images": List<dynamic>.from(images.map((x) => x)),
      };
}

class User {
  int uid;
  String name;
  String email;

  User({
    required this.uid,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"],
        name: json["name"] ?? '',
        email: json["email"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
      };
}
