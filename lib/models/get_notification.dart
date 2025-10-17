import 'dart:convert';

// To parse this JSON data
GetNotification getNotificationFromJson(String str) =>
    GetNotification.fromJson(json.decode(str));

String getNotificationToJson(GetNotification data) =>
    json.encode(data.toJson());

class GetNotification {
  List<NotificationItem> notifications;

  GetNotification({required this.notifications});

  factory GetNotification.fromJson(Map<String, dynamic> json) =>
      GetNotification(
        notifications: json["notifications"] == null
            ? []
            : List<NotificationItem>.from(
                json["notifications"].map((x) => NotificationItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "notifications": List<dynamic>.from(notifications.map((x) => x.toJson())),
      };
}

class NotificationItem {
  int notificationId;
  int senderUid;
  int receiverUid;
  int? postId;
  String type;
  String message;
  int isRead;
  DateTime createdAt;
  Sender sender;
  Post? post;

  NotificationItem({
    required this.notificationId,
    required this.senderUid,
    required this.receiverUid,
    this.postId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.sender,
    this.post,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        notificationId: json["notification_id"],
        senderUid: json["sender_uid"],
        receiverUid: json["receiver_uid"],
        postId: json["post_id"],
        type: json["type"],
        message: json["message"],
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
  String? postTopic;
  String? postDescription;
  DateTime postDate;
  int postFkUid;
  List<ImageItem> images;

  Post({
    required this.postId,
    this.postTopic,
    this.postDescription,
    required this.postDate,
    required this.postFkUid,
    required this.images,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        postId: json["post_id"],
        postTopic: json["post_topic"],
        postDescription: json["post_description"],
        postDate: DateTime.parse(json["post_date"]),
        postFkUid: json["post_fk_uid"],
        images: json["images"] == null
            ? []
            : List<ImageItem>.from(
                json["images"].map((x) => ImageItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "post_id": postId,
        "post_topic": postTopic,
        "post_description": postDescription,
        "post_date": postDate.toIso8601String(),
        "post_fk_uid": postFkUid,
        "images": List<dynamic>.from(images.map((x) => x.toJson())),
      };
}

class ImageItem {
  int imageId;
  String image;
  int imageFkPostid;

  ImageItem({
    required this.imageId,
    required this.image,
    required this.imageFkPostid,
  });

  factory ImageItem.fromJson(Map<String, dynamic> json) => ImageItem(
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

class Sender {
  int uid;
  String name;
  String email;
  String? personalDescription;
  String profileImage;
  int? height;
  int? weight;
  String? shirtSize;
  dynamic chest;
  dynamic waistCircumference;
  dynamic hip;
  String type;
  int isBanned;
  dynamic bannedAt;

  Sender({
    required this.uid,
    required this.name,
    required this.email,
    this.personalDescription,
    required this.profileImage,
    this.height,
    this.weight,
    this.shirtSize,
    this.chest,
    this.waistCircumference,
    this.hip,
    required this.type,
    required this.isBanned,
    this.bannedAt,
  });

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
        uid: json["uid"],
        name: json["name"],
        email: json["email"],
        personalDescription: json["personal_description"],
        profileImage: json["profile_image"],
        height: json["height"],
        weight: json["weight"],
        shirtSize: json["shirt_size"],
        chest: json["chest"],
        waistCircumference: json["waist_circumference"],
        hip: json["hip"],
        type: json["type"],
        isBanned: json["is_banned"],
        bannedAt: json["banned_at"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "email": email,
        "personal_description": personalDescription,
        "profile_image": profileImage,
        "height": height,
        "weight": weight,
        "shirt_size": shirtSize,
        "chest": chest,
        "waist_circumference": waistCircumference,
        "hip": hip,
        "type": type,
        "is_banned": isBanned,
        "banned_at": bannedAt,
      };
}
