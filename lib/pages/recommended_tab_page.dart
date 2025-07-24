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

  @override
  void initState() {
    super.initState();
    loadInitialData();
    var user = gs.read('user');
    dev.log(user.toString());

    // เริ่มต้น timer สำหรับ update เวลาทุก 30 วินาที
    _startTimer();
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

  Future<void> loadAllPosts() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final uid = gs.read('user'); // GetStorage: เก็บ uid ไว้ก่อน

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

          // ใส่ข้อมูล like count จาก post model
          likeCountMap[postId] = postItem.post.amountOfLike;

          // ใช้ likedSet จาก API เพื่อตรวจสอบว่าโพสต์นี้เคยถูกไลก์โดย user หรือยัง
          likedMap[postId] = likedSet.contains(postId);
        }

        // 4. สร้าง map สำหรับแสดงหัวใจ
        for (int i = 0; i < filteredPosts.length; i++) {
          showHeartMap[i] = false;
        }
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

  Widget _buildLoadingWidget() {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade800, Colors.grey.shade600],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
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
        body: _buildLoadingWidget(),
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

          // Enhanced Posts List
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final postItem = filteredPosts[index];
                      final pageController = PageController();

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Enhanced Header Section
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey[200]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                postItem.user.profileImage),
                                            radius: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                postItem.user.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatTimeAgo(
                                                    postItem.post.postDate),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black,
                                              Colors.grey[800]!
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          "ติดตาม",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert,
                                            color: Colors.grey[500], size: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'report',
                                            child: Row(
                                              children: [
                                                Icon(Icons.flag_outlined,
                                                    size: 16),
                                                SizedBox(width: 8),
                                                Text('รายงาน'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'block',
                                            child: Row(
                                              children: [
                                                Icon(Icons.block_outlined,
                                                    size: 16),
                                                SizedBox(width: 8),
                                                Text('บล็อก'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Enhanced Content Section
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (postItem.post.postTopic != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        postItem.post.postTopic!,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  if (postItem.post.postDescription != null &&
                                      postItem.post.postDescription!
                                          .trim()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        postItem.post.postDescription!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[800],
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  if (postItem.hashtags.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: postItem.hashtags.map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '#${tag.tagName}',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Enhanced Image Section
                            if (postItem.images.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          height: 400,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: PageView(
                                              controller: pageController,
                                              children:
                                                  postItem.images.map((img) {
                                                return GestureDetector(
                                                  onDoubleTap: () async {
                                                    likePost(
                                                        postItem.post.postId);
                                                    setState(() =>
                                                        showHeartMap[index] =
                                                            true);
                                                    await Future.delayed(
                                                        const Duration(
                                                            seconds: 1));
                                                    setState(() =>
                                                        showHeartMap[index] =
                                                            false);
                                                  },
                                                  child: Image.network(
                                                    img.image,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
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
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Container(
                                                        height: 400,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
                                                        child: Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                  Icons
                                                                      .error_outline,
                                                                  color: Colors
                                                                          .grey[
                                                                      400],
                                                                  size: 32),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'ไม่สามารถโหลดรูปภาพได้',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
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
                                          ),
                                        ),
                                        // Enhanced heart animation
                                        AnimatedScale(
                                          scale: showHeartMap[index] == true
                                              ? 1.0
                                              : 0.0,
                                          duration:
                                              const Duration(milliseconds: 200),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red
                                                      .withOpacity(0.3),
                                                  blurRadius: 16,
                                                  spreadRadius: 3,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Enhanced page indicator
                                    if (postItem.images.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: SmoothPageIndicator(
                                          controller: pageController,
                                          count: postItem.images.length,
                                          effect: ExpandingDotsEffect(
                                            activeDotColor: Colors.black,
                                            dotColor: Colors.grey[300]!,
                                            dotHeight: 6,
                                            dotWidth: 6,
                                            spacing: 4,
                                            expansionFactor: 2,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Enhanced Footer Section
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Enhanced Categories
                                  if (postItem.categories.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children:
                                              postItem.categories.map((cat) {
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                border: Border.all(
                                                    color: Colors.grey[300]!),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                cat.cname,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),

                                  // Enhanced Action Bar
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        // Like button
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: likedMap[postItem
                                                            .post.postId] ==
                                                        true
                                                    ? Colors.red[50]
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                onPressed: () => likePost(
                                                    postItem.post.postId),
                                                icon: Icon(
                                                  likedMap[postItem
                                                              .post.postId] ==
                                                          true
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: likedMap[postItem
                                                              .post.postId] ==
                                                          true
                                                      ? Colors.red
                                                      : Colors.grey[600],
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width:
                                                    4), // เว้นระยะระหว่างไอคอนกับตัวเลข
                                            Text(
                                              '${likeCountMap[postItem.post.postId] ?? 0}',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(width: 16),

                                        // ปุ่มคอมเมนต์ (ยังไม่ทำงาน)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              // TODO: handle comment tap
                                            },
                                            icon: Icon(
                                              Icons.comment_outlined,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '0', // ถ้ามีจำนวนคอมเมนต์ให้แทนที่ตรงนี้
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // ปุ่มบันทึก (ยังไม่ทำงาน)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              // TODO: handle save tap
                                            },
                                            icon: Icon(
                                              Icons.bookmark_border,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '0', // ถ้ามีจำนวนบันทึกให้แทนที่ตรงนี้
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
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
