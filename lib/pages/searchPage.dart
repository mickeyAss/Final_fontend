import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_user.dart';
import 'package:fontend_pro/pages/other_user_profile.dart';
import 'package:fontend_pro/models/get_post_hashtags.dart';
import 'package:fontend_pro/pages/search_post_hashtags.dart';
import 'package:fontend_pro/pages/user_detail_post.dart'; // เพิ่ม import สำหรับ UserDetailPostPage

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

  late int loggedInUid; // uid ของผู้ใช้ที่ล็อกอิน
  TextEditingController searchController = TextEditingController();
  String currentSearchQuery = '';
  bool isSearchingHashtag = false;

  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

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

  Future<List<GetPostHashtags>> loadHashtagsWithPosts() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response =
          await http.get(Uri.parse("$url/hashtags/hashtags-with-posts"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((e) => GetPostHashtags.fromJson(e)).toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load hashtags');
      }
    } catch (e) {
      log('Error loading hashtags: $e');
      rethrow;
    }
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

  void _clearSearch() {
    searchController.clear();
    setState(() {
      currentSearchQuery = '';
      isSearchingHashtag = false;
      filteredUsers = user;
      searchedHashtags.clear();
      _selectedHashtag = null;
      _selectedHashtagPosts.clear();
    });
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
                              suffixIcon: currentSearchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                            onChanged: (query) {
                              setState(() {
                                currentSearchQuery = query;
                                isSearchingHashtag = query.startsWith("#");
                                _selectedHashtag = null;
                                _selectedHashtagPosts.clear();
                              });

                              if (query.startsWith("#")) {
                                searchHashtags(query);
                              } else {
                                setState(() {
                                  filteredUsers = user
                                      .where((u) => (u.name ?? '')
                                          .toLowerCase()
                                          .contains(query.toLowerCase()))
                                      .toList();
                                });
                              }
                            },
                          ),
                        ),
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
                        // Show search results or selected hashtag content
                        if (isSearchingHashtag) ...[
                          if (_selectedHashtag != null) ...[
                            // Selected hashtag header
                            Row(
                              children: [
                                Text(
                                  '#${_selectedHashtag!.tagName}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${_selectedHashtagPosts.length} โพสต์)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Get.to(
                                      () => SearchPostHashtagsPage(
                                        tagId: _selectedHashtag!.tagId,
                                        tagName: _selectedHashtag!.tagName,
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "ดูทั้งหมด",
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Selected hashtag posts grid
                            if (_isLoadingSelectedHashtagPosts)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            else if (_selectedHashtagPosts.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.content_paste_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'ยังไม่มีโพสต์สำหรับแฮชแท็กนี้',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              _buildSelectedHashtagGrid(),
                          ] else ...[
                            // Hashtag search results
                            Row(
                              children: [
                                const Text(
                                  "ผลการค้นหา",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_isSearchingHashtags) ...[
                                  const SizedBox(width: 12),
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey,
                                    ),
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
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'ไม่พบผลการค้นหา',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ลองค้นหาด้วยคำอื่น',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...searchedHashtags
                                  .map((hashtag) => _buildHashtagItem(hashtag)),
                          ],
                        ] else if (currentSearchQuery.isNotEmpty) ...[
                          // User search results
                          const Text(
                            "ผลการค้นหาผู้ใช้",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (filteredUsers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_search,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'ไม่พบผู้ใช้',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
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
                                    title: Text(
                                      user.name ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onTap: () {
                                      Get.to(
                                        () => OtherUserProfilePage(
                                            userId: user.uid),
                                      );
                                    },
                                  ),
                                )),
                        ] else ...[
                          // Default content - Suggestions and Popular hashtags
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "แนะนำ",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to see all suggestions
                                },
                                child: const Text(
                                  "ดูทั้งหมด",
                                  style: TextStyle(color: Colors.blue),
                                ),
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
}
