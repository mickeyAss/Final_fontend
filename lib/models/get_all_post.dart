// To parse this JSON data, do
//
//     final getAllPost = getAllPostFromJson(jsonString);

import 'dart:convert';

GetAllPost getAllPostFromJson(String str) => GetAllPost.fromJson(json.decode(str));

String getAllPostToJson(GetAllPost data) => json.encode(data.toJson());

class GetAllPost {
    Post post;
    List<Image> images;

    GetAllPost({
        required this.post,
        required this.images,
    });

    factory GetAllPost.fromJson(Map<String, dynamic> json) => GetAllPost(
        post: Post.fromJson(json["post"]),
        images: List<Image>.from(json["images"].map((x) => Image.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "post": post.toJson(),
        "images": List<dynamic>.from(images.map((x) => x.toJson())),
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
    String postTopic;
    String postDescription;
    dynamic amountOfLike;
    dynamic amountOfSave;
    dynamic amountOfComment;
    String postDate;
    int postFkCid;
    int postFkUid;

    Post({
        required this.postId,
        required this.postTopic,
        required this.postDescription,
        required this.amountOfLike,
        required this.amountOfSave,
        required this.amountOfComment,
        required this.postDate,
        required this.postFkCid,
        required this.postFkUid,
    });

    factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"],
        postTopic: json["post_topic"],
        postDescription: json["post_description"],
        amountOfLike: json["amount_of_like"],
        amountOfSave: json["amount_of_save"],
        amountOfComment: json["amount_of_comment"],
        postDate: json["post_date"],
        postFkCid: json["post_fk_cid"],
        postFkUid: json["post_fk_uid"],
    );

    Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "amount_of_like": amountOfLike,
        "amount_of_save": amountOfSave,
        "amount_of_comment": amountOfComment,
        "post_date": postDate,
        "post_fk_cid": postFkCid,
        "post_fk_uid": postFkUid,
    };
}
