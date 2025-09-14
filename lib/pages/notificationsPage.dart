import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/user_detail_post.dart';
import 'package:fontend_pro/models/get_notification.dart' as NotificationModel;

class Notificationspage extends StatefulWidget {
  const Notificationspage({super.key});

  @override
  State<Notificationspage> createState() => _NotificationspageState();
}

class _NotificationspageState extends State<Notificationspage> {
  NotificationModel.GetNotification? notificationData;
  bool isLoading = true;
  int loggedInUid = 0;
  Map<int, bool> followingStatus = {};

  GetStorage gs = GetStorage();

  @override
  void initState() {
    super.initState();
    loggedInUid = gs.read('user') ?? 0;
    fetchNotifications();
  }

  // นำทางไปหน้า Post Detail
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
        body: jsonEncode({
          "userId": loggedInUid,
        }),
      );

      if (response.statusCode == 200) {
        log('Marked notification $notificationId as read');
        setState(() {
          final index = notificationData!.notifications
              .indexWhere((n) => n.notificationId == notificationId);
          if (index != -1) {
            notificationData!.notifications[index].isRead = 1;
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
      if (notification.type == 'follow') {
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

      Map<int, bool> newFollowingStatus = {};
      for (var result in results) {
        newFollowingStatus[result.key] = result.value;
      }

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
        log('ติดตามผู้ใช้ $targetUserId สำเร็จ');

        setState(() {
          followingStatus[targetUserId] = true;
        });

        _showSuccessSnackBar('ติดตามสำเร็จ');
      } else {
        log('เกิดข้อผิดพลาดในการติดตาม: ${response.body}');
        _showErrorSnackBar('ไม่สามารถติดตามได้ในขณะนี้');
      }
    } catch (e) {
      log('Error following user: $e');
      _showErrorSnackBar('เกิดข้อผิดพลาดในการติดตาม');
    }
  }

  Future<void> unfollowUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final uri = Uri.parse('$url/user/unfollow');

      final request = http.Request('DELETE', uri);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'follower_id': loggedInUid,
        'following_id': targetUserId,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        log('เลิกติดตามผู้ใช้ $targetUserId สำเร็จ');
        setState(() {
          followingStatus[targetUserId] = false;
        });

        _showSuccessSnackBar('เลิกติดตามสำเร็จ');
      } else {
        log('เกิดข้อผิดพลาดในการเลิกติดตาม: ${response.body}');
        _showErrorSnackBar('ไม่สามารถเลิกติดตามได้ในขณะนี้');
      }
    } catch (e) {
      log('Error unfollowing user: $e');
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลิกติดตาม');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> fetchNotifications() async {
    var config = await Configuration.getConfig();
    var apiEndpoint = config['apiEndpoint'];
    final url = Uri.parse('$apiEndpoint/user/notifications/${gs.read('user')}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final NotificationModel.GetNotification data =
            NotificationModel.getNotificationFromJson(response.body);

        setState(() {
          notificationData = data;
          isLoading = false;
        });

        if (data.notifications.isNotEmpty) {
          loadFollowingStatusForNotifications();
        }
      } else {
        setState(() {
          isLoading = false;
        });
        log('API error status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      log('Exception when fetching notifications: $e');
    }
  }

  String timeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('dd MMM').format(createdAt);
    }
  }

  Widget getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 12),
        );
      case 'comment':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_bubble, color: Colors.white, size: 12),
        );
      case 'follow':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_add, color: Colors.white, size: 12),
        );
      case 'report':
      case 'report_user':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning, color: Colors.white, size: 12),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String getNotificationMessage(NotificationModel.Notification notification) {
    final senderName = notification.sender.name;
    final type = notification.type;

    switch (type) {
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

  Widget buildNotificationContent(NotificationModel.Notification notification) {
    final bool isReportNotification =
        notification.type == 'report' || notification.type == 'report_user';

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          height: 1.3,
        ),
        children: [
          if (isReportNotification) ...[
            TextSpan(
              text: getNotificationMessage(notification),
              style: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ] else ...[
            TextSpan(
              text: notification.sender.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text:
                  ' ${getNotificationMessage(notification).substring(notification.sender.name.length)}',
              style: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color getNotificationBackgroundColor(
      NotificationModel.Notification notification, bool isRead) {
    if (isRead) return Colors.white;

    switch (notification.type) {
      case 'like':
        return Colors.red.shade50;
      case 'comment':
        return Colors.blue.shade50;
      case 'follow':
        return Colors.green.shade50;
      case 'report':
      case 'report_user':
        return Colors.orange.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Widget buildPostThumbnail(dynamic post) {
    if (post == null || post['images'] == null || post['images'].isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.image,
          color: Colors.grey,
          size: 20,
        ),
      );
    }

    final firstImage = post['images'].first;
    final imageUrl = firstImage['image'] ?? '';

    return GestureDetector(
      onTap: () => _navigateToPostDetail(post['post_id']),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          color: imageUrl.isEmpty ? Colors.grey.shade300 : null,
        ),
        child: imageUrl.isEmpty
            ? const Icon(
                Icons.image,
                color: Colors.grey,
                size: 20,
              )
            : null,
      ),
    );
  }

  Widget buildFollowButton(NotificationModel.Notification notification) {
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
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: isFollowing ? 8 : 12),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.grey.shade100 : Colors.blue,
          borderRadius: BorderRadius.circular(6),
          border: isFollowing ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFollowing) ...[
                Icon(Icons.check, color: Colors.grey.shade600, size: 14),
                const SizedBox(width: 4),
                Text(
                  'กำลังติดตาม',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                const Text(
                  'ติดตามกลับ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
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
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await fetchNotifications();
          },
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2),
                )
              : notificationData == null ||
                      notificationData!.notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'ไม่มีการแจ้งเตือน',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'การแจ้งเตือนจะปรากฏที่นี่',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notificationData!.notifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                            notificationData!.notifications[index];
                        final bool isRead = notification.isRead == 1;
                        final bool isPostNotification =
                            notification.type == 'like' ||
                                notification.type == 'comment' ||
                                notification.type == 'report';

                        return GestureDetector(
                          onTap: () async {
                            if (!isRead) {
                              await markNotificationAsRead(
                                  notification.notificationId);
                            }

                            if (isPostNotification &&
                                notification.post != null) {
                              _navigateToPostDetail(
                                  notification.post['post_id']);
                            }
                          },
                          child: Container(
                            color: getNotificationBackgroundColor(
                                notification, isRead),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundImage: notification
                                                .sender.profileImage.isNotEmpty
                                            ? NetworkImage(notification
                                                .sender.profileImage)
                                            : const AssetImage(
                                                    'assets/images/default_avatar.png')
                                                as ImageProvider,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: getNotificationIcon(
                                            notification.type),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        buildNotificationContent(notification),
                                        if (notification.post != null &&
                                            notification.post['post_topic'] !=
                                                null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            notification.post['post_topic'] ??
                                                '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          timeAgo(notification.createdAt),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (notification.type == 'follow')
                                    buildFollowButton(notification),
                                  if (notification.post != null &&
                                      isPostNotification)
                                    buildPostThumbnail(notification.post),
                                ],
                              ),
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
