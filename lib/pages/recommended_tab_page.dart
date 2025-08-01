import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/like_post.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:fontend_pro/models/get_all_post.dart' as model;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RecommendedTab extends StatefulWidget {
  final PageController pageController;
  const RecommendedTab({super.key, required this.pageController});

  @override
  State<RecommendedTab> createState() => _RecommendedTabState();
}

class _RecommendedTabState extends State<RecommendedTab> {
  List<GetAllCategory> category = [];
  List<model.GetAllPost> allPosts = [];
  List<model.GetAllPost> filteredPosts = [];

  int selectedIndex = -1;
  int? selectedCid;
  GetStorage gs = GetStorage();

  Map<int, bool> showHeartMap = {};
  Map<int, int> likeCountMap = {};
  Map<int, bool> likedMap = {};

  bool isInitialLoading = true;

  // เพิ่มตัวแปรสำหรับ real-time update
  Timer? _timer;

  late int loggedInUid;

  // เก็บ uid ของผู้ใช้ที่ติดตามอยู่ (สถานะติดตาม)
  Set<int> followingUserIds = {};

  @override
  void initState() {
    super.initState();
    loadInitialData();
    var user = gs.read('user');
    dev.log(user.toString());

    // เริ่มต้น timer สำหรับ update เวลาทุก 30 วินาที
    _startTimer();

    dynamic rawUid = gs.read('user');
    if (rawUid is int) {
      loggedInUid = rawUid;
    } else if (rawUid is String) {
      loggedInUid = int.tryParse(rawUid) ?? 0;
    } else {
      loggedInUid = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // เริ่มต้น timer สำหรับ update เวลา
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          // Force rebuild เพื่อ update เวลา
        });
      }
    });
  }

  // ฟังก์ชันแปลงเวลาเป็นรูปแบบ Instagram
  String _formatTimeAgo(DateTime postDate) {
    final now = DateTime.now();
    final difference = now.difference(postDate);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks สัปดาห์ที่แล้ว';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ปีที่แล้ว';
    }
  }

  Future<void> loadInitialData() async {
    setState(() {
      isInitialLoading = true;
    });
    await loadCategories();
    await loadAllPosts();
    setState(() {
      isInitialLoading = false;
    });
  }

  Future<void> loadCategories() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final categoryResponse = await http.get(Uri.parse("$url/category/get"));
      if (categoryResponse.statusCode == 200) {
        category = getAllCategoryFromJson(categoryResponse.body);
      } else {
        throw Exception('โหลดหมวดหมู่ไม่สำเร็จ');
      }
    } catch (e) {
      dev.log('Error loading categories: $e');
    }
  }

  // เพิ่มฟังก์ชันใหม่สำหรับโหลดสถานะการติดตาม
  Future<void> loadFollowingStatus() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      // เคลียร์ข้อมูลเก่า
      followingUserIds.clear();

      // ตรวจสอบสถานะการติดตามสำหรับทุกคนในโพสต์
      Set<int> uniqueUserIds = allPosts.map((post) => post.user.uid).toSet();

      for (int targetUserId in uniqueUserIds) {
        if (targetUserId != loggedInUid) {
          // ไม่ตรวจสอบตัวเอง
          final response = await http.get(
            Uri.parse(
                '$url/user/is-following?follower_id=$loggedInUid&following_id=$targetUserId'),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['isFollowing'] == true) {
              followingUserIds.add(targetUserId);
            }
          }
        }
      }

      // อัพเดต UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      dev.log('Error loading following status: $e');
    }
  }

  // แก้ไขฟังก์ชัน loadAllPosts เพื่อโหลดสถานะการติดตามด้วย
  Future<void> loadAllPosts() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final uid = gs.read('user');

      final postResponse = await http.get(Uri.parse("$url/image_post/get"));
      final likedResponse =
          await http.get(Uri.parse("$url/image_post/liked-posts/$uid"));

      if (postResponse.statusCode == 200 && likedResponse.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(postResponse.body);
        allPosts =
            jsonData.map((item) => model.GetAllPost.fromJson(item)).toList();
        filteredPosts = allPosts;

        // 1. เก็บโพสต์ที่ผู้ใช้เคยกดไลก์
        final likedIds = jsonDecode(likedResponse.body)['likedPostIds'];
        final likedSet = Set<int>.from(likedIds);

        // 2. เคลียร์ข้อมูลก่อน
        showHeartMap.clear();
        likeCountMap.clear();
        likedMap.clear();

        // 3. กำหนดค่า likedMap และ likeCountMap ตามโพสต์ที่โหลดมา
        for (var postItem in allPosts) {
          final postId = postItem.post.postId;
          likeCountMap[postId] = postItem.post.amountOfLike;
          likedMap[postId] = likedSet.contains(postId);
        }

        // 4. สร้าง map สำหรับแสดงหัวใจ
        for (int i = 0; i < filteredPosts.length; i++) {
          showHeartMap[i] = false;
        }

        // 5. โหลดสถานะการติดตาม
        await loadFollowingStatus();
      } else {
        throw Exception('โหลดโพสต์หรือโพสต์ที่ไลก์ไม่สำเร็จ');
      }
    } catch (e) {
      dev.log('Error loading posts: $e');
      allPosts = [];
      filteredPosts = [];
      likedMap.clear();
      likeCountMap.clear();
      showHeartMap.clear();
      followingUserIds.clear();
    }
  }

  void filterPostsByCategory(int? cid) {
    setState(() {
      selectedCid = cid;
      selectedIndex = cid == null
          ? -1
          : category.indexWhere((element) => element.cid == cid);

      if (cid == null) {
        filteredPosts = allPosts;
      } else {
        filteredPosts = allPosts.where((post) {
          return post.categories.any((cat) => cat.cid == cid);
        }).toList();
      }

      showHeartMap.clear();
      for (int i = 0; i < filteredPosts.length; i++) {
        showHeartMap[i] = false;
      }
    });
  }

  void likePost(int postId) async {
    final uid = gs.read('user'); // อ่าน user id จาก GetStorage
    final isLiked = likedMap[postId] ?? false;

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      // ✅ สลับ endpoint ตามสถานะ like/unlike
      final endpoint = isLiked ? '/image_post/unlike' : '/image_post/like';
      final uri = Uri.parse('$url$endpoint');

      final likeModel = LikePost(userId: uid, postId: postId);
      final bodyJson = likePostToJson(likeModel);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: bodyJson,
      );

      if (response.statusCode == 200) {
        setState(() {
          likedMap[postId] = !isLiked;

          if (!isLiked) {
            // กดไลก์
            likeCountMap[postId] = (likeCountMap[postId] ?? 0) + 1;
          } else {
            // กดยกเลิกไลก์
            likeCountMap[postId] = (likeCountMap[postId] ?? 1) - 1;
            if (likeCountMap[postId]! < 0) {
              likeCountMap[postId] = 0; // ป้องกันติดลบ
            }
          }
        });
      } else {
        dev.log("Like/Unlike API failed: ${response.body}");
      }
    } catch (e) {
      dev.log("Error like/unlike post: $e");
    }
  }

  // แก้ไขฟังก์ชัน followUser
  Future<void> followUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse('$url/user/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'follower_id': loggedInUid,
          'following_id': targetUserId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        dev.log('ติดตามผู้ใช้ $targetUserId สำเร็จ: ${data['message']}');

        setState(() {
          followingUserIds.add(targetUserId);
        });
      } else {
        final errorData = jsonDecode(response.body);
        dev.log(
            'เกิดข้อผิดพลาดในการติดตาม: ${errorData['error'] ?? errorData['message']}');

        // แสดง snackbar หรือ dialog แจ้งเตือนผู้ใช้
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['error'] ?? 'เกิดข้อผิดพลาดในการติดตาม'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      dev.log('Error following user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // แก้ไขฟังก์ชัน unfollowUser
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
        final data = jsonDecode(response.body);
        dev.log('เลิกติดตามผู้ใช้ $targetUserId สำเร็จ: ${data['message']}');

        setState(() {
          followingUserIds.remove(targetUserId);
        });
      } else {
        final errorData = jsonDecode(response.body);
        dev.log(
            'เกิดข้อผิดพลาดในการเลิกติดตาม: ${errorData['error'] ?? errorData['message']}');

        // แจ้งเตือนผู้ใช้ถ้าไม่พบข้อมูลการติดตาม หรือเกิดข้อผิดพลาดอื่นๆ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['error'] ??
                  errorData['message'] ??
                  'เกิดข้อผิดพลาดในการเลิกติดตาม'),
              backgroundColor:
                  response.statusCode == 404 ? Colors.orange : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      dev.log('Error unfollowing user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // เพิ่มฟังก์ชันตรวจสอบสถานะการติดตามแบบเฉพาะเจาะจง (ถ้าต้องการใช้)
  Future<bool> checkFollowingStatus(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.get(
        Uri.parse(
            '$url/user/is-following?follower_id=$loggedInUid&following_id=$targetUserId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFollowing'] ?? false;
      }
    } catch (e) {
      dev.log('Error checking following status: $e');
    }

    return false;
  }

  // เพิ่มฟังก์ชัน buildFollowButton สำหรับจัดการปุ่มติดตาม
  Widget buildFollowButton(model.GetAllPost postItem) {
    final isFollowing = followingUserIds.contains(postItem.user.uid);
    final isSelf = postItem.user.uid == loggedInUid;

    if (isSelf) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isFollowing) {
              unfollowUser(postItem.user.uid);
            } else {
              followUser(postItem.user.uid);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              horizontal: isFollowing ? 9 : 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.grey[50] : Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFollowing ? Colors.grey[300]! : Colors.black87,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isFollowing
                        ? Icons.check_rounded
                        : Icons.person_add_rounded,
                    key: ValueKey(isFollowing),
                    size: 15,
                    color: isFollowing ? Colors.green[600] : Colors.white,
                  ),
                ),
                if (!isFollowing) ...[
                  const SizedBox(width: 6),
                  Text(
                    'ติดตาม',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Enhanced Category Filter Section
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  // "ทั้งหมด" button with modern gradient
                  GestureDetector(
                    onTap: () => filterPostsByCategory(null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: selectedCid == null
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF2C2C2C),
                                  const Color(0xFF1A1A1A),
                                  const Color(0xFF000000),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: const [0.0, 0.5, 1.0],
                              )
                            : null,
                        color: selectedCid == null ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: selectedCid == null
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 1,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedCid == null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.apps_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          Text(
                            'ทั้งหมด',
                            style: TextStyle(
                              color: selectedCid == null
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                              fontWeight: selectedCid == null
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Category buttons with modern styling
                  ...category.map((cate) {
                    final cid = cate.cid;
                    final isSelected = selectedCid == cid;
                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => filterPostsByCategory(cid),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFF2C2C2C),
                                      const Color(0xFF1A1A1A),
                                      const Color(0xFF000000),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    stops: const [0.0, 0.5, 1.0],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.05),
                                      blurRadius: 1,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              Text(
                                cate.cname,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),

          Expanded(
            child: filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_outlined,
                            size: 36,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีโพสต์ในหมวดหมู่นี้',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ลองเลือกหมวดหมู่อื่น หรือสร้างโพสต์ใหม่',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final postItem = filteredPosts[index];
                      final pageController = PageController();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 1),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Instagram-style Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  // Profile image
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple,
                                          Colors.pink,
                                          Colors.orange,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            postItem.user.profileImage),
                                        radius: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Username and time
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          postItem.user.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          _formatTimeAgo(
                                              postItem.post.postDate),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Follow button and menu
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      buildFollowButton(postItem),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        onPressed: () {
                                          // Show menu
                                        },
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Image Section (Instagram style - full width)
                            if (postItem.images.isNotEmpty)
                              SizedBox(
                                height: 400, // Fixed Instagram-like height
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    PageView(
                                      controller: pageController,
                                      children: postItem.images.map((img) {
                                        return GestureDetector(
                                          onDoubleTap: () async {
                                            likePost(postItem.post.postId);
                                            setState(() =>
                                                showHeartMap[index] = true);
                                            await Future.delayed(
                                                const Duration(seconds: 1));
                                            setState(() =>
                                                showHeartMap[index] = false);
                                          },
                                          child: Image.network(
                                            img.image,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                color: Colors.grey[100],
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.black,
                                                    strokeWidth: 2,
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                height: 400,
                                                color: Colors.grey[100],
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.error_outline,
                                                          color:
                                                              Colors.grey[400],
                                                          size: 32),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'ไม่สามารถโหลดรูปภาพได้',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    // Heart animation
                                    Center(
                                      child: AnimatedScale(
                                        scale: showHeartMap[index] == true
                                            ? 1.2
                                            : 0.0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.elasticOut,
                                        child: AnimatedOpacity(
                                          opacity: showHeartMap[index] == true
                                              ? 1.0
                                              : 0.0,
                                          duration:
                                              const Duration(milliseconds: 200),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.8),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 20,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.favorite,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Page indicator (Instagram style - top right)
                                    if (postItem.images.length > 1)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '1/${postItem.images.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            // Action buttons (Instagram style)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  // Like button
                                  GestureDetector(
                                    onTap: () => likePost(postItem.post.postId),
                                    child: Icon(
                                      likedMap[postItem.post.postId] == true
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: likedMap[postItem.post.postId] ==
                                              true
                                          ? const Color.fromARGB(255, 0, 0, 0)
                                          : Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Comment button
                                  GestureDetector(
                                    onTap: () {
                                      // Handle comment
                                    },
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Share button
                                  GestureDetector(
                                    onTap: () {
                                      // Handle share
                                    },
                                    child: const Icon(
                                      Icons.send_outlined,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),

                                  const Spacer(),

                                  // Save button
                                  GestureDetector(
                                    onTap: () {
                                      // Handle save
                                    },
                                    child: const Icon(
                                      Icons.bookmark_border,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Likes count
                            if ((likeCountMap[postItem.post.postId] ?? 0) > 0)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${likeCountMap[postItem.post.postId]} คนถูกใจ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            // Caption
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (postItem.post.postTopic != null)
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                          height: 1.3,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${postItem.user.name} ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: postItem.post.postTopic!,
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (postItem.post.postDescription != null &&
                                      postItem.post.postDescription!
                                          .trim()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        postItem.post.postDescription!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Hashtags
                            if (postItem.hashtags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: Wrap(
                                  spacing: 4,
                                  children: postItem.hashtags.map((tag) {
                                    return Text(
                                      '#${tag.tagName}',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                            // Categories (simplified)
                            if (postItem.categories.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: Text(
                                  postItem.categories
                                      .map((cat) => cat.cname)
                                      .join(' • '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
