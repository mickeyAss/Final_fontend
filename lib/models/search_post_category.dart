import 'dart:convert';
// To parse this JSON data, do
//
//     final searchPostCategory = searchPostCategoryFromJson(jsonString);


SearchPostCategory searchPostCategoryFromJson(String str) => SearchPostCategory.fromJson(json.decode(str));

String searchPostCategoryToJson(SearchPostCategory data) => json.encode(data.toJson());

class SearchPostCategory {
    String searchName;
    List<MatchedCategory> matchedCategories;
    int totalPosts;
    List<Post> posts;

    SearchPostCategory({
        required this.searchName,
        required this.matchedCategories,
        required this.totalPosts,
        required this.posts,
    });

    factory SearchPostCategory.fromJson(Map<String, dynamic> json) => SearchPostCategory(
        searchName: json["search_name"],
        matchedCategories: List<MatchedCategory>.from(json["matched_categories"].map((x) => MatchedCategory.fromJson(x))),
        totalPosts: json["total_posts"],
        posts: List<Post>.from(json["posts"].map((x) => Post.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "search_name": searchName,
        "matched_categories": List<dynamic>.from(matchedCategories.map((x) => x.toJson())),
        "total_posts": totalPosts,
        "posts": List<dynamic>.from(posts.map((x) => x.toJson())),
    };
}

class MatchedCategory {
    int cid;
    String cname;
    String cimage;
    String ctype;
    String cdescription;

    MatchedCategory({
        required this.cid,
        required this.cname,
        required this.cimage,
        required this.ctype,
        required this.cdescription,
    });

    factory MatchedCategory.fromJson(Map<String, dynamic> json) => MatchedCategory(
        cid: json["cid"],
        cname: json["cname"],
        cimage: json["cimage"],
        ctype: json["ctype"],
        cdescription: json["cdescription"],
    );

    Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,
        "ctype": ctype,
        "cdescription": cdescription,
    };
}

class Post {
    int postId;
    String? postTopic;
    String postDescription;
    DateTime postDate;
    Category category;
    User user;
    List<String> images;

    Post({
        required this.postId,
        required this.postTopic,
        required this.postDescription,
        required this.postDate,
        required this.category,
        required this.user,
        required this.images,
    });

    factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"],
        postTopic: json["post_topic"],
        postDescription: json["post_description"],
        postDate: DateTime.parse(json["post_date"]),
        category: Category.fromJson(json["category"]),
        user: User.fromJson(json["user"]),
        images: List<String>.from(json["images"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_date": postDate.toIso8601String(),
        "category": category.toJson(),
        "user": user.toJson(),
        "images": List<dynamic>.from(images.map((x) => x)),
    };
}

class Category {
    int id;
    String name;
    String image;
    String type;
    String description;

    Category({
        required this.id,
        required this.name,
        required this.image,
        required this.type,
        required this.description,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        image: json["image"],
        type: json["type"],
        description: json["description"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "image": image,
        "type": type,
        "description": description,
    };
}

class User {
    int uid;
    String name;
    String email;
    String profileImage;

    User({
        required this.uid,
        required this.name,
        required this.email,
        required this.profileImage,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"],
        name: json["name"],
        email: json["email"],
        profileImage: json["profile_image"],
    );

    Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "profile_image": profileImage,
    };
}
