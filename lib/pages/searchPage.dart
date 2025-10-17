import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fontend_pro/pages/mainPage.dart';
import 'package:fontend_pro/models/get_all_user.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fontend_pro/pages/user_detail_post.dart';
import 'package:fontend_pro/pages/other_user_profile.dart';
import 'package:fontend_pro/models/get_post_hashtags.dart';
import 'package:fontend_pro/pages/search_post_hashtags.dart';
import 'package:photo_manager/photo_manager.dart'; // เพิ่ม import สำหรับ UserDetailPostPage

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  List<GetAllUser> user = []; // users ทั้งหมด
  List<GetAllUser> filteredUsers = []; // users ที่กรองจากการ search
  final GetStorage gs = GetStorage();

  List<GetPostHashtags> hashtagsWithPosts = []; // hashtags ยอดนิยมพร้อมโพสต์
  List<GetPostHashtags> searchedHashtags = []; // hashtags ที่ค้นหาเจอ
  bool _isLoadingHashtags = true;
  bool _isSearchingHashtags = false;

  GetPostHashtags? _selectedHashtag; // hashtag ที่เลือก
  List<dynamic> _selectedHashtagPosts = []; // โพสต์ของ hashtag ที่เลือก
  bool _isLoadingSelectedHashtagPosts = false;

  // เพิ่มตัวแปรสำหรับการค้นหาเนื้อหาโพสต์
  List<dynamic> contentSearchResults = [];
  bool _isSearchingContent = false;

  // เพิ่มตัวแปรสำหรับการค้นหาด้วยรูปภาพ
  List<dynamic> imageSearchResults = [];
  bool _isSearchingByImage = false;
  String _imageSearchLabels = '';

  late int loggedInUid; // uid ของผู้ใช้ที่ล็อกอิน
  TextEditingController searchController = TextEditingController();
  String currentSearchQuery = '';
  bool isSearchingHashtag = false;

  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  List<dynamic> categorySearchResults = [];
  bool _isSearchingCategory = false;
  List<dynamic> matchedCategories = [];

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeData();
    _initializeHashtags();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await loadDataUser(loggedInUid);
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _initializeUser() {
    dynamic rawUid = gs.read('user');
    if (rawUid is int) {
      loggedInUid = rawUid;
    } else if (rawUid is String) {
      loggedInUid = int.tryParse(rawUid) ?? 0;
    } else {
      loggedInUid = 0;
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      await loadDataUser(loggedInUid);
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
    _initializeHashtags();
  }

  Future<void> loadDataUser(int loggedInUid) async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response =
          await http.get(Uri.parse("$url/user/users-except?uid=$loggedInUid"));

      if (response.statusCode == 200) {
        final newUsers = getAllUserFromJson(response.body);
        setState(() {
          user = newUsers;
          filteredUsers = newUsers;
          _errorMessage = null;
        });
        log('Users loaded successfully: ${newUsers.length} users');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load users');
      }
    } catch (e) {
      log('Error loading user data: $e');
      throw e;
    }
  }

  Future<void> searchHashtags(String query) async {
    if (query.trim().isEmpty || !query.startsWith('#')) return;

    setState(() {
      _isSearchingHashtags = true;
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final cleanQuery = query.substring(1); // Remove # from query
      final response =
          await http.get(Uri.parse("$url/hashtags/search?q=$cleanQuery"));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        setState(() {
          searchedHashtags = (body['data'] as List)
              .map((e) => GetPostHashtags.fromJson(e))
              .toList();
        });
      } else {
        log("Hashtag search failed: ${response.statusCode}");
      }
    } catch (e) {
      log("Error searching hashtags: $e");
    } finally {
      setState(() {
        _isSearchingHashtags = false;
      });
    }
  }

  Future<void> _loadSelectedHashtagPosts(int tagId) async {
    setState(() {
      _isLoadingSelectedHashtagPosts = true;
    });

    try {
      final config = await Configuration.getConfig();
      final url = config['apiEndpoint'];

      final response = await http.get(
        Uri.parse("$url/hashtags/hashtag-posts?tag_id=$tagId"),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _selectedHashtagPosts = body['posts'];
        });
      } else {
        log("Failed to load hashtag posts: ${response.statusCode}");
      }
    } catch (e) {
      log("Error loading hashtag posts: $e");
    } finally {
      setState(() {
        _isLoadingSelectedHashtagPosts = false;
      });
    }
  }

  Future<List<GetPostHashtags>> loadHashtagsWithPosts({int topN = 10}) async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response =
          await http.get(Uri.parse("$url/hashtags/hashtags-with-posts"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        // แปลงเป็นโมเดล
        final allHashtags =
            jsonData.map((e) => GetPostHashtags.fromJson(e)).toList();

        // เรียงตาม usageCount ลดหลั่น
        allHashtags.sort((a, b) => b.usageCount.compareTo(a.usageCount));

        // เอา Top N
        return allHashtags.take(topN).toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load hashtags');
      }
    } catch (e) {
      log('Error loading hashtags: $e');
      rethrow;
    }
  }

  // ฟังก์ชันค้นหาเนื้อหาโพสต์
  Future<void> searchPostContent(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearchingContent = true;
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      // ค้นหาทั้ง post content และ analysis text แบบ parallel
      final futures = await Future.wait([
        // ค้นหา post content เดิม
        http.get(
          Uri.parse(
              "$url/hashtags/search-posts?q=${Uri.encodeQueryComponent(query)}"),
        ),
        // ค้นหา analysis text
        http.get(
          Uri.parse(
              "$url/hashtags/analysis-posts?q=${Uri.encodeQueryComponent(query)}"),
        ),
      ]);

      final postContentResponse = futures[0];
      final analysisTextResponse = futures[1];

      List<dynamic> allResults = [];

      // รวมผลลัพธ์จาก post content
      if (postContentResponse.statusCode == 200) {
        final postBody = jsonDecode(postContentResponse.body);
        allResults.addAll(postBody['posts'] ?? []);
      }

      // รวมผลลัพธ์จาก analysis text (หลีกเลี่ยงการซ้ำ)
      if (analysisTextResponse.statusCode == 200) {
        final analysisBody = jsonDecode(analysisTextResponse.body);
        final analysisPosts = analysisBody['posts'] ?? [];

        // กรองโพสต์ที่ซ้ำ (ตาม post_id)
        final existingPostIds =
            allResults.map((post) => post['post_id']).toSet();
        final uniqueAnalysisPosts = analysisPosts
            .where((post) => !existingPostIds.contains(post['post_id']))
            .toList();

        allResults.addAll(uniqueAnalysisPosts);
      }

      setState(() {
        contentSearchResults = allResults;
      });
    } catch (e) {
      log("Error searching content: $e");
      setState(() {
        contentSearchResults = [];
      });
    } finally {
      setState(() {
        _isSearchingContent = false;
      });
    }
  }

