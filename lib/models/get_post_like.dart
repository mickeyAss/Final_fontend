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
    Ctype ctype;

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
        ctype: ctypeValues.map[json["ctype"]]!,
    );

    Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,
        "ctype": ctypeValues.reverse[ctype],
    };
}

enum Ctype {
    M
}

final ctypeValues = EnumValues({
    "M": Ctype.M
});

class Hashtag {
    int tagId;
    TagName tagName;

    Hashtag({
        required this.tagId,
        required this.tagName,
    });

    factory Hashtag.fromJson(Map<String, dynamic> json) => Hashtag(
        tagId: json["tag_id"],
        tagName: tagNameValues.map[json["tag_name"]]!,
    );

    Map<String, dynamic> toJson() => {
        "tag_id": tagId,
        "tag_name": tagNameValues.reverse[tagName],
    };
}

enum TagName {
    EMPTY
}

final tagNameValues = EnumValues({
    "มินิมอล": TagName.EMPTY
});

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
    Name name;
    Email email;
    PersonalDescription personalDescription;
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
        name: nameValues.map[json["name"]]!,
        email: emailValues.map[json["email"]]!,
        personalDescription: personalDescriptionValues.map[json["personal_description"]]!,
        profileImage: json["profile_image"],
    );

    Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": nameValues.reverse[name],
        "email": emailValues.reverse[email],
        "personal_description": personalDescriptionValues.reverse[personalDescription],
        "profile_image": profileImage,
    };
}

enum Email {
    MICSARA_GMAIL_COM,
    TEAM_GMAIL_COM
}

final emailValues = EnumValues({
    "micsara@gmail.com": Email.MICSARA_GMAIL_COM,
    "team@gmail.com": Email.TEAM_GMAIL_COM
});

enum Name {
    SARAWUT_SUTTHIPANYO,
    TEAM
}

final nameValues = EnumValues({
    "Sarawut Sutthipanyo": Name.SARAWUT_SUTTHIPANYO,
    "team": Name.TEAM
});

enum PersonalDescription {
    EMPTY,
    MICKEY
}

final personalDescriptionValues = EnumValues({
    "": PersonalDescription.EMPTY,
    "MICKEY": PersonalDescription.MICKEY
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
