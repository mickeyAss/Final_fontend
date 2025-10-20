import 'dart:convert';

// To parse this JSON data, do
//
//     final postDetail = postDetailFromJson(jsonString);

PostDetail postDetailFromJson(String str) => PostDetail.fromJson(json.decode(str));

String postDetailToJson(PostDetail data) => json.encode(data.toJson());

class PostDetail {
    Post post;
    User user;
    List<Image> images;
    List<Category> categories;
    List<Hashtag> hashtags;

    PostDetail({
        required this.post,
        required this.user,
        required this.images,
        required this.categories,
        required this.hashtags,
    });

    factory PostDetail.fromJson(Map<String, dynamic> json) => PostDetail(
        post: Post.fromJson(json["post"]),
        user: User.fromJson(json["user"]),
        images: List<Image>.from(json["images"]?.map((x) => Image.fromJson(x)) ?? []),
        categories: List<Category>.from(json["categories"]?.map((x) => Category.fromJson(x)) ?? []),
        hashtags: List<Hashtag>.from(json["hashtags"]?.map((x) => Hashtag.fromJson(x)) ?? []),
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
    String? cimage;  // อาจเป็น null
    String ctype;

    Category({
        required this.cid,
        required this.cname,
        this.cimage,  // ไม่ required
        required this.ctype,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
        cid: json["cid"] ?? 0,
        cname: json["cname"] ?? '',
        cimage: json["cimage"],  // อนุญาตให้เป็น null
        ctype: json["ctype"] ?? '',
    );

    Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,  // จะเป็น null ถ้าไม่มีค่า
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
        tagId: json["tag_id"] ?? 0,
        tagName: json["tag_name"] ?? '',
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
    String? postDescription;  // อาจเป็น null
    DateTime postDate;
    int postFkUid;
    int amountOfLike;
    int amountOfSave;
    int amountOfComment;
    String postStatus; // ✅ เพิ่มฟิลด์ status

    Post({
        required this.postId,
        required this.postTopic,
        this.postDescription,  // ไม่ required
        required this.postDate,
        required this.postFkUid,
        required this.amountOfLike,
        required this.amountOfSave,
        required this.amountOfComment,
        required this.postStatus, // ✅ เพิ่ม constructor
    });

    factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"] ?? 0,
        postTopic: json["post_topic"] ?? '',
        postDescription: json["post_description"],  // อนุญาตให้เป็น null
        postDate: json["post_date"] != null 
            ? DateTime.parse(json["post_date"]) 
            : DateTime.now(),
        postFkUid: json["post_fk_uid"] ?? 0,
        amountOfLike: json["amount_of_like"] ?? 0,
        amountOfSave: json["amount_of_save"] ?? 0,
        amountOfComment: json["amount_of_comment"] ?? 0,
        postStatus: json["post_status"] ?? 'public', // ✅ อ่านจาก JSON
    );

    Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,  // จะเป็น null ถ้าไม่มีค่า
        "post_date": postDate.toIso8601String(),
        "post_fk_uid": postFkUid,
        "amount_of_like": amountOfLike,
        "amount_of_save": amountOfSave,
        "amount_of_comment": amountOfComment,
        "post_status": postStatus, // ✅ ส่งกลับ JSON
    };
}


class User {
    int uid;
    String name;
    String email;
    String? personalDescription;  // อาจเป็น null
    String? profileImage;        // อาจเป็น null

    User({
        required this.uid,
        required this.name,
        required this.email,
        this.personalDescription,  // ไม่ required
        this.profileImage,         // ไม่ required
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"] ?? 0,
        name: json["name"] ?? '',
        email: json["email"] ?? '',
        personalDescription: json["personal_description"],  // อนุญาตให้เป็น null
        profileImage: json["profile_image"],               // อนุญาตให้เป็น null
    );

    Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "personal_description": personalDescription,  // จะเป็น null ถ้าไม่มีค่า
        "profile_image": profileImage,               // จะเป็น null ถ้าไม่มีค่า
    };
}