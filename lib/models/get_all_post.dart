import 'dart:convert';
// To parse this JSON data, do
//
//     final getAllPost = getAllPostFromJson(jsonString);


List<GetAllPost> getAllPostFromJson(String str) => List<GetAllPost>.from(json.decode(str).map((x) => GetAllPost.fromJson(x)));

String getAllPostToJson(List<GetAllPost> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetAllPost {
    Post post;
    User user;
    List<Image> images;
    List<Category> categories;
    List<Hashtag> hashtags;

    GetAllPost({
        required this.post,
        required this.user,
        required this.images,
        required this.categories,
        required this.hashtags,
    });

    factory GetAllPost.fromJson(Map<String, dynamic> json) => GetAllPost(
        post: Post.fromJson(json["post"]),
        user: User.fromJson(json["user"]),
        images: List<Image>.from(json["images"].map((x) => Image.fromJson(x))),
        categories: List<Category>.from(json["categories"].map((x) => Category.fromJson(x))),
        hashtags: List<Hashtag>.from(json["hashtags"].map((x) => Hashtag.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "post": post.toJson(),
        "user": user.toJson(),
        "images": List<dynamic>.from(images.map((x) => x.toJson())),
        "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
        "hashtags": List<dynamic>.from(hashtags.map((x) => x.toJson())),
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
        cid: json["cid"],
        cname: json["cname"],
        cimage: json["cimage"],
        ctype: json["ctype"],
    );

    Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,
        "ctype": ctype,
    };
}

class Hashtag {
    int tagId;
    String tagName;

    Hashtag({
        required this.tagId,
        required this.tagName,
    });

    factory Hashtag.fromJson(Map<String, dynamic> json) => Hashtag(
        tagId: json["tag_id"],
        tagName: json["tag_name"],
    );

    Map<String, dynamic> toJson() => {
        "tag_id": tagId,
        "tag_name": tagName,
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
        imageId: json["image_id"],
        image: json["image"],
        imageFkPostid: json["image_fk_postid"],
    );

    Map<String, dynamic> toJson() => {
        "image_id": imageId,
        "image": image,
        "image_fk_postid": imageFkPostid,
    };
}

class Post {
  int postId;
  String? postTopic;
  String? postDescription;
  DateTime postDate;
  int postFkUid;
  int amountOfLike;
  int amountOfComment;     // ✅ เพิ่ม
  int amountOfSave;        // ✅ เพิ่ม

  Post({
    required this.postId,
    required this.postTopic,
    required this.postDescription,
    required this.postDate,
    required this.postFkUid,
    required this.amountOfLike,
    required this.amountOfComment,    // ✅ เพิ่ม
    required this.amountOfSave,       // ✅ เพิ่ม
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"],
        postTopic: json["post_topic"],
        postDescription: json["post_description"],
        postDate: DateTime.parse(json["post_date"]),
        postFkUid: json["post_fk_uid"],
        amountOfLike: json["amount_of_like"] ?? 0,
        amountOfComment: json["amount_of_comment"] ?? 0,  // ✅ รองรับ null
        amountOfSave: json["amount_of_save"] ?? 0,        // ✅ รองรับ null
      );

  Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_date": postDate.toIso8601String(),
        "post_fk_uid": postFkUid,
        "amount_of_like": amountOfLike,
        "amount_of_comment": amountOfComment,   // ✅ ส่งกลับ
        "amount_of_save": amountOfSave,         // ✅ ส่งกลับ
      };
}


class User {
    int uid;
    String name;
    String email;
    String height;
    String weight;
    String shirtSize;
    String chest;
    String waistCircumference;
    String hip;
    String personalDescription;
    String profileImage;

    User({
        required this.uid,
        required this.name,
        required this.email,
        required this.height,
        required this.weight,
        required this.shirtSize,
        required this.chest,
        required this.waistCircumference,
        required this.hip,
        required this.personalDescription,
        required this.profileImage,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"],
        name: json["name"],
        email: json["email"],
        height: json["height"],
        weight: json["weight"],
        shirtSize: json["shirt_size"],
        chest: json["chest"],
        waistCircumference: json["waist_circumference"],
        hip: json["hip"],
        personalDescription: json["personal_description"],
        profileImage: json["profile_image"],
    );

    Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "height": height,
        "weight": weight,
        "shirt_size": shirtSize,
        "chest": chest,
        "waist_circumference": waistCircumference,
        "hip": hip,
        "personal_description": personalDescription,
        "profile_image": profileImage,
    };
}
