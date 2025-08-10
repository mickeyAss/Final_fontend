import 'dart:convert';

GetNotification getNotificationFromJson(String str) => GetNotification.fromJson(json.decode(str));

String getNotificationToJson(GetNotification data) => json.encode(data.toJson());

class GetNotification {
  List<Notification> notifications;

  GetNotification({
    required this.notifications,
  });

  factory GetNotification.fromJson(Map<String, dynamic> json) => GetNotification(
    notifications: List<Notification>.from(json["notifications"].map((x) => Notification.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "notifications": List<dynamic>.from(notifications.map((x) => x.toJson())),
  };
}

class Notification {
  int notificationId;
  int senderUid;
  int receiverUid;
  int? postId;
  String type; // เปลี่ยนจาก Type enum เป็น String
  String message; // เปลี่ยนจาก Message enum เป็น String
  int isRead;
  DateTime createdAt;
  Sender sender;
  Post? post;

  Notification({
    required this.notificationId,
    required this.senderUid,
    required this.receiverUid,
    required this.postId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.sender,
    required this.post,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    notificationId: json["notification_id"],
    senderUid: json["sender_uid"],
    receiverUid: json["receiver_uid"],
    postId: json["post_id"],
    type: json["type"] ?? "", // รับค่า string โดยตรง
    message: json["message"] ?? "", // รับค่า string โดยตรง
    isRead: json["is_read"],
    createdAt: DateTime.parse(json["created_at"]),
    sender: Sender.fromJson(json["sender"]),
    post: json["post"] == null ? null : Post.fromJson(json["post"]),
  );

  Map<String, dynamic> toJson() => {
    "notification_id": notificationId,
    "sender_uid": senderUid,
    "receiver_uid": receiverUid,
    "post_id": postId,
    "type": type,
    "message": message,
    "is_read": isRead,
    "created_at": createdAt.toIso8601String(),
    "sender": sender.toJson(),
    "post": post?.toJson(),
  };
}

class Post {
  int postId;
  String postTopic; // เปลี่ยนจาก PostTopic enum เป็น String
  String postDescription; // เปลี่ยนจาก PostDescription enum เป็น String
  DateTime postDate;
  int postFkUid;
  int amountOfSave;
  int amountOfComment;
  List<Image> images;

  Post({
    required this.postId,
    required this.postTopic,
    required this.postDescription,
    required this.postDate,
    required this.postFkUid,
    required this.amountOfSave,
    required this.amountOfComment,
    required this.images,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    postId: json["post_id"],
    postTopic: json["post_topic"] ?? "", // รับค่า string โดยตรง
    postDescription: json["post_description"] ?? "", // รับค่า string โดยตรง
    postDate: DateTime.parse(json["post_date"]),
    postFkUid: json["post_fk_uid"],
    amountOfSave: json["amount_of_save"],
    amountOfComment: json["amount_of_comment"],
    images: List<Image>.from(json["images"].map((x) => Image.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "post_id": postId,
    "post_topic": postTopic,
    "post_description": postDescription,
    "post_date": postDate.toIso8601String(),
    "post_fk_uid": postFkUid,
    "amount_of_save": amountOfSave,
    "amount_of_comment": amountOfComment,
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
    image: json["image"] ?? "", // เพิ่ม null safety
    imageFkPostid: json["image_fk_postid"],
  );

  Map<String, dynamic> toJson() => {
    "image_id": imageId,
    "image": image,
    "image_fk_postid": imageFkPostid,
  };
}

class Sender {
  int uid;
  String name; // เปลี่ยนจาก Name enum เป็น String
  String profileImage;

  Sender({
    required this.uid,
    required this.name,
    required this.profileImage,
  });

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
    uid: json["uid"],
    name: json["name"] ?? "", // รับค่า string โดยตรง
    profileImage: json["profile_image"] ?? "", // เพิ่ม null safety
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "name": name,
    "profile_image": profileImage,
  };
}