  import 'dart:convert';
  import 'dart:developer';
  import 'package:get/get.dart';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'package:get_storage/get_storage.dart';
  import 'package:fontend_pro/config/config.dart';
  import 'package:fontend_pro/models/get_user_uid.dart';
  import 'package:fontend_pro/pages/user_detail_post.dart';
  import 'package:fontend_pro/models/get_post_user.dart' as model;

  class OtherUserProfilePage extends StatefulWidget {
    final int userId; // รับ userId ของคนที่จะดู profile

    const OtherUserProfilePage({
      super.key,
      required this.userId,
    });

    @override
    State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
  }

  class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
    int selectedIndex = 0; // เฉพาะ tab posts เท่านั้น
    GetUserUid? user;
    final GetStorage gs = GetStorage();

    List<model.GetPostUser>? userPosts;
    bool _isInitialLoading = true;
    bool _isRefreshing = false;
    bool _isFollowing = false;
    bool _isFollowLoading = false;

    int followersCount = 0;
    int followingCount = 0;
    int postsCount = 0;

    // ตัวแปรสำหรับเก็บ userId ของผู้ใช้ปัจจุบัน
    int? currentUserId;
    Set<int> followingUserIds = <int>{}; // เพิ่มตัวแปรนี้

    @override
    void initState() {
      super.initState();
      _getCurrentUserId();
      _initializeData();
    }

    void _getCurrentUserId() {
      final uid = gs.read('user');
      if (uid != null) {
        currentUserId = uid is int ? uid : int.tryParse(uid.toString());
      }
    }

    Future<void> _initializeData() async {
      await Future.wait([
        loadDataUser(),
        loadUserPosts(),
        _checkFollowStatus(),
      ]);

      setState(() {
        _isInitialLoading = false;
      });
    }

    Future<void> loadDataUser() async {
      try {
        final uid = widget.userId;
        log("กำลังโหลดข้อมูลของ User ID: $uid");

        final config = await Configuration.getConfig();
        final url = config['apiEndpoint'];
        final response = await http.get(Uri.parse("$url/user/get/$uid"));

        if (response.statusCode == 200) {
          setState(() {
            user = getUserUidFromJson(response.body);
          });
          log("โหลดข้อมูลสำเร็จ: ${response.body}");

          await _loadFollowCounts();
        } else {
          log('โหลดข้อมูลไม่สำเร็จ: ${response.statusCode}');
          throw Exception('โหลดข้อมูลไม่สำเร็จ');
        }
      } catch (e) {
        log('Error loading user data: $e');
        rethrow;
      }
    }

    Future<void> _refreshData() async {
      setState(() {
        _isRefreshing = true;
      });

      try {
        await Future.wait([
          loadDataUser(),
          loadUserPosts(),
          _checkFollowStatus(),
        ]);
      } catch (e) {
        log('Error refreshing data: $e');
      } finally {
        setState(() {
          _isRefreshing = false;
        });
      }
    }

    Future<void> loadUserPosts() async {
      try {
        final uid = widget.userId;
        log('UID ที่โหลดข้อมูล: $uid');

        final config = await Configuration.getConfig();
        final url = config['apiEndpoint'];
        final fullUrl = "$url/image_post/by-user/$uid";
        log('เรียก API ที่ URL: $fullUrl');

        final response = await http.get(Uri.parse(fullUrl));
        log('สถานะการตอบกลับ: ${response.statusCode}');

        if (response.statusCode != 200) {
          log('ข้อความตอบกลับ: ${response.body}');
          throw Exception("โหลดโพสต์ไม่สำเร็จ");
        }

        log('ข้อมูล JSON ที่ได้: ${response.body}');

        final posts = model.getPostUserFromJson(response.body);
        log('จำนวนโพสต์ที่โหลดได้: ${posts.length}');

        setState(() {
          userPosts = posts;
          postsCount = posts.length;
        });
      } catch (e) {
        log('Error loading user posts: $e');
        setState(() {
          userPosts = [];
          postsCount = 0;
        });
      }
    }

    // ฟังก์ชันสำหรับเช็คสถานะการติดตาม
    Future<void> _checkFollowStatus() async {
      if (currentUserId == null) return;

      try {
        final config = await Configuration.getConfig();
        final url = config['apiEndpoint'];
        final uri = Uri.parse('$url/user/is-following').replace(queryParameters: {
          'follower_id': currentUserId.toString(),
          'following_id': widget.userId.toString(),
        });

        log('เรียก API is-following: $uri');
        final response = await http.get(uri);
        log('Response Status (is-following): ${response.statusCode}');
        log('Response Body (is-following): ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final isFollowing = data['isFollowing'] ?? false;
          setState(() {
            _isFollowing = isFollowing;
            if (isFollowing) {
              followingUserIds.add(widget.userId);
            } else {
              followingUserIds.remove(widget.userId);
            }
          });
          log('Follow status: $_isFollowing');
        } else {
          log('Failed to check follow status: ${response.statusCode}');
          setState(() {
            _isFollowing = false;
          });
        }
      } catch (e) {
        log('Error checking follow status: $e');
        setState(() {
          _isFollowing = false;
        });
      }
    }

    // ฟังก์ชันสำหรับติดตามผู้ใช้
    Future<void> followUser(int targetUserId) async {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      try {
        final response = await http.post(
          Uri.parse('$url/user/follow'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "follower_id": currentUserId,
            "following_id": targetUserId,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          log('ติดตามผู้ใช้ $targetUserId สำเร็จ');
          setState(() {
            followingUserIds.add(targetUserId);
            _isFollowing = true;
            followersCount++;
          });
        } else {
          log('เกิดข้อผิดพลาดในการติดตาม: ${response.body}');
          _showErrorSnackBar('ไม่สามารถติดตามได้ในขณะนี้');
        }
      } catch (e) {
        log('Error following user: $e');
        _showErrorSnackBar('เกิดข้อผิดพลาดในการติดตาม');
      }
    }

    // ฟังก์ชันสำหรับเลิกติดตามผู้ใช้
    Future<void> unfollowUser(int targetUserId) async {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      try {
        final uri = Uri.parse('$url/user/unfollow');
        final request = http.Request('DELETE', uri);
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode({
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          log('เลิกติดตามผู้ใช้ $targetUserId สำเร็จ');
          setState(() {
            followingUserIds.remove(targetUserId);
            _isFollowing = false;
            followersCount = followersCount > 0 ? followersCount - 1 : 0;
          });
        } else {
          log('เกิดข้อผิดพลาดในการเลิกติดตาม: ${response.body}');
          _showErrorSnackBar('ไม่สามารถเลิกติดตามได้ในขณะนี้');
        }
      } catch (e) {
        log('Error unfollowing user: $e');
        _showErrorSnackBar('เกิดข้อผิดพลาดในการเลิกติดตาม');
      }
    }

    // ฟังก์ชันสำหรับแสดงข้อความแจ้งเตือนเมื่อเกิดข้อผิดพลาด
    void _showErrorSnackBar(String message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // ฟังก์ชันสำหรับติดตาม/เลิกติดตาม (ปรับปรุงแล้ว)
    Future<void> _toggleFollow() async {
      if (currentUserId == null || _isFollowLoading) return;

      setState(() {
        _isFollowLoading = true;
      });

      try {
        if (_isFollowing) {
          await unfollowUser(widget.userId);
        } else {
          await followUser(widget.userId);
        }
      } catch (e) {
        log('Error toggling follow: $e');
        _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isFollowLoading = false;
          });
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            user?.name ?? "username",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.black,
                size: 24,
              ),
              onPressed: _showMoreOptionsBottomSheet,
            ),
          ],
        ),
        body: _isInitialLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.black,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.grey[300]!, width: 1),
                                  ),
                                  child: CircleAvatar(
                                    radius: 42,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: user?.profileImage != null
                                        ? NetworkImage(user!.profileImage!)
                                        : null,
                                    child: user?.profileImage == null
                                        ? Icon(Icons.person,
                                            size: 40, color: Colors.grey[600])
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Text(postsCount.toString(),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              )),
                                          const SizedBox(height: 2),
                                          Text('โพส',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              )),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(followersCount.toString(),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              )),
                                          const SizedBox(height: 2),
                                          Text('ผู้ติดตาม',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              )),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(followingCount.toString(),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              )),
                                          const SizedBox(height: 2),
                                          Text('กำลังติดตาม',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (user?.personalDescription != null &&
                                user!.personalDescription!.trim().isNotEmpty)
                              Text(
                                user!.personalDescription!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // ปุ่มสำหรับติดตาม/เลิกติดตาม
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _isFollowing
                                      ? Colors.grey[200]
                                      : const Color.fromARGB(255, 0, 0, 0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap:
                                        _isFollowLoading ? null : _toggleFollow,
                                    child: Center(
                                      child: _isFollowLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _isFollowing
                                                  ? "กำลังติดตาม"
                                                  : "ติดตาม",
                                              style: TextStyle(
                                                color: _isFollowing
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Colors.grey[300]!, width: 0.5),
                              ),
                            ),
                            child: Container(
                              height: 44,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.grid_on_outlined,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                          ),
                          _buildPostsGrid(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      );
    }

    Widget _buildPostsGrid() {
      // แสดง loading indicator เฉพาะตอน refresh
      if (userPosts == null && _isRefreshing) {
        return Container(
          height: 200,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
          ),
        );
      }

      // ถ้าไม่มีข้อมูลหรือข้อมูลว่าง
      if (userPosts == null || userPosts!.isEmpty) {
        return Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ยังไม่มีโพสต์',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                'เมื่อผู้ใช้แชร์ภาพถ่ายและวิดีโอ\nภาพเหล่านั้นจะปรากฏที่นี่',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      // แสดง GridView
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1),
        itemCount: userPosts!.length,
        itemBuilder: (context, index) {
          final post = userPosts![index];
          String? imageUrl =
              post.images.isNotEmpty ? post.images.first.image : null;
          int? postId = post.post.postId;

          return GestureDetector(
            onTap: () {
              if (postId != null) {
                log('Navigating to post detail with ID: $postId');
                Get.to(() => UserDetailPostPage(postId: postId));
              }
            },
            child: Container(
              color: Colors.grey[100],
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.broken_image,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Icon(
                      Icons.image_outlined,
                      color: Colors.grey[400],
                      size: 40,
                    ),
            ),
          );
        },
      );
    }

    void _showMoreOptionsBottomSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.report_outlined),
                  title: const Text('รายงาน'),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog();
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    // แก้ไขฟังก์ชัน _showReportDialog
    void _showReportDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ReportUserDialog(
            onReport: (reason) async {
              await _reportUser(reason);
            },
          );
        },
      );
    }

    // ฟังก์ชันเรียก API report-user (ปรับปรุงแล้ว)
    Future<void> _reportUser(String reason) async {
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถรายงานได้ กรุณาเข้าสู่ระบบใหม่'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // แสดง loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('กำลังรายงาน...'),
              ],
            ),
          );
        },
      );

      try {
        final config = await Configuration.getConfig();
        final url = config['apiEndpoint'];
        final uri = Uri.parse('$url/image_post/report-user');

        log('Sending report request: reporter_id=$currentUserId, reported_id=${widget.userId}, reason=$reason');

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            "reporter_id": currentUserId,
            "reported_id": widget.userId,
            "reason": reason,
          }),
        );

        // ปิด loading dialog
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        log('Report response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('รายงานผู้ใช้สำเร็จ ขอบคุณสำหรับการแจ้ง'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          String errorMessage = 'เกิดข้อผิดพลาด';
          try {
            final data = jsonDecode(response.body);
            errorMessage = data['message'] ?? errorMessage;
          } catch (e) {
            log('Error parsing error response: $e');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // ปิด loading dialog ถ้ายังเปิดอยู่
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        log('Error reporting user: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการรายงาน กรุณาลองใหม่อีกครั้ง'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    void _showBlockDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'บล็อกผู้ใช้',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'คุณต้องการบล็อกผู้ใช้นี้หรือไม่?',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ฟีเจอร์บล็อกยังไม่พร้อมใช้งาน'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('บล็อก'),
              ),
            ],
          );
        },
      );
    }

    Future<int> getFollowersCount(int uid) async {
      try {
        final config = await Configuration.getConfig();
        final apiEndpoint = config['apiEndpoint'];
        final url = Uri.parse('$apiEndpoint/user/followers-count/$uid');

        log('เรียก API followers-count: $url');
        final response = await http.get(url);
        log('Response Status (followers): ${response.statusCode}');
        log('Response Body (followers): ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          log('Parsed data (followers): $data');

          int count = 0;
          if (data is Map<String, dynamic>) {
            if (data.containsKey('followers')) {
              count = data['followers'] ?? 0;
            } else if (data.containsKey('COUNT(*)')) {
              count = data['COUNT(*)'] ?? 0;
            }
          }

          log('Final followers count: $count');
          return count;
        } else {
          log('Failed to load followers count: ${response.statusCode}');
          return 0;
        }
      } catch (e) {
        log('Error getting followers count: $e');
        return 0;
      }
    }

    Future<int> getFollowingCount(int uid) async {
      try {
        final config = await Configuration.getConfig();
        final apiEndpoint = config['apiEndpoint'];
        final url = Uri.parse('$apiEndpoint/user/following-count/$uid');

        log('เรียก API following-count: $url');
        final response = await http.get(url);
        log('Response Status (following): ${response.statusCode}');
        log('Response Body (following): ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          log('Parsed data (following): $data');

          int count = 0;
          if (data is Map<String, dynamic>) {
            if (data.containsKey('following')) {
              count = data['following'] ?? 0;
            } else if (data.containsKey('COUNT(*)')) {
              count = data['COUNT(*)'] ?? 0;
            }
          }

          log('Final following count: $count');
          return count;
        } else {
          log('Failed to load following count: ${response.statusCode}');
          return 0;
        }
      } catch (e) {
        log('Error getting following count: $e');
        return 0;
      }
    }

    Future<void> _loadFollowCounts() async {
      if (user?.uid == null) {
        log('User UID is null, cannot load follow counts');
        return;
      }

      try {
        final followers = await getFollowersCount(user!.uid!);
        final following = await getFollowingCount(user!.uid!);

        setState(() {
          followersCount = followers;
          followingCount = following;
        });

        log('Followers count loaded: $followersCount');
        log('Following count loaded: $followingCount');
      } catch (e) {
        log('Error loading follow counts: $e');
        setState(() {
          followersCount = 0;
          followingCount = 0;
        });
      }
    }
  }

  // สร้าง ReportUserDialog เป็น StatefulWidget แยก
  class ReportUserDialog extends StatefulWidget {
    final Function(String) onReport;

    const ReportUserDialog({
      Key? key,
      required this.onReport,
    }) : super(key: key);

    @override
    State<ReportUserDialog> createState() => _ReportUserDialogState();
  }

  class _ReportUserDialogState extends State<ReportUserDialog> {
    String? selectedReason;

    final List<String> reportReasons = [
      "สแปม / โฆษณา",
      "พฤติกรรมไม่เหมาะสม",
      "ปลอมตัว / ขโมยข้อมูล",
      "อื่นๆ",
    ];

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'รายงานผู้ใช้',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: reportReasons.map((reason) {
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedReason = reason;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: selectedReason == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.onReport(selectedReason!);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedReason == null ? Colors.grey[300] : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'รายงาน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedReason == null ? Colors.grey[600] : Colors.white,
              ),
            ),
          ),
        ],
      );
    }
  }
