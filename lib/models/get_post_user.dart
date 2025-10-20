import 'dart:convert';

// To parse this JSON data, do
//
//     final getPostUser = getPostUserFromJson(jsonString);

List<GetPostUser> getPostUserFromJson(String str) =>
    List<GetPostUser>.from(json.decode(str).map((x) => GetPostUser.fromJson(x)));

String getPostUserToJson(List<GetPostUser> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetPostUser {
  Post post;
  List<Image> images;
  List<Category> categories;

  GetPostUser({
    required this.post,
    required this.images,
    required this.categories,
  });

  factory GetPostUser.fromJson(Map<String, dynamic> json) => GetPostUser(
        post: Post.fromJson(json["post"] ?? {}),
        images: (json["images"] != null)
            ? List<Image>.from(json["images"].map((x) => Image.fromJson(x)))
            : [],
        categories: (json["categories"] != null)
            ? List<Category>.from(json["categories"].map((x) => Category.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "post": post.toJson(),
        "images": List<dynamic>.from(images.map((x) => x.toJson())),
        "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
      };
}

class Category {
  int cid;
  String cname;
  String cimage;
  String ctype;

  Category({
    required this.cid,
    required this.cname,
    required this.cimage,
    required this.ctype,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        cid: json["cid"] ?? 0,
        cname: json["cname"] ?? '',
        cimage: json["cimage"] ?? '',
        ctype: json["ctype"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,
        "ctype": ctype,
      };
}

class Image {
  int imageId;
  String image;
  int imageFkPostid;

  Image({
    required this.imageId,
    required this.image,
    required this.imageFkPostid,
  });

  factory Image.fromJson(Map<String, dynamic> json) => Image(
        imageId: json["image_id"] ?? 0,
        image: json["image"] ?? '',
        imageFkPostid: json["image_fk_postid"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "image_id": imageId,
        "image": image,
        "image_fk_postid": imageFkPostid,
      };
}
class Post {
  int postId;
  String postTopic;
  String postDescription;
  int amountOfLike;
  int amountOfSave;
  int amountOfComment;
  DateTime postDate;
  int postFkUid;
  String postStatus; // ✅ เพิ่มฟิลด์นี้

  Post({
    required this.postId,
    required this.postTopic,
    required this.postDescription,
    required this.amountOfLike,
    required this.amountOfSave,
    required this.amountOfComment,
    required this.postDate,
    required this.postFkUid,
    required this.postStatus, // ✅ ต้องใส่ constructor
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"] ?? 0,
        postTopic: json["post_topic"] ?? '',
        postDescription: json["post_description"] ?? '',
        amountOfLike: json["amount_of_like"] ?? 0,
        amountOfSave: json["amount_of_save"] ?? 0,
        amountOfComment: json["amount_of_comment"] ?? 0,
        postDate: json["post_date"] != null
            ? DateTime.parse(json["post_date"])
            : DateTime.now(),
        postFkUid: json["post_fk_uid"] ?? 0,
        postStatus: json["post_status"] ?? 'public', // ✅ อ่านจาก JSON
      );

  Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "amount_of_like": amountOfLike,
        "amount_of_save": amountOfSave,
        "amount_of_comment": amountOfComment,
        "post_date": postDate.toIso8601String(),
        "post_fk_uid": postFkUid,
        "post_status": postStatus, // ✅ ส่งกลับ JSON
      };
}

