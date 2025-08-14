import 'dart:convert';

// Enum for post status
enum PostStatus {
  public,
  friends;

  // Convert from string to enum
  static PostStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'public':
        return PostStatus.public;
      case 'friends':
        return PostStatus.friends;
      default:
        return PostStatus.public; // Default value
    }
  }

  // Convert enum to string
  String toStringValue() {
    switch (this) {
      case PostStatus.public:
        return 'public';
      case PostStatus.friends:
        return 'friends';
    }
  }
}

List<GetAllPost> getAllPostFromJson(String str) =>
    List<GetAllPost>.from(json.decode(str).map((x) => GetAllPost.fromJson(x)));

String getAllPostToJson(List<GetAllPost> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

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
        post: Post.fromJson(json["post"] ?? {}),
        user: User.fromJson(json["user"] ?? {}),
        images: json["images"] == null
            ? []
            : List<Image>.from(json["images"].map((x) => Image.fromJson(x))),
        categories: json["categories"] == null
            ? []
            : List<Category>.from(
                json["categories"].map((x) => Category.fromJson(x))),
        hashtags: json["hashtags"] == null
            ? []
            : List<Hashtag>.from(
                json["hashtags"].map((x) => Hashtag.fromJson(x))),
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
  String? postTopic;
  String? postDescription;
  DateTime postDate;
  int postFkUid;
  int amountOfLike;
  int amountOfComment;
  int amountOfSave;
  PostStatus postStatus;

  Post({
    required this.postId,
    this.postTopic,
    this.postDescription,
    required this.postDate,
    required this.postFkUid,
    required this.amountOfLike,
    required this.amountOfComment,
    required this.amountOfSave,
    required this.postStatus,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"] ?? 0,
        postTopic: json["post_topic"],
        postDescription: json["post_description"],
        postDate: json["post_date"] == null
            ? DateTime.now()
            : DateTime.parse(json["post_date"]),
        postFkUid: json["post_fk_uid"] ?? 0,
        amountOfLike: json["amount_of_like"] ?? 0,
        amountOfComment: json["amount_of_comment"] ?? 0,
        amountOfSave: json["amount_of_save"] ?? 0,
        postStatus: PostStatus.fromString(json["post_status"] ?? "public"),
      );

  Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_date": postDate.toIso8601String(),
        "post_fk_uid": postFkUid,
        "amount_of_like": amountOfLike,
        "amount_of_comment": amountOfComment,
        "amount_of_save": amountOfSave,
        "post_status": postStatus.toStringValue(),
      };
}

class User {
  int uid;
  String name;
  String email;
  
  String personalDescription;
  String profileImage;

  User({
    required this.uid,
    required this.name,
    required this.email,
   
    required this.personalDescription,
    required this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"] ?? 0,
        name: json["name"] ?? '',
        email: json["email"] ?? '',
        
        personalDescription: json["personal_description"] ?? '',
        profileImage: json["profile_image"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        
        "personal_description": personalDescription,
        "profile_image": profileImage,
      };
}
   