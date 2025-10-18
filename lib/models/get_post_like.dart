import 'dart:convert';
// To parse this JSON data, do
//
//     final getPostLike = getPostLikeFromJson(jsonString);


List<GetPostLike> getPostLikeFromJson(String str) => List<GetPostLike>.from(json.decode(str).map((x) => GetPostLike.fromJson(x)));

String getPostLikeToJson(List<GetPostLike> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetPostLike {
    Post post;
    User user;
    List<Image> images;
    List<Category> categories;
    List<Hashtag> hashtags;

    GetPostLike({
        required this.post,
        required this.user,
        required this.images,
        required this.categories,
        required this.hashtags,
    });

    factory GetPostLike.fromJson(Map<String, dynamic> json) => GetPostLike(
        post: Post.fromJson(json["post"]),
        user: User.fromJson(json["user"]),
        images: List<Image>.from((json["images"] ?? []).map((x) => Image.fromJson(x))),  // ✅ รองรับ null
        categories: List<Category>.from((json["categories"] ?? []).map((x) => Category.fromJson(x))),  // ✅ รองรับ null
        hashtags: List<Hashtag>.from((json["hashtags"] ?? []).map((x) => Hashtag.fromJson(x))),  // ✅ รองรับ null
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
    String? cimage;  // ✅ เปลี่ยนเป็น nullable
    Ctype ctype;

    Category({
        required this.cid,
        required this.cname,
        this.cimage,  // ✅ ไม่บังคับ
        required this.ctype,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
        cid: json["cid"],
        cname: json["cname"],
        cimage: json["cimage"],  // ✅ อาจเป็น null
        ctype: ctypeValues.map[json["ctype"]] ?? Ctype.F,  // ✅ มี default value
    );

    Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,
        "ctype": ctypeValues.reverse[ctype],
    };
}

enum Ctype {
    F,
    M
}

final ctypeValues = EnumValues({
    "F": Ctype.F,
    "M": Ctype.M
});

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
    String? postTopic;  // ✅ เป็น nullable อยู่แล้ว
    String postDescription;
    DateTime postDate;
    int postFkUid;
    int amountOfLike;

    Post({
        required this.postId,
        this.postTopic,  // ✅ ไม่บังคับ
        required this.postDescription,
        required this.postDate,
        required this.postFkUid,
        required this.amountOfLike,
    });

    factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"],
        postTopic: json["post_topic"],  // ✅ อาจเป็น null
        postDescription: json["post_description"] ?? "",  // ✅ ป้องกัน null
        postDate: DateTime.parse(json["post_date"]),
        postFkUid: json["post_fk_uid"],
        amountOfLike: json["amount_of_like"] ?? 0,  // ✅ ป้องกัน null
    );

    Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_date": postDate.toIso8601String(),
        "post_fk_uid": postFkUid,
        "amount_of_like": amountOfLike,
    };
}

class User {
    int uid;
    String name;
    String email;
    String? personalDescription;  // ✅ เป็น nullable อยู่แล้ว
    String? profileImage;  // ✅ เปลี่ยนเป็น nullable

    User({
        required this.uid,
        required this.name,
        required this.email,
        this.personalDescription,  // ✅ ไม่บังคับ
        this.profileImage,  // ✅ ไม่บังคับ
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"],
        name: json["name"],
        email: json["email"],
        personalDescription: json["personal_description"],
        profileImage: json["profile_image"],  // ✅ อาจเป็น null
    );

    Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "personal_description": personalDescription,
        "profile_image": profileImage,
    };
}

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
        reverseMap = map.map((k, v) => MapEntry(v, k));
        return reverseMap;
    }
}