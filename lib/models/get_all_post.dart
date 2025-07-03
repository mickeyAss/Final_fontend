class GetAllPost {
  final Post post;
  final User user;
  final List<ImageData> images;
  final List<Category> categories;

  GetAllPost({
    required this.post,
    required this.user,
    required this.images,
    required this.categories,
  });

  factory GetAllPost.fromJson(Map<String, dynamic> json) {
    return GetAllPost(
      post: Post.fromJson(json['post']),
      user: User.fromJson(json['user']),
      images: (json['images'] as List)
          .map((i) => ImageData.fromJson(i))
          .toList(),
      categories: (json['categories'] as List)
          .map((c) => Category.fromJson(c))
          .toList(),
    );
  }
}

class Post {
  final int postId;
  final String postTopic;
  final String? postDescription;

  Post({
    required this.postId,
    required this.postTopic,
    this.postDescription,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['post_id'],
      postTopic: json['post_topic'],
      postDescription: json['post_description'],
    );
  }
}

class User {
  final String name;
  final String? profileImage;

  User({
    required this.name,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      profileImage: json['profile_image'],
    );
  }
}

class ImageData {
  final String image;

  ImageData({required this.image});

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(image: json['image']);
  }
}

class Category {
  final String cname;

  Category({required this.cname});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(cname: json['cname']);
  }
}
