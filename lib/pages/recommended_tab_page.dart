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

    final uri = Uri.parse('$url/image_post/like');

    // ✅ สร้าง model แล้วแปลงเป็น JSON
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
          likeCountMap[postId] = (likeCountMap[postId] ?? 0) + 1;
        } else {
          likeCountMap[postId] = (likeCountMap[postId] ?? 1) - 1;
        }
      });
    } else {
      dev.log("Like API failed: ${response.body}");
    }
  } catch (e) {
    dev.log("Error liking post: $e");
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
                                        Container(
                                          decoration: BoxDecoration(
                                            color: likedMap[
                                                        postItem.post.postId] ==
                                                    true
                                                ? Colors.red[50]
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            onPressed: () => likePost(postItem
                                                .post
                                                .postId), // เรียกฟังก์ชันกดไลก์
                                            icon: Icon(
                                              likedMap[postItem.post.postId] ==
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

                                        // จำนวนไลก์แสดงข้างๆ ไอคอน
                                        Text(
                                          '${likeCountMap[postItem.post.postId] ?? 0}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
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
    // return Scaffold(
    //   body: Padding(
    //     padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
    //     child: SingleChildScrollView(
    //         child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         SingleChildScrollView(
    //             scrollDirection: Axis.horizontal, // ให้เลื่อนแนวนอน
    //             child: FutureBuilder(
    //               future: loadData_Category,
    //               builder: (context, snapshot) {
    //                 if (snapshot.connectionState == ConnectionState.waiting) {
    //                   return const Center(child: CircularProgressIndicator());
    //                 } else if (snapshot.hasError) {
    //                   return const Center(
    //                       child: Text('Error loading Category data'));
    //                 }
      
    //                 return Row(
    //                   children: category.asMap().entries.map((entry) {
    //                     int index = entry.key;
    //                     var cate = entry.value;
      
    //                     bool isSelected = selectedIndex == index;
      
    //                     return Padding(
    //                       padding: const EdgeInsets.symmetric(horizontal: 4.0),
    //                       child: TextButton(
    //                         onPressed: () {
    //                           setState(() {
    //                             selectedIndex = index;
    //                           });
    //                         },
    //                         style: ButtonStyle(
    //                           padding: WidgetStateProperty.all(EdgeInsets.zero),
    //                           backgroundColor:
    //                               WidgetStateProperty.all(Colors.transparent),
    //                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    //                           overlayColor:
    //                               WidgetStateProperty.all(Colors.transparent),
    //                           foregroundColor: WidgetStateProperty.all(
    //                             isSelected ? Colors.black : Colors.black54,
    //                           ),
    //                         ),
    //                         child: Text(
    //                           cate.cname,
    //                           style: TextStyle(
    //                             fontWeight: isSelected
    //                                 ? FontWeight.bold
    //                                 : FontWeight.normal,
    //                           ),
    //                         ),
    //                       ),
    //                     );
    //                   }).toList(),
    //                 );
    //               },
    //             )),
    //         FutureBuilder<List<model.GetAllPost>?>(
    //           future: loadDataPost(),
    //           builder: (context, snapshot) {
    //             if (snapshot.connectionState == ConnectionState.waiting) {
    //               return Center(child: CircularProgressIndicator());
    //             } else if (snapshot.hasError) {
    //               return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
    //             } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
    //               return Center(child: Text('ไม่พบข้อมูล'));
    //             }
      
    //             final posts = snapshot.data!;
      
    //             return ListView.builder(
    //               shrinkWrap: true,
    //               physics: NeverScrollableScrollPhysics(),
    //               itemCount: posts.length,
    //               itemBuilder: (context, index) {
    //                 final post = posts[index];
    //                 final pageController = PageController();
      
    //                 return Padding(
    //                   padding: const EdgeInsets.all(10.0),
    //                   child: Column(
    //                     crossAxisAlignment: CrossAxisAlignment.start,
    //                     children: [
    //                       // Header: รูปโปรไฟล์ + ชื่อ + ปุ่มติดตาม + เมนู
    //                       Row(
    //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                         children: [
    //                           Row(
    //                             children: [
    //                               ClipOval(
    //                                 child: Image.network(
    //                                   post.user.profileImage ?? '',
    //                                   width: 40,
    //                                   height: 40,
    //                                   fit: BoxFit.cover,
    //                                   errorBuilder:
    //                                       (context, error, stackTrace) =>
    //                                           Image.asset(
    //                                     'assets/default_profile.png',
    //                                     width: 40,
    //                                     height: 40,
    //                                     fit: BoxFit.cover,
    //                                   ),
    //                                 ),
    //                               ),
    //                               SizedBox(width: 10),
    //                               Text(
    //                                 post.user.name,
    //                                 style: TextStyle(
    //                                     fontSize: 12,
    //                                     fontWeight: FontWeight.bold),
    //                               ),
    //                             ],
    //                           ),
    //                           Row(
    //                             children: [
    //                               FilledButton(
    //                                 style: FilledButton.styleFrom(
    //                                   backgroundColor: Colors.black,
    //                                   foregroundColor: Colors.white,
    //                                   padding: EdgeInsets.symmetric(
    //                                       horizontal: 12, vertical: 2),
    //                                   textStyle: TextStyle(
    //                                       fontSize: 12,
    //                                       fontWeight: FontWeight.bold),
    //                                   elevation: 10,
    //                                   shape: RoundedRectangleBorder(
    //                                     borderRadius: BorderRadius.circular(8),
    //                                   ),
    //                                   minimumSize: Size(0, 40),
    //                                   visualDensity: VisualDensity.compact,
    //                                 ),
    //                                 onPressed: () {},
    //                                 child: Text("ติดตาม"),
    //                               ),
    //                               PopupMenuButton<String>(
    //                                 icon: Icon(Icons.more_vert),
    //                                 onSelected: (value) {
    //                                   if (value == 'report') {
    //                                     // รายงาน
    //                                   } else if (value == 'block') {
    //                                     // บล็อก
    //                                   }
    //                                 },
    //                                 itemBuilder: (context) => [
    //                                   PopupMenuItem(
    //                                       value: 'report', child: Text('รายงาน')),
    //                                   PopupMenuItem(
    //                                       value: 'block', child: Text('บล็อก')),
    //                                 ],
    //                               ),
    //                             ],
    //                           ),
    //                         ],
    //                       ),
    //                       SizedBox(height: 10),
      
    //                       // รูปภาพแบบ PageView
    //                       if (post.images.isNotEmpty)
    //                         Center(
    //                           child: Container(
    //                             height: 450,
    //                             width: double.infinity,
    //                             child: PageView(
    //                               controller: pageController,
    //                               children: post.images.map((image) {
    //                                 return ClipRRect(
    //                                   borderRadius: BorderRadius.circular(20),
    //                                   child: Image.network(
    //                                     image.image,
    //                                     fit: BoxFit.cover,
    //                                   ),
    //                                 );
    //                               }).toList(),
    //                             ),
    //                           ),
    //                         ),
      
    //                       SizedBox(height: 10),
      
    //                       // SmoothPageIndicator
    //                       if (post.images.length > 1)
    //                         Center(
    //                           child: SmoothPageIndicator(
    //                             controller: pageController,
    //                             count: post.images.length,
    //                             effect: ExpandingDotsEffect(
    //                               dotWidth: 8,
    //                               dotHeight: 8,
    //                               spacing: 8,
    //                               expansionFactor: 4,
    //                               dotColor: Colors.black,
    //                               activeDotColor: Colors.black38,
    //                             ),
    //                           ),
    //                         ),
      
    //                       SizedBox(height: 10),
      
    //                       // แสดงปุ่ม category และไอคอนต่าง ๆ
    //                       Row(
    //                         crossAxisAlignment:
    //                             CrossAxisAlignment.start, // สำคัญ! ให้ชิดบน
    //                         children: [
    //                           // ฝั่งซ้าย: ปุ่ม category
    //                           Expanded(
    //                             flex: 1,
    //                             child: Wrap(
    //                               spacing: 4.0,
    //                               runSpacing: 4.0,
    //                               children: post.categories.map((category) {
    //                                 return OutlinedButton(
    //                                   style: OutlinedButton.styleFrom(
    //                                     backgroundColor: Colors.white,
    //                                     foregroundColor: Colors.black,
    //                                     padding: EdgeInsets.symmetric(
    //                                         horizontal: 20, vertical: 2),
    //                                     textStyle: TextStyle(fontSize: 12),
    //                                     elevation: 10,
    //                                     shape: RoundedRectangleBorder(
    //                                       borderRadius: BorderRadius.circular(20),
    //                                     ),
    //                                     minimumSize: Size(0, 40),
    //                                     visualDensity: VisualDensity.compact,
    //                                   ),
    //                                   onPressed: () {},
    //                                   child: Text(category.cname),
    //                                 );
    //                               }).toList(),
    //                             ),
    //                           ),
      
    //                           // ฝั่งขวา: ปุ่มไอคอนแนวนอน อยู่ชิดบน
    //                           Padding(
    //                             padding: const EdgeInsets.only(top: 5),
    //                             child: Row(
    //                               mainAxisSize: MainAxisSize.min,
    //                               children: [
    //                                 GestureDetector(
    //                                   onTap: () {},
    //                                   child: Row(
    //                                     children: [
    //                                       Icon(Icons.favorite_border),
    //                                       SizedBox(width: 4),
    //                                       Text("423"),
    //                                     ],
    //                                   ),
    //                                 ),
    //                                 SizedBox(width: 8),
    //                                 GestureDetector(
    //                                   onTap: () {
    //                                     showModalBottomSheet(
    //                                       context: context,
    //                                       isScrollControlled:
    //                                           true, // ทำให้ป๊อปอัพใหญ่ขึ้นได้
    //                                       shape: const RoundedRectangleBorder(
    //                                         borderRadius: BorderRadius.vertical(
    //                                             top: Radius.circular(16)),
    //                                       ),
    //                                       builder: (context) {
    //                                         return DraggableScrollableSheet(
    //                                           expand: false,
    //                                           initialChildSize:
    //                                               0.4, // ขนาดเริ่มต้น (40% ของหน้าจอ)
    //                                           minChildSize: 0.2,
    //                                           maxChildSize: 0.9,
    //                                           builder:
    //                                               (context, scrollController) {
    //                                             return Container(
    //                                               padding:
    //                                                   const EdgeInsets.all(16),
    //                                               child: ListView.builder(
    //                                                 controller: scrollController,
    //                                                 itemCount:
    //                                                     10, // ตัวอย่างคอมเมนต์ 10 รายการ
    //                                                 itemBuilder:
    //                                                     (context, index) {
    //                                                   return ListTile(
    //                                                     leading:
    //                                                         Icon(Icons.person),
    //                                                     title: Text(
    //                                                         "ความคิดเห็นที่ ${index + 1}"),
    //                                                     subtitle: Text(
    //                                                         "นี่คือข้อความความคิดเห็น..."),
    //                                                   );
    //                                                 },
    //                                               ),
    //                                             );
    //                                           },
    //                                         );
    //                                       },
    //                                     );
    //                                   },
    //                                   child: Row(
    //                                     children: [
    //                                       Image.asset('assets/images/chat.png',
    //                                           height: 20, width: 20),
    //                                       SizedBox(width: 3),
    //                                       Text("42"),
    //                                     ],
    //                                   ),
    //                                 ),
    //                                 SizedBox(width: 8),
    //                                 GestureDetector(
    //                                   onTap: () {},
    //                                   child: Row(
    //                                     children: [
    //                                       Icon(Icons.bookmark_outline_rounded),
    //                                       SizedBox(width: 4),
    //                                       Text("224"),
    //                                     ],
    //                                   ),
    //                                 ),
    //                               ],
    //                             ),
    //                           ),
    //                         ],
    //                       ),
      
    //                       // ข้อความเนื้อหาโพสต์
    //                       Padding(
    //                         padding: const EdgeInsets.only(left: 8, top: 8),
    //                         child: Column(
    //                           crossAxisAlignment: CrossAxisAlignment.start,
    //                           children: [
    //                             Text(post.post.postTopic,
    //                                 style:
    //                                     TextStyle(fontWeight: FontWeight.bold)),
    //                             if (post.post.postDescription != null)
    //                               Text(post.post.postDescription!),
    //                             Text("#ถ่ายรูปหน้ากระจก #ชุดเล่น",
    //                                 style: TextStyle(color: Colors.blue)),
    //                             SizedBox(height: 5),
    //                             Text(
    //                               "3 วันที่แล้ว",
    //                               style: TextStyle(
    //                                   color: Colors.black38, fontSize: 10),
    //                             ),
    //                           ],
    //                         ),
    //                       ),
      
    //                       Divider(thickness: 1),
    //                     ],
    //                   ),
    //                 );
    //               },
    //             );
    //           },
    //         ),
    //         // Column(
    //         //   crossAxisAlignment: CrossAxisAlignment.start,
    //         //   children: [
    //         //     Row(
    //         //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         //       children: [
    //         //         Row(
    //         //           children: [
    //         //             ClipOval(
    //         //               child: Image.asset(
    //         //                 'assets/images/pic2.jpg',
    //         //                 width: 40,
    //         //                 height: 40,
    //         //                 fit: BoxFit.cover,
    //         //               ),
    //         //             ),
    //         //             SizedBox(width: 10),
    //         //             Text(
    //         //               "apxd_lxz ",
    //         //               style: TextStyle(
    //         //                   fontSize: 12, fontWeight: FontWeight.bold),
    //         //             ),
    //         //           ],
    //         //         ),
    //         //         Row(
    //         //           children: [
    //         //             FilledButton(
    //         //               style: FilledButton.styleFrom(
    //         //                 backgroundColor: const Color.fromARGB(255, 0, 0, 0),
    //         //                 foregroundColor:
    //         //                     const Color.fromARGB(255, 255, 255, 255),
    //         //                 padding: const EdgeInsets.symmetric(
    //         //                     horizontal: 12,
    //         //                     vertical: 2), // ลด padding ด้านบน-ล่าง
    //         //                 textStyle: const TextStyle(
    //         //                   fontSize: 12,
    //         //                   fontWeight: FontWeight.bold,
    //         //                 ),
    //         //                 elevation: 10,
    //         //                 shape: RoundedRectangleBorder(
    //         //                   borderRadius: BorderRadius.circular(8),
    //         //                 ),
    //         //                 minimumSize:
    //         //                     const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
    //         //                 visualDensity: VisualDensity
    //         //                     .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
    //         //               ),
    //         //               onPressed: () {},
    //         //               child: const Text("ติดตาม"),
    //         //             ),
    //         //             PopupMenuButton<String>(
    //         //               icon: const Icon(Icons.more_vert),
    //         //               onSelected: (String result) {
    //         //                 // Handle เมื่อกดเลือกเมนู
    //         //                 if (result == 'report') {
    //         //                   // ดำเนินการรายงาน
    //         //                 } else if (result == 'block') {
    //         //                   // ดำเนินการบล็อก
    //         //                 }
    //         //               },
    //         //               itemBuilder: (BuildContext context) =>
    //         //                   <PopupMenuEntry<String>>[
    //         //                 const PopupMenuItem<String>(
    //         //                   value: 'report',
    //         //                   child: Text('รายงาน'),
    //         //                 ),
    //         //                 const PopupMenuItem<String>(
    //         //                   value: 'block',
    //         //                   child: Text('บล็อก'),
    //         //                 ),
    //         //               ],
    //         //             ),
    //         //           ],
    //         //         ),
    //         //       ],
    //         //     ),
    //         //     SizedBox(height: 10),
    //         //     Center(
    //         //       child: Container(
    //         //         height: 450, // กำหนดความสูงให้กับ PageView
    //         //         width: double.infinity, // กำหนดความกว้างเต็มหน้าจอ
    //         //         child: PageView(
    //         //           controller: pageController, // เชื่อมโยงกับ PageController
    //         //           children: [
    //         //             ClipRRect(
    //         //               borderRadius: BorderRadius.circular(20),
    //         //               child: Image.asset(
    //         //                 'assets/images/p1.jpg',
    //         //                 fit: BoxFit.cover,
    //         //               ),
    //         //             ),
    //         //             ClipRRect(
    //         //               borderRadius: BorderRadius.circular(20),
    //         //               child: Image.asset(
    //         //                 'assets/images/p2.jpg',
    //         //                 fit: BoxFit.cover,
    //         //               ),
    //         //             ),
    //         //             ClipRRect(
    //         //               borderRadius: BorderRadius.circular(20),
    //         //               child: Image.asset(
    //         //                 'assets/images/p3.jpg',
    //         //                 fit: BoxFit.cover,
    //         //               ),
    //         //             ),
    //         //           ],
    //         //         ),
    //         //       ),
    //         //     ),
    //         //     SizedBox(height: 10),
    //         //     // SmoothPageIndicator
    //         //     Center(
    //         //       child: SmoothPageIndicator(
    //         //         controller: pageController, // เชื่อมโยงกับ PageController
    //         //         count: 3, // จำนวนรูป
    //         //         effect: ExpandingDotsEffect(
    //         //           dotWidth: 8, // ขนาดจุด
    //         //           dotHeight: 8, // ความสูงของจุด
    //         //           spacing: 8, // ระยะห่างระหว่างจุด
    //         //           expansionFactor: 4, // ขนาดขยายจุดเมื่อถูกเลือก
    //         //           dotColor: const Color.fromARGB(
    //         //               255, 0, 0, 0), // สีของจุดที่ไม่ได้เลือก
    //         //           activeDotColor: Colors.black38, // สีของจุดที่เลือก
    //         //         ),
    //         //       ),
    //         //     ),
    //         //     SizedBox(height: 10),
    //         //     Row(
    //         //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         //       children: [
    //         //         Row(
    //         //           children: [
    //         //             OutlinedButton(
    //         //                 style: OutlinedButton.styleFrom(
    //         //                   backgroundColor:
    //         //                       const Color.fromARGB(255, 255, 255, 255),
    //         //                   foregroundColor: Colors.black,
    //         //                   padding: const EdgeInsets.symmetric(
    //         //                       horizontal: 20,
    //         //                       vertical: 2), // ลด padding ด้านบน-ล่าง
    //         //                   textStyle: const TextStyle(
    //         //                       fontSize: 12, color: Colors.black54),
    //         //                   elevation: 10,
    //         //                   shape: RoundedRectangleBorder(
    //         //                     borderRadius: BorderRadius.circular(20),
    //         //                   ),
    //         //                   minimumSize:
    //         //                       const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
    //         //                   visualDensity: VisualDensity
    //         //                       .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
    //         //                 ),
    //         //                 onPressed: () {},
    //         //                 child: const Text('สตรีท')),
    //         //             SizedBox(
    //         //               width: 8,
    //         //             ),
    //         //             OutlinedButton(
    //         //                 style: OutlinedButton.styleFrom(
    //         //                   backgroundColor:
    //         //                       const Color.fromARGB(255, 255, 255, 255),
    //         //                   foregroundColor: Colors.black,
    //         //                   padding: const EdgeInsets.symmetric(
    //         //                       horizontal: 20,
    //         //                       vertical: 2), // ลด padding ด้านบน-ล่าง
    //         //                   textStyle: const TextStyle(
    //         //                       fontSize: 12, color: Colors.black54),
    //         //                   elevation: 10,
    //         //                   shape: RoundedRectangleBorder(
    //         //                     borderRadius: BorderRadius.circular(20),
    //         //                   ),
    //         //                   minimumSize:
    //         //                       const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
    //         //                   visualDensity: VisualDensity
    //         //                       .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
    //         //                 ),
    //         //                 onPressed: () {},
    //         //                 child: const Text('chainese')),
    //         //           ],
    //         //         ),
    //         //         Row(
    //         //           children: [
    //         //             GestureDetector(
    //         //               onTap: () {
    //         //                 // ทำสิ่งที่ต้องการเมื่อไอคอนแรกถูกกด
    //         //               },
    //         //               child: Row(
    //         //                 children: [
    //         //                   Icon(Icons.favorite_border),
    //         //                   Text("423"),
    //         //                 ],
    //         //               ),
    //         //             ),
    //         //             SizedBox(width: 5),
    //         //             GestureDetector(
    //         //               onTap: () {
    //         //                 // ทำสิ่งที่ต้องการเมื่อไอคอนที่สองถูกกด
    //         //               },
    //         //               child: Row(
    //         //                 children: [
    //         //                   Image.asset(
    //         //                     'assets/images/chat.png',
    //         //                     height: 20,
    //         //                     width: 20,
    //         //                   ),
    //         //                   SizedBox(width: 3),
    //         //                   Text("42"),
    //         //                 ],
    //         //               ),
    //         //             ),
    //         //             SizedBox(width: 5),
    //         //             GestureDetector(
    //         //               onTap: () {
    //         //                 // ทำสิ่งที่ต้องการเมื่อไอคอนที่สามถูกกด
    //         //               },
    //         //               child: Row(
    //         //                 children: [
    //         //                   Icon(Icons.bookmark_outline_rounded),
    //         //                   Text("224"),
    //         //                 ],
    //         //               ),
    //         //             ),
    //         //           ],
    //         //         )
    //         //       ],
    //         //     ),
      
    //         //     Padding(
    //         //       padding: const EdgeInsets.only(left: 8),
    //         //       child: Column(
    //         //         crossAxisAlignment: CrossAxisAlignment.start,
    //         //         children: [
    //         //           Text(
    //         //             "แต่งตัวชิลๆ",
    //         //             style: TextStyle(fontWeight: FontWeight.bold),
    //         //           ),
    //         //           Text("ไอเดียแต่งตัวถ่ายรูปหน้ากระจกสวยๆจ้าา"),
    //         //           Text(
    //         //             "#ถ่ายรูปหน้ากระจก #ชุดเล่น",
    //         //             style: TextStyle(color: Colors.blue),
    //         //           ),
    //         //           SizedBox(
    //         //             height: 5,
    //         //           ),
    //         //           Text(
    //         //             "3 วันที่แล้ว",
    //         //             style: TextStyle(color: Colors.black38, fontSize: 10),
    //         //           ),
    //         //         ],
    //         //       ),
    //         //     ),
    //         //   ],
    //         // ),
    //       ],
    //     )),
    //   ),
    // );
  }

  Future<void> loadDataCategory() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final response = await http.get(Uri.parse("$url/category/get"));
    if (response.statusCode == 200) {
      category = getAllCategoryFromJson(response.body);
      dev.log(response.body);
      setState(() {});
    } else {
      dev.log('Error loading user data: ${response.statusCode}');
    }
  }

  Future<List<model.GetAllPost>?> loadDataPost() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.get(Uri.parse("$url/image_post/get"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final posts =
            jsonData.map((item) => model.GetAllPost.fromJson(item)).toList();

        dev.log('Received post data: ${posts.length}');
        return posts;
      } else {
        dev.log('Error loading post data: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('Exception during post loading: $e');
    }
    return null;
  }
}
