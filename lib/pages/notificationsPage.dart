import 'dart:convert';
import 'dart:developer';
import 'package:fontend_pro/pages/other_user_profile.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/user_detail_post.dart';
import 'package:fontend_pro/models/get_notification.dart' as NotificationModel;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationModel.GetNotification? notificationData;
  bool isLoading = true;
  int loggedInUid = 0;
  Map<int, bool> followingStatus = {};
  final GetStorage gs = GetStorage();

  @override
  void initState() {
    super.initState();
    loggedInUid = gs.read('user') ?? 0;
    log('Logged in UID: $loggedInUid');
    fetchNotifications();
  }

  void _navigateToPostDetail(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailPostPage(postId: postId),
      ),
    );
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final apiUrl =
        Uri.parse('$url/image_post/notification/read/$notificationId');

    try {
      final response = await http.put(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"userId": loggedInUid}),
      );

      if (response.statusCode == 200) {
        log('Marked notification $notificationId as read');
        setState(() {
          final index = notificationData?.notifications
              .indexWhere((n) => n.notificationId == notificationId);
          if (index != null && index != -1) {
            notificationData?.notifications[index].isRead = 1;
          }
        });
      } else {
        log('Failed to mark notification as read: ${response.body}');
      }
    } catch (e) {
      log('Error marking notification as read: $e');
    }
  }

  Future<bool> checkIsFollowing(int targetUserId) async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.get(
        Uri.parse(
            "$url/user/is-following?follower_id=$loggedInUid&following_id=$targetUserId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFollowing'] ?? false;
      } else {
        log('Failed to check following status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('Error checking following status: $e');
      return false;
    }
  }

  Future<void> loadFollowingStatusForNotifications() async {
    if (notificationData?.notifications == null) return;

    Set<int> senderIds = {};
    for (var notification in notificationData!.notifications) {
      if (notification.type.toUpperCase() == 'USER') {
        senderIds.add(notification.sender.uid);
      }
    }

    if (senderIds.isEmpty) return;

    List<Future<MapEntry<int, bool>>> futures = senderIds.map((senderId) async {
      bool isFollowing = await checkIsFollowing(senderId);
      return MapEntry(senderId, isFollowing);
    }).toList();

    try {
      List<MapEntry<int, bool>> results = await Future.wait(futures);
      Map<int, bool> newFollowingStatus = {
        for (var result in results) result.key: result.value
      };
      setState(() {
        followingStatus.addAll(newFollowingStatus);
      });
      log('Loaded following status for ${senderIds.length} users concurrently');
    } catch (e) {
      log('Error loading following status concurrently: $e');
    }
  }

  Future<void> followUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse('$url/user/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "follower_id": loggedInUid,
          "following_id": targetUserId,
        }),
      );

      if (response.statusCode == 200) {
        log('Followed user $targetUserId successfully');
        setState(() => followingStatus[targetUserId] = true);
        _showSnackBar('ติดตามสำเร็จ', Colors.green);
      } else {
        _showSnackBar('ไม่สามารถติดตามได้ในขณะนี้', Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการติดตาม', Colors.red);
    }
  }

  Future<void> unfollowUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final request = http.Request('DELETE', Uri.parse('$url/user/unfollow'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'follower_id': loggedInUid,
        'following_id': targetUserId,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        log('Unfollowed user $targetUserId successfully');
        setState(() => followingStatus[targetUserId] = false);
        _showSnackBar('เลิกติดตามสำเร็จ', Colors.green);
      } else {
        _showSnackBar('ไม่สามารถเลิกติดตามได้ในขณะนี้', Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเลิกติดตาม', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    var config = await Configuration.getConfig();
    var apiEndpoint = config['apiEndpoint'];
    final url = Uri.parse('$apiEndpoint/user/notifications/$loggedInUid');

    try {
      final response = await http.get(url);
      log('Notification API response: ${response.body}');
      if (response.statusCode == 200) {
        final NotificationModel.GetNotification data =
            NotificationModel.getNotificationFromJson(response.body);

        log('Fetched ${data.notifications.length} notifications');

        setState(() {
          notificationData = data;
          isLoading = false;
        });

        if (data.notifications.isNotEmpty)
          loadFollowingStatusForNotifications();
      } else {
        setState(() => isLoading = false);
        log('API error status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      log('Exception when fetching notifications: $e');
    }
  }

  String timeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inSeconds < 60) return 'เมื่อสักครู่';
    if (difference.inMinutes < 60) return '${difference.inMinutes} นาทีที่แล้ว';
    if (difference.inHours < 24) return '${difference.inHours} ชั่วโมงที่แล้ว';
    if (difference.inDays < 7) return '${difference.inDays} วันที่แล้ว';
    return DateFormat('dd MMM').format(createdAt);
  }

  Widget getNotificationIcon(NotificationModel.NotificationItem notification) {
    final senderUid = notification.sender.uid;
    final isFollowing = followingStatus[senderUid] ?? false;

    // ถ้าติดตามแล้ว ให้ไม่แสดงไอคอน
    if (isFollowing) return const SizedBox.shrink();

    switch (notification.type.toUpperCase()) {
      case 'USER':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_add, color: Colors.white, size: 12),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String getNotificationMessage(
      NotificationModel.NotificationItem notification) {
    final senderName = notification.sender.name;
    final type = notification.type;

    switch (type.toLowerCase()) {
      // แนะนำให้ lowercase เพื่อให้ match ได้ทั้ง LIKE/like
      case 'like':
        return '$senderName ถูกใจโพสต์ของคุณ';
      case 'comment':
        return '$senderName แสดงความคิดเห็นในโพสต์ของคุณ: "${notification.message}"';
      case 'follow':
        return '$senderName เริ่มติดตามคุณ';
      case 'report':
        final reportMessage = notification.message.isNotEmpty
            ? notification.message
            : 'มีการรายงานโพสต์';
        return 'โพสต์ของคุณถูกรายงาน: "$reportMessage"';
      case 'report_user':
        final reportMessage = notification.message.isNotEmpty
            ? notification.message
            : 'มีผู้รายงานคุณ';
        return 'ผู้ใช้ $senderName รายงานคุณ: "$reportMessage"';
      default:
        return notification.message;
    }
  }

  Widget buildNotificationContent(
      NotificationModel.NotificationItem notification) {
    final senderName = notification.sender.name;
    final message = getNotificationMessage(notification);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          senderName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2), // เว้นระยะเล็กน้อย
        Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Color getNotificationBackgroundColor(
      NotificationModel.NotificationItem notification, bool isRead) {
    return isRead ? Colors.white : Colors.green.shade50;
  }

  Widget buildPostThumbnail(NotificationModel.Post? post) {
    if (post == null || post.images.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.image, color: Colors.grey, size: 20),
      );
    }

    final imageUrl = post.images.first.image ?? '';
    return GestureDetector(
      onTap: () => _navigateToPostDetail(post.postId ?? 0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl), fit: BoxFit.cover)
              : null,
          color: imageUrl.isEmpty ? Colors.grey.shade300 : null,
        ),
        child: imageUrl.isEmpty
            ? const Icon(Icons.image, color: Colors.grey, size: 20)
            : null,
      ),
    );
  }

  Widget buildFollowButton(NotificationModel.NotificationItem notification) {
    final senderUid = notification.sender.uid;
    final isFollowing = followingStatus[senderUid] ?? false;

    return GestureDetector(
      onTap: () async {
        if (isFollowing) {
          await unfollowUser(senderUid);
        } else {
          await followUser(senderUid);
        }
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:
              isFollowing ? Colors.white : Colors.black, // สีขาวถ้าติดตามแล้ว
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isFollowing ? Colors.black : Colors.transparent),
        ),
        child: Center(
          child: Text(
            isFollowing ? 'ติดตามแล้ว' : 'ติดตาม',
            style: TextStyle(
                color: isFollowing
                    ? Colors.black
                    : Colors.white, // ตัวอักษรตรงข้ามพื้นหลัง
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('การแจ้งเตือน',
            style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600)),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchNotifications,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2))
              : (notificationData?.notifications.isEmpty ?? true)
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('ไม่มีการแจ้งเตือน',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500)),
                          SizedBox(height: 8),
                          Text('การแจ้งเตือนจะปรากฏที่นี่',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notificationData?.notifications.length ?? 0,
                      itemBuilder: (context, index) {
                        final notification =
                            notificationData!.notifications[index];
                        final isRead = notification.isRead == 1;

                        return GestureDetector(
                          onTap: () async {
                            if (!isRead) {
                              setState(() {
                                notification.isRead = 1;
                              });
                              await markNotificationAsRead(
                                  notification.notificationId);
                            }

                            if (notification.post != null &&
                                notification.post?.postId != null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailPostPage(
                                    postId: notification.post!.postId!,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: getNotificationBackgroundColor(
                                  notification, isRead),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // รูปโปรไฟล์ผู้ส่ง
                                GestureDetector(
                                  onTap: () {
                                    if (notification.sender.uid !=
                                        loggedInUid) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OtherUserProfilePage(
                                            userId: notification.sender.uid,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundImage: notification.sender
                                                    .profileImage?.isNotEmpty ??
                                                false
                                            ? NetworkImage(notification
                                                .sender.profileImage!)
                                            : const AssetImage(
                                                    'assets/images/default_avatar.png')
                                                as ImageProvider,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child:
                                            getNotificationIcon(notification),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      buildNotificationContent(notification),
                                      // แสดงข้อความใต้ชื่อผู้ส่ง
                                      if (notification.message != null &&
                                          notification.message!.isNotEmpty)
                                        
                                      const SizedBox(height: 6),
                                      Text(
                                        timeAgo(notification.createdAt),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (notification.type.toUpperCase() == 'USER')
                                  buildFollowButton(notification),
                                if (notification.post != null)
                                  const SizedBox(width: 12),
                                if (notification.post != null)
                                  buildPostThumbnail(notification.post),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
