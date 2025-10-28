import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/user_detail_post.dart';
import 'package:fontend_pro/pages/other_user_profile.dart';
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
  Map<int, String> followingStatus = {}; // uid -> status
  final GetStorage gs = GetStorage();

  @override
  void initState() {
    super.initState();
    loggedInUid = gs.read('user') ?? 0;
    log('Logged in UID: $loggedInUid');
    fetchNotifications();
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

        // ดึงสถานะการติดตามจริงๆ จาก API
        if (data.notifications.isNotEmpty) {
          for (var n in data.notifications) {
            await checkFollowingStatus(n.sender.uid);
          }
        }
      } else {
        setState(() => isLoading = false);
        log('API error status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      log('Exception when fetching notifications: $e');
    }
  }

  // 🔹 เช็คสถานะการติดตาม - แก้ไขตรรกะให้ถูกต้อง
  Future<void> checkFollowingStatus(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      // 🔹 เช็ค 2 ทิศทาง
      // 1. เขาติดตามเราหรือไม่ (สำหรับ accept/reject)
      final theyFollowUsResponse = await http.get(
        Uri.parse(
            '$url/user/is-following?follower_id=$targetUserId&following_id=$loggedInUid'),
      );

      // 2. เราติดตามเขาหรือไม่ (สำหรับ unfollow)
      final weFollowThemResponse = await http.get(
        Uri.parse(
            '$url/user/is-following?follower_id=$loggedInUid&following_id=$targetUserId'),
      );

      if (theyFollowUsResponse.statusCode == 200 &&
          weFollowThemResponse.statusCode == 200) {
        final theyFollowData = jsonDecode(theyFollowUsResponse.body);
        final weFollowData = jsonDecode(weFollowThemResponse.body);

        final bool theyFollowUs = theyFollowData['isFollowing'] ?? false;
        final String? theirStatus = theyFollowData['status'];

        final bool weFollowThem = weFollowData['isFollowing'] ?? false;
        final String? ourStatus = weFollowData['status'];

        setState(() {
          // กรณีที่ 1: เขาส่ง follow request มา แต่เรายังไม่ยอมรับ
          if (theyFollowUs && theirStatus == 'pending') {
            followingStatus[targetUserId] = 'pending';
          }
          // กรณีที่ 2: เขาติดตามเราแล้ว (accepted) และเราก็ติดตามเขาแล้ว
          else if (theyFollowUs &&
              theirStatus == 'accepted' &&
              weFollowThem &&
              ourStatus == 'accepted') {
            followingStatus[targetUserId] = 'both_following';
          }
          // กรณีที่ 3: เขาติดตามเราแล้ว แต่เรายังไม่ได้ติดตามกลับ
          else if (theyFollowUs && theirStatus == 'accepted' && !weFollowThem) {
            followingStatus[targetUserId] = 'follow_back';
          }
          // กรณีที่ 4: เราติดตามเขาแล้ว แต่เขายังไม่ได้ติดตามเรา
          else if (weFollowThem && ourStatus == 'accepted' && !theyFollowUs) {
            followingStatus[targetUserId] = 'we_follow_only';
          }
          // กรณีที่ 5: เราส่ง follow request ไป แต่เขายังไม่ยอมรับ
          else if (weFollowThem && ourStatus == 'pending') {
            followingStatus[targetUserId] = 'request_sent';
          }
          // กรณีอื่นๆ: ยังไม่มีความสัมพันธ์
          else {
            followingStatus[targetUserId] = 'none';
          }
        });

        log('Follow status for user $targetUserId: ${followingStatus[targetUserId]}');
      }
    } catch (e) {
      log('Error checking follow status: $e');
      setState(() {
        followingStatus[targetUserId] = 'none';
      });
    }
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

  // 🔹 ยอมรับคำขอติดตาม (Accept Follow Request)
  Future<void> acceptFollowRequest(int followerUid) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.put(
        Uri.parse('$url/user/accept-follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "follower_id": followerUid,
          "following_id": loggedInUid,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('ยอมรับคำขอติดตามแล้ว', Colors.green);
        // เช็คสถานะใหม่จาก API
        await checkFollowingStatus(followerUid);
      } else {
        _showSnackBar('ไม่สามารถยอมรับได้', Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด', Colors.red);
      log('Error accepting follow: $e');
    }
  }

  // 🔹 ปฏิเสธคำขอติดตาม (Reject Follow Request)
  Future<void> rejectFollowRequest(int followerUid) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final request =
          http.Request('DELETE', Uri.parse('$url/user/reject-follow'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'follower_id': followerUid,
        'following_id': loggedInUid,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _showSnackBar('ปฏิเสธคำขอติดตามแล้ว', Colors.orange);
        await fetchNotifications(); // รีเฟรช notification
      } else {
        _showSnackBar('ไม่สามารถปฏิเสธได้', Colors.red);
        log('Reject follow failed: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด', Colors.red);
      log('Error rejecting follow: $e');
    }
  }

  // 🔹 ติดตามกลับ (Follow Back)
  Future<void> followBackUser(int targetUserId) async {
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
        _showSnackBar('ติดตามกลับสำเร็จ', Colors.green);
        // เช็คสถานะใหม่จาก API
        await checkFollowingStatus(targetUserId);
      } else {
        _showSnackBar('ไม่สามารถติดตามกลับได้', Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการติดตามกลับ', Colors.red);
      log('Error following back: $e');
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
        _showSnackBar('เลิกติดตามสำเร็จ', Colors.green);
        // เช็คสถานะใหม่จาก API
        await checkFollowingStatus(targetUserId);
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

  String timeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inSeconds < 60) return 'เมื่อสักครู่';
    if (difference.inMinutes < 60) return '${difference.inMinutes} นาทีที่แล้ว';
    if (difference.inHours < 24) return '${difference.inHours} ชั่วโมงที่แล้ว';
    if (difference.inDays < 7) return '${difference.inDays} วันที่แล้ว';
    return DateFormat('dd MMM').format(createdAt);
  }

  // ------------------------------------------------------------
  // 🔹 ปุ่มต่างๆ
  // ------------------------------------------------------------
  Widget acceptFollowButton(int followerUid) {
    return GestureDetector(
      onTap: () async {
        await acceptFollowRequest(followerUid);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('ยอมรับ',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget rejectFollowButton(int followerUid) {
    return GestureDetector(
      onTap: () async {
        await rejectFollowRequest(followerUid); // <-- เรียกฟังก์ชัน reject
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Center(
          child: Text('ปฏิเสธ',
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget followBackButton(int targetUserId) {
    return GestureDetector(
      onTap: () async {
        await followBackUser(targetUserId);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('ติดตามกลับ',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget unfollowUserButton(int targetUserId) {
    return GestureDetector(
      onTap: () async {
        await unfollowUser(targetUserId);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
        ),
        child: const Center(
          child: Text('เลิกติดตาม',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget requestSentButton() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text('รอการยอมรับ',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔹 แสดงปุ่มตาม notification type และ status
  // ------------------------------------------------------------
  Widget buildFollowButton(NotificationModel.NotificationItem notification) {
    final senderUid = notification.sender.uid;
    final status = followingStatus[senderUid] ?? 'none';

    // ถ้า type เป็น 'follow' หรือ 'user' = เป็นการแจ้งเตือนว่ามีคนขอติดตาม
    final isFollowNotification = notification.type.toLowerCase() == 'follow' ||
        notification.type.toLowerCase() == 'user';

    // ถ้าไม่ใช่ notification ประเภทติดตาม ไม่ต้องแสดงปุ่ม
    if (!isFollowNotification) {
      return const SizedBox.shrink();
    }

    // แสดงปุ่มตามสถานะ
    switch (status) {
      case 'pending':
        // เขาส่ง request มา → แสดงปุ่ม "ยอมรับ" และ "ปฏิเสธ"
        return Row(
          children: [
            acceptFollowButton(senderUid),
            const SizedBox(width: 8),
            rejectFollowButton(senderUid),
          ],
        );

      case 'follow_back':
        // เขาติดตามเราแล้ว แต่เรายังไม่ได้ติดตามกลับ → "ติดตามกลับ"
        return followBackButton(senderUid);

      case 'both_following':
        // ติดตามกันแล้วทั้งสองฝ่าย → "เลิกติดตาม"
        return unfollowUserButton(senderUid);

      case 'we_follow_only':
        // เราติดตามเขาแล้ว แต่เขายังไม่ติดตามเรา → "เลิกติดตาม"
        return unfollowUserButton(senderUid);

      case 'request_sent':
        // เราส่ง request ไปแล้ว รอเขายอมรับ → แสดงสถานะ "รอการยอมรับ"
        return requestSentButton();

      case 'none':
      default:
        // ยังไม่มีความสัมพันธ์ → ในกรณี notification แสดง "ยอมรับ" และ "ปฏิเสธ"
        return Row(
          children: [
            acceptFollowButton(senderUid),
            const SizedBox(width: 8),
            rejectFollowButton(senderUid),
          ],
        );
    }
  }

  Widget getNotificationIcon(NotificationModel.NotificationItem notification) {
    final senderUid = notification.sender.uid;
    final status = followingStatus[senderUid] ?? 'none';

    // ไม่แสดง icon สีเขียวถ้าติดตามกันแล้ว
    if (status == 'both_following' || status == 'follow_back')
      return const SizedBox.shrink();

    switch (notification.type.toUpperCase()) {
      case 'USER':
      case 'FOLLOW':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.blue,
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
    final messageText = notification.message.toLowerCase();
    final status = followingStatus[notification.sender.uid] ?? 'none';

    if (messageText.contains('กดถูกใจ')) {
      return '$senderName ถูกใจโพสต์ของคุณ';
    } else if (messageText.contains('คอมเมนต์')) {
      return '$senderName แสดงความคิดเห็นในโพสต์ของคุณ';
    } else if (messageText.contains('ติดตาม')) {
      if (status == 'both_following') {
        return '$senderName และคุณติดตามกันแล้ว';
      } else if (status == 'follow_back') {
        return '$senderName เริ่มติดตามคุณ';
      } else {
        return '$senderName ส่งคำขอการติดตามคุณ';
      }
    } else {
      // เผื่อไว้ถ้าเป็นข้อความอื่น
      return '$senderName ${notification.message}';
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
        const SizedBox(height: 2),
        Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color getNotificationBackgroundColor(
      NotificationModel.NotificationItem notification, bool isRead) {
    return isRead ? Colors.white : Colors.blue.shade50;
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserDetailPostPage(postId: post.postId ?? 0),
        ),
      ),
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

  // ------------------------------------------------------------
  // 🔹 UI หลัก
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
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
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
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
                                      postId: notification.post!.postId!),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: getNotificationBackgroundColor(
                                  notification, isRead),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (notification.sender.uid !=
                                        loggedInUid) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OtherUserProfilePage(
                                                  userId:
                                                      notification.sender.uid),
                                        ),
                                      );
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
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
                                      const SizedBox(height: 8),
                                      Text(
                                        timeAgo(notification.createdAt),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                      // แสดงปุ่มสำหรับ follow notification
                                      // ✅ แสดงปุ่มเฉพาะเมื่อเป็นการติดตาม
                                      if (notification.message
                                          .toLowerCase()
                                          .contains('ติดตาม'))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child:
                                              buildFollowButton(notification),
                                        ),
                                    ],
                                  ),
                                ),
                                // แสดง thumbnail สำหรับ post notification
                                if (notification.post != null) ...[
                                  const SizedBox(width: 12),
                                  buildPostThumbnail(notification.post),
                                ],
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
