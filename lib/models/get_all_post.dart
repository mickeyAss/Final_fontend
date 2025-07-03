import 'dart:convert';

List<GetAllPost> getAllPostFromJson(String str) =>
    List<GetAllPost>.from(json.decode(str).map((x) => GetAllPost.fromJson(x)));

String getAllPostToJson(List<GetAllPost> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetAllPost {
  Post post;
  User user;
  List<Image> images;
  List<Category> categories;

  GetAllPost({
    required this.post,
    required this.user,
    required this.images,
    required this.categories,
  });

  factory GetAllPost.fromJson(Map<String, dynamic> json) => GetAllPost(
        post: Post.fromJson(json["post"]),
        user: User.fromJson(json["user"]),
        images: json["images"] != null
            ? List<Image>.from(json["images"].map((x) => Image.fromJson(x)))
            : [],
        categories: json["categories"] != null
            ? List<Category>.from(
                json["categories"].map((x) => Category.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "post": post.toJson(),
        "user": user.toJson(),
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
        cid: json["cid"],
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
        imageId: json["image_id"],
        image: json["image"] ?? '',
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
  String? postDescription;
  int amountOfLike;
  int amountOfSave;
  int amountOfComment;
  DateTime postDate;
  int postFkUid;

  Post({
    required this.postId,
    required this.postTopic,
    this.postDescription,
    required this.amountOfLike,
    required this.amountOfSave,
    required this.amountOfComment,
    required this.postDate,
    required this.postFkUid,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"],
        postTopic: json["post_topic"] ?? '',
        postDescription: json["post_description"],
        amountOfLike: json["amount_of_like"] ?? 0,
        amountOfSave: json["amount_of_save"] ?? 0,
        amountOfComment: json["amount_of_comment"] ?? 0,
        postDate: json["post_date"] != null
            ? DateTime.parse(json["post_date"])
            : DateTime.now(),
        postFkUid: json["post_fk_uid"] ?? 0,
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
      };
}

class User {
  int uid;
  String name;
  String email;
  String? height;
  String? weight;
  String? shirtSize;
  String? chest;
  String? waistCircumference;
  String? hip;
  String? personalDescription;
  String? profileImage;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.height,
    this.weight,
    this.shirtSize,
    this.chest,
    this.waistCircumference,
    this.hip,
    this.personalDescription,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"],
        name: json["name"] ?? '',
        email: json["email"] ?? '',
        height: json["height"] as String?,
        weight: json["weight"] as String?,
        shirtSize: json["shirt_size"] as String?,
        chest: json["chest"] as String?,
        waistCircumference: json["waist_circumference"] as String?,
        hip: json["hip"] as String?,
        personalDescription: json["personal_description"] as String?,
        profileImage: json["profile_image"] as String?,
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
