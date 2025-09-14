import 'dart:convert';
// To parse this JSON data, do
//
//     final getNotification = getNotificationFromJson(jsonString);


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
    dynamic postId;
    String type;
    String message;
    int isRead;
    DateTime createdAt;
    Sender sender;
    dynamic post;

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
        type: json["type"],
        message: json["message"],
        isRead: json["is_read"],
        createdAt: DateTime.parse(json["created_at"]),
        sender: Sender.fromJson(json["sender"]),
        post: json["post"],
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
        "post": post,
    };
}

class Sender {
    int uid;
    String name;
    String profileImage;

    Sender({
        required this.uid,
        required this.name,
        required this.profileImage,
    });

    factory Sender.fromJson(Map<String, dynamic> json) => Sender(
        uid: json["uid"],
        name: json["name"],
        profileImage: json["profile_image"],
    );

    Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "profile_image": profileImage,
    };
}
