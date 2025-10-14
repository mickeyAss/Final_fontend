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
    List<dynamic> categories;
    List<dynamic> hashtags;

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
        images: List<Image>.from(json["images"].map((x) => Image.fromJson(x))),
        categories: List<dynamic>.from(json["categories"].map((x) => x)),
        hashtags: List<dynamic>.from(json["hashtags"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "post": post.toJson(),
        "user": user.toJson(),
        "images": List<dynamic>.from(images.map((x) => x.toJson())),
        "categories": List<dynamic>.from(categories.map((x) => x)),
        "hashtags": List<dynamic>.from(hashtags.map((x) => x)),
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
    dynamic postTopic;
    dynamic postDescription;
    DateTime postDate;
    int postFkUid;
    int amountOfLike;
    int amountOfSave;
    int amountOfComment;

    Post({
        required this.postId,
        required this.postTopic,
        required this.postDescription,
        required this.postDate,
        required this.postFkUid,
        required this.amountOfLike,
        required this.amountOfSave,
        required this.amountOfComment,
    });

    factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"],
        postTopic: json["post_topic"],
        postDescription: json["post_description"],
        postDate: DateTime.parse(json["post_date"]),
        postFkUid: json["post_fk_uid"],
        amountOfLike: json["amount_of_like"],
        amountOfSave: json["amount_of_save"],
        amountOfComment: json["amount_of_comment"],
    );

    Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_date": postDate.toIso8601String(),
        "post_fk_uid": postFkUid,
        "amount_of_like": amountOfLike,
        "amount_of_save": amountOfSave,
        "amount_of_comment": amountOfComment,
    };
}

class User {
    int uid;
    String name;
    String email;
    dynamic personalDescription;
    String profileImage;

    User({
        required this.uid,
        required this.name,
        required this.email,
        required this.personalDescription,
        required this.profileImage,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"],
        name: json["name"],
        email: json["email"],
        personalDescription: json["personal_description"],
        profileImage: json["profile_image"],
    );

    Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "personal_description": personalDescription,
        "profile_image": profileImage,
    };
}