// ฟังก์ชันสร้าง Widget สำหรับแสดงผลการค้นหาเนื้อหา
  Widget _buildContentSearchResult(dynamic post) {
    final images = post['images'] as List<dynamic>;
    final hasImages = images.isNotEmpty;
    final mainImage = hasImages ? images[0] : null;

    // Check if this post has analysis data
    final analysis = post['analysis'] as List<dynamic>?;
    final hasAnalysis = analysis?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final postId = post['post_id'];
          if (postId != null) {
            Get.to(() => UserDetailPostPage(postId: postId));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        post['user']?['profile_image']?.isNotEmpty == true
                            ? NetworkImage(post['user']['profile_image'])
                            : null,
                    child: post['user']?['profile_image']?.isEmpty != false
                        ? Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['user']?['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (post['post_date'] != null)
                          Text(
                            _formatDate(post['post_date']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Show AI analysis indicator if available
                  if (hasAnalysis)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy,
                            size: 12,
                            color: Colors.purple[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Post content
            if (post['post_topic']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  post['post_topic'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

            if (post['post_description']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  post['post_description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Show analysis text preview if available
            if (hasAnalysis)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 14,
                            color: Colors.purple[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI Analysis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analysis!.first['analysis_text'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

            // Hashtags
            if (post['hashtags'] != null &&
                (post['hashtags'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (post['hashtags'] as List).map<Widget>((hashtag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${hashtag['tag_name']}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Images
            if (hasImages)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          mainImage,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child:
                                  Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.collections,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeHashtags() async {
    try {
      final data = await loadHashtagsWithPosts();
      setState(() {
        hashtagsWithPosts = data;
        _isLoadingHashtags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHashtags = false;
      });
    }
  }

  Future<void> searchPostByCategory(String categoryName) async {
    if (categoryName.trim().isEmpty) return;

    setState(() {
      _isSearchingCategory = true;
      categorySearchResults.clear();
      matchedCategories.clear();
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.get(
        Uri.parse(
            "$url/category/search-by-category?cname=${Uri.encodeQueryComponent(categoryName)}"),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        setState(() {
          matchedCategories = body['matched_categories'] ?? [];
          categorySearchResults = body['posts'] ?? [];
        });

        log("พบโพสต์จาก category: ${categorySearchResults.length} โพสต์");
      } else if (response.statusCode == 404) {
        log("ไม่พบหมวดหมู่หรือโพสต์");
        setState(() {
          categorySearchResults = [];
          matchedCategories = [];
        });
      } else {
        log("Category search failed: ${response.statusCode}");
      }
    } catch (e) {
      log("Error searching by category: $e");
      setState(() {
        categorySearchResults = [];
        matchedCategories = [];
      });
    } finally {
      setState(() {
        _isSearchingCategory = false;
      });
    }
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {
      currentSearchQuery = '';
      isSearchingHashtag = false;
      filteredUsers = user;
      searchedHashtags.clear();
      contentSearchResults.clear();
      imageSearchResults.clear();
      categorySearchResults.clear();
      matchedCategories.clear();
      _imageSearchLabels = '';
      _selectedHashtag = null;
      _selectedHashtagPosts.clear();
      _isSearchingByImage = false;
      _isSearchingCategory = false;
    });
  }

// 4. เพิ่มฟังก์ชันสำหรับสร้าง Widget แสดงผลการค้นหา category
  Widget _buildCategorySearchHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.deepOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category,
                  size: 20,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'หมวดหมู่ที่พบ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange[700],
                      ),
                    ),
                    Text(
                      '${matchedCategories.length} หมวดหมู่ • ${categorySearchResults.length} โพสต์',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (matchedCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matchedCategories.map<Widget>((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.2),
                        Colors.deepOrange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (category['cimage'] != null &&
                          category['cimage'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            category['cimage'],
                            width: 16,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.category,
                                    size: 16, color: Colors.orange),
                          ),
                        )
                      else
                        const Icon(Icons.category,
                            size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        category['cname'] ?? '',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySearchResult(dynamic post) {
    final images = post['images'] as List<dynamic>;
    final hasImages = images.isNotEmpty;
    final mainImage = hasImages ? images[0] : null;
    final category = post['category'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          final postId = post['post_id'];
          if (postId != null) {
            Get.to(() => UserDetailPostPage(postId: postId));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        post['user']?['profile_image']?.isNotEmpty == true
                            ? NetworkImage(post['user']['profile_image'])
                            : null,
                    child: post['user']?['profile_image']?.isEmpty != false
                        ? Icon(Icons.person, size: 18, color: Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['user']?['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        if (post['post_date'] != null)
                          Text(
                            _formatDate(post['post_date']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.8),
                          Colors.deepOrange.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          category['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post['post_topic']?.isNotEmpty == true) ...[
                    Text(
                      post['post_topic'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (post['post_description']?.isNotEmpty == true) ...[
                    Text(
                      post['post_description'],
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Category info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (category['image'] != null &&
                            category['image'].toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              category['image'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.category,
                                    color: Colors.orange),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.category,
                                color: Colors.orange),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                              if (category['description'] != null)
                                Text(
                                  category['description'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Images
                  if (hasImages) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              mainImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                          if (images.length > 1)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.collections,
                                        color: Colors.white, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${images.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectHashtag(GetPostHashtags hashtag) {
    setState(() {
      _selectedHashtag = hashtag;
      currentSearchQuery = '#${hashtag.tagName}';
      isSearchingHashtag = true;
      searchedHashtags.clear();
    });

    searchController.text = '#${hashtag.tagName}';
    _loadSelectedHashtagPosts(hashtag.tagId);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} วันที่แล้ว';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ชม.';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} นาที';
      } else {
        return 'เมื่อสักครู่';
      }
    } catch (e) {
      return dateString;
    }
  }

  double _getRandomHeight() {
    return 200 + math.Random().nextDouble() * 100;
  }

  Widget _buildHashtagItem(GetPostHashtags hashtag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectHashtag(hashtag),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(
                  Icons.tag,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${hashtag.tagName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedHashtagPost(dynamic post, double itemHeight) {
    final images = post['images'] as List<dynamic>;
    final hasImages = images.isNotEmpty;
    final mainImage = hasImages ? images[0] : null;

    return Container(
      height: itemHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // นำทางไปหน้า UserDetailPostPage แทนการแสดง popup
          final postId = post['post_id'];
          if (postId != null) {
            Get.to(() => UserDetailPostPage(postId: postId));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main image section
            if (hasImages)
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        mainImage,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.collections,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.article,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),

            // Content section
            Expanded(
              flex: hasImages ? 2 : 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post['post_topic'] != null) ...[
                      Text(
                        post['post_topic'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (post['post_description'] != null) ...[
                      Expanded(
                        child: Text(
                          post['post_description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: hasImages ? 3 : 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else
                      const Spacer(),

                    // User info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: post['user'] != null &&
                                  post['user']['profile_image']?.isNotEmpty ==
                                      true
                              ? NetworkImage(post['user']['profile_image']!)
                              : null,
                          child: post['user'] == null ||
                                  post['user']['profile_image'] == null ||
                                  post['user']['profile_image']
                                      .toString()
                                      .isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Colors.grey[600],
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['user']['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (post['post_date'] != null)
                                Text(
                                  _formatDate(post['post_date']),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedHashtagGrid() {
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = _selectedHashtagPosts[index];
              final itemHeight = _getRandomHeight();
              return _buildSelectedHashtagPost(post, itemHeight);
            },
            childCount: _selectedHashtagPosts.length,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularHashtagGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: hashtagsWithPosts.length,
      itemBuilder: (context, index) {
        final hashtag = hashtagsWithPosts[index];
        final imageUrl =
            hashtag.posts.isNotEmpty && hashtag.posts[0].images.isNotEmpty
                ? hashtag.posts[0].images[0]
                : '';

        return InkWell(
          onTap: () => _selectHashtag(hashtag),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: Stack(
              children: [
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.tag,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.tag,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${hashtag.tagName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${hashtag.posts.length} โพสต์',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> searchImageByLabel(File imageFile) async {
    setState(() {
      _isSearchingByImage = true;
      imageSearchResults.clear();
      _imageSearchLabels = '';
      contentSearchResults.clear();
      categorySearchResults.clear();
      searchedHashtags.clear();
      _selectedHashtag = null;
      _selectedHashtagPosts.clear();
      isSearchingHashtag = false;
      currentSearchQuery = "";
      filteredUsers = user;
    });

    try {
      // 1️⃣ แปลงรูปเป็น Base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      log("Image converted to Base64, size: ${bytes.length} bytes");

      // 2️⃣ เรียก Vision API
      final apiKey = "AIzaSyBpz8mdC1PePyf5cb1BP7jS53a2x7jT-e0";
      final visionUrl =
          "https://vision.googleapis.com/v1/images:annotate?key=$apiKey";
      final translateUrl =
          "https://translation.googleapis.com/language/translate/v2?key=$apiKey";

      final visionBody = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 10}
            ]
          }
        ]
      });

      final visionResponse = await http.post(
        Uri.parse(visionUrl),
        headers: {"Content-Type": "application/json"},
        body: visionBody,
      );

      if (visionResponse.statusCode != 200) {
        log("Vision API error: ${visionResponse.statusCode}");
        setState(() {
          _isSearchingByImage = false;
          _imageSearchLabels = 'เกิดข้อผิดพลาดในการวิเคราะห์รูปภาพ';
        });
        return;
      }

      final data = jsonDecode(visionResponse.body);
      final labelAnnotations = data['responses'][0]['labelAnnotations'];

      if (labelAnnotations == null || labelAnnotations.isEmpty) {
        log("ไม่พบ label ในรูปภาพ");
        setState(() {
          _isSearchingByImage = false;
          _imageSearchLabels = 'ไม่สามารถตรวจจับเนื้อหาในรูปภาพได้';
        });
        return;
      }

      // แปลงเป็น List<String
      final labelsEn = labelAnnotations
          .map<String>((l) => l['description'].toString())
          .toList();
      log("Detected labels (EN): $labelsEn");

      // 3️⃣ แปล labels เป็นไทย
      final descriptionText = labelsEn.join(", ");
      final translateBody =
          jsonEncode({"q": descriptionText, "target": "th", "format": "text"});

      final translateResponse = await http.post(
        Uri.parse(translateUrl),
        headers: {"Content-Type": "application/json"},
        body: translateBody,
      );

      List<String> labelsTH = labelsEn; // fallback เป็นอังกฤษ
      String translatedText = descriptionText;

      if (translateResponse.statusCode == 200) {
        final translateData = jsonDecode(translateResponse.body);
        translatedText =
            translateData['data']['translations'][0]['translatedText'];
        log("Translated text: $translatedText");

        labelsTH = translatedText
            .split(RegExp(r",\s*"))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        log("Labels (TH, array): $labelsTH");
      }

      setState(() {
        _imageSearchLabels = translatedText;
      });

      // 4️⃣ ส่ง labelsTH ไป backend
      final config = await Configuration.getConfig();
      final url = config['apiEndpoint'];

      log("Sending labels to backend: $labelsTH");

      final response = await http.post(
        Uri.parse("$url/image_post/searchByImageLabels"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"labels": labelsTH}), // ✅ ส่งเป็น array ของ String
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          imageSearchResults = List<Map<String, dynamic>>.from(data['posts']);
          _isSearchingByImage = false;
        });
        log("Found ${imageSearchResults.length} posts from label search");
      } else {
        log("Post search failed: ${response.body}");
        setState(() {
          _isSearchingByImage = false;
          _imageSearchLabels = "ไม่พบโพสต์ที่ตรงกับรูปภาพ";
        });
      }
    } catch (e, stackTrace) {
      log("Error analyzing image: $e", stackTrace: stackTrace);
      setState(() {
        _isSearchingByImage = false;
        _imageSearchLabels = 'เกิดข้อผิดพลาด: ${e.toString()}';
      });
    }
  }

  Widget _buildProgressStep(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? Colors.purple : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.purple[600] : Colors.grey[500],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSearchResult(dynamic post) {
    final userName = post['name'] ?? 'Unknown';
    final userProfile = post['profile_image'];

    // ใช้ image_url จาก backend สำหรับรูปแรก
    final mainImage = post['image_url'];

    // ดึงข้อมูลวิเคราะห์ AI
    final analysisText = post['analysis_text'] ?? '';
    final hasAnalysis = analysisText.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          final postId = post['post_id'];
          if (postId != null) {
            Get.to(() => UserDetailPostPage(postId: postId));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header user info
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        userProfile != null && userProfile.isNotEmpty
                            ? NetworkImage(userProfile)
                            : null,
                    child: userProfile == null || userProfile.isEmpty
                        ? Icon(Icons.person, size: 18, color: Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            // Post content
            if (post['post_topic']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  post['post_topic'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            if (post['post_description']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(post['post_description']),
              ),
               // แสดง AI Analysis
            if (hasAnalysis)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.05),
                        Colors.deepPurple.withOpacity(0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.psychology,
                                size: 16, color: Colors.purple[700]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Analysis - ตรงกับรูปภาพที่ค้นหา',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        analysisText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

            // แสดงรูปแรกจาก image_url
            if (mainImage != null && mainImage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    mainImage,
                    height: 180, // ความสูงเล็ก
                    fit: BoxFit.cover, // ความกว้างเต็มคอนเทนเนอร์
                    width: double.infinity, // ทำให้เต็มความกว้าง
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[100],
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 32, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),

           
          ],
        ),
      ),
    );
  }

  Widget _buildImageSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_search,
                  size: 18, color: Colors.purple),
            ),
            const SizedBox(width: 8),
            const Text(
              "ค้นหาด้วยรูปภาพ",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple),
            ),
            if (_isSearchingByImage) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.purple),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Labels
        if (_imageSearchLabels.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.1),
                  Colors.deepPurple.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 20, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'AI ตรวจจับเนื้อหาในรูปภาพ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: Text(
                    _imageSearchLabels,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[800], height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Loading state
        if (_isSearchingByImage) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.05),
                  Colors.deepPurple.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    color: Colors.purple[600],
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'กำลังค้นหาโพสต์ที่เกี่ยวข้อง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Results
        if (!_isSearchingByImage && imageSearchResults.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.teal.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle,
                      size: 20, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พบโพสต์ที่ตรงกัน ${imageSearchResults.length} โพสต์',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'จากการวิเคราะห์เนื้อหาในรูปภาพ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...imageSearchResults.map((post) => _buildImageSearchResult(post)),
        ],

        // No results
        if (!_isSearchingByImage &&
            _imageSearchLabels.isNotEmpty &&
            imageSearchResults.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.image_not_supported,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบโพสต์ที่ตรงกับรูปภาพ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'คำค้นหา: $_imageSearchLabels',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'ลองเลือกรูปภาพอื่นหรือค้นหาด้วยคำอื่น',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                // Search header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'ค้นหาเพื่อนหรือ #hashtag',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (currentSearchQuery.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          onPressed: _clearSearch,
                                        ),
                                      // ปุ่มค้นหารูปภาพที่มีการแสดงสถานะ
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: IconButton(
                                          icon: Stack(
                                            children: [
                                              Icon(
                                                Icons.image,
                                                color: _isSearchingByImage
                                                    ? Colors.purple
                                                    : Colors.grey,
                                                size: 22,
                                              ),
                                              if (_isSearchingByImage)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.purple,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          onPressed: _pickImageForSearch,
                                        ),
                                      ),
                                    ],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                                onChanged: (query) {
                                  // ถ้ากำลังค้นหาด้วยรูปภาพ ไม่ให้ทำอะไร
                                  if (_isSearchingByImage ||
                                      imageSearchResults.isNotEmpty) {
                                    return;
                                  }

                                  setState(() {
                                    currentSearchQuery = query;
                                    isSearchingHashtag = query.startsWith("#");
                                    _selectedHashtag = null;
                                    _selectedHashtagPosts.clear();
                                    imageSearchResults
                                        .clear(); // ล้างผลค้นหารูปภาพ
                                    _imageSearchLabels = ''; // ล้าง labels
                                  });

                                  if (query.startsWith("#")) {
                                    searchHashtags(query);
                                    setState(() {
                                      contentSearchResults.clear();
                                      categorySearchResults.clear();
                                    });
                                  } else if (query.isNotEmpty) {
                                    setState(() {
                                      filteredUsers = user
                                          .where((u) => (u.name ?? '')
                                              .toLowerCase()
                                              .contains(query.toLowerCase()))
                                          .toList();
                                    });
                                    searchPostContent(query);
                                    searchPostByCategory(query);
                                  } else {
                                    setState(() {
                                      filteredUsers = user;
                                      contentSearchResults.clear();
                                      categorySearchResults.clear();
                                    });
                                  }
                                })),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // เช็คการแสดงผลการค้นหารูปภาพก่อน
                        if (_isSearchingByImage ||
                            imageSearchResults.isNotEmpty ||
                            _imageSearchLabels.isNotEmpty) ...[
                          _buildImageSearchSection(),
                        ]
                        // 1. แสดง Hashtag search ก่อน (ถ้าเป็นการค้นหา hashtag)
                        else if (isSearchingHashtag) ...[
                          if (_selectedHashtag != null) ...[
                            // Selected hashtag content
                            Row(
                              children: [
                                Text('#${_selectedHashtag!.tagName}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Text('(${_selectedHashtagPosts.length} โพสต์)',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[600])),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Get.to(() => SearchPostHashtagsPage(
                                          tagId: _selectedHashtag!.tagId,
                                          tagName: _selectedHashtag!.tagName,
                                        ));
                                  },
                                  child: const Text("ดูทั้งหมด",
                                      style: TextStyle(color: Colors.blue)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isLoadingSelectedHashtagPosts)
                              const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                    color: Colors.black),
                              ))
                            else if (_selectedHashtagPosts.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.content_paste_off,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text('ยังไม่มีโพสต์สำหรับแฮชแท็กนี้',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )
                            else
                              _buildSelectedHashtagGrid(),
                          ] else ...[
                            // Hashtag search results
                            Row(
                              children: [
                                const Text("ผลการค้นหา",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                if (_isSearchingHashtags) ...[
                                  const SizedBox(width: 12),
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (searchedHashtags.isEmpty &&
                                !_isSearchingHashtags)
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text('ไม่พบผลการค้นหา',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text('ลองค้นหาด้วยคำอื่น',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500])),
                                  ],
                                ),
                              )
                            else
                              ...searchedHashtags
                                  .map((hashtag) => _buildHashtagItem(hashtag)),
                          ],
                        ]

                        // 2. แสดงผลการค้นหาทั่วไป (ถ้าไม่ใช่ hashtag search)
                        else if (currentSearchQuery.isNotEmpty) ...[
                          // 2.1 แสดงผลผู้ใช้
                          if (filteredUsers.isNotEmpty) ...[
                            const Text("ผลการค้นหาผู้ใช้",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...filteredUsers.map((user) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 25,
                                      backgroundImage:
                                          user.profileImage?.isNotEmpty == true
                                              ? NetworkImage(user.profileImage!)
                                              : null,
                                      backgroundColor: Colors.grey[300],
                                      child: user.profileImage?.isEmpty != false
                                          ? const Icon(Icons.person,
                                              color: Colors.grey)
                                          : null,
                                    ),
                                    title: Text(user.name ?? 'Unknown',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    onTap: () => Get.to(() =>
                                        OtherUserProfilePage(userId: user.uid)),
                                  ),
                                )),
                            const SizedBox(height: 16),
                          ],

                          // 2.2 แสดงผลโพสต์จากการค้นหาเนื้อหา
                          if (contentSearchResults.isNotEmpty ||
                              _isSearchingContent) ...[
                            Row(
                              children: [
                                const Text("ผลการค้นหาโพสต์",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                if (_isSearchingContent) ...[
                                  const SizedBox(width: 12),
                                  const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.grey)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_isSearchingContent)
                              const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                    color: Colors.black),
                              ))
                            else if (contentSearchResults.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.content_paste_search,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text('ไม่พบโพสต์ที่ตรงกับคำค้นหา',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )
                            else
                              ...contentSearchResults.map(
                                  (post) => _buildContentSearchResult(post)),
                            const SizedBox(height: 16),
                          ],
                          if (categorySearchResults.isNotEmpty ||
                              _isSearchingCategory) ...[
                            Row(
                              children: [
                                const Icon(Icons.category,
                                    size: 20, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text(
                                  "ผลการค้นหาจากหมวดหมู่",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (_isSearchingCategory) ...[
                                  const SizedBox(width: 12),
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.orange),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_isSearchingCategory)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(
                                      color: Colors.orange),
                                ),
                              )
                            else if (categorySearchResults.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.category_outlined,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'ไม่พบโพสต์ในหมวดหมู่นี้',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              _buildCategorySearchHeader(),
                              ...categorySearchResults.map(
                                  (post) => _buildCategorySearchResult(post)),
                            ],
                            const SizedBox(height: 16),
                          ],

                          // 2.4 แสดงข้อความถ้าไม่พบผลการค้นหาใด ๆ เลย
                          if (filteredUsers.isEmpty &&
                              contentSearchResults.isEmpty &&
                              imageSearchResults.isEmpty &&
                              !_isSearchingContent &&
                              !_isSearchingByImage &&
                              _imageSearchLabels.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text('ไม่พบผลการค้นหา',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text('ลองค้นหาด้วยคำอื่น',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ),
                        ]

                        // 3. แสดงเนื้อหาเริ่มต้น (เมื่อไม่มีการค้นหา)
                        else ...[
                          // Default content - Suggestions and Popular hashtags
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("แนะนำ",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Mainpage(initialIndex: 3)));
                                },
                                child: const Text("ดูทั้งหมด",
                                    style: TextStyle(color: Colors.blue)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // User suggestions (horizontal scroll)
                          SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: user.length > 10 ? 10 : user.length,
                              itemBuilder: (context, index) {
                                final userItem = user[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: InkWell(
                                    onTap: () {
                                      Get.to(() => OtherUserProfilePage(
                                          userId: userItem.uid));
                                      // Navigate to user profile
                                      log('Navigate to suggested user: ${userItem.name}');
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 70,
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 35,
                                            backgroundImage: userItem
                                                        .profileImage
                                                        ?.isNotEmpty ==
                                                    true
                                                ? NetworkImage(
                                                    userItem.profileImage!)
                                                : null,
                                            backgroundColor: Colors.grey[300],
                                            child: userItem.profileImage
                                                        ?.isEmpty !=
                                                    false
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 32,
                                                    color: Colors.grey,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            userItem.name ?? 'Unknown',
                                            style:
                                                const TextStyle(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Popular hashtags section
                          const Text(
                            "แฮชแท็กยอดนิยม",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoadingHashtags
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                  ),
                                )
                              : _buildPopularHashtagGrid(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageForSearch() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await searchImageByLabel(File(pickedFile.path));
    }
  }
}
