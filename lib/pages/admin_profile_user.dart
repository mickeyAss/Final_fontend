import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_user_uid.dart';
import 'package:fontend_pro/pages/admin_detailpost.dart';
import 'package:fontend_pro/pages/user_detail_post.dart';
import 'package:fontend_pro/models/get_post_user.dart' as model;

class AdminprofileUserPage extends StatefulWidget {
  final int userId; // รับ userId ของคนที่จะดู profile

  const AdminprofileUserPage({
    super.key,
    required this.userId,
  });

  @override
  State<AdminprofileUserPage> createState() => _AdminprofileUserPageState();
}

class _AdminprofileUserPageState extends State<AdminprofileUserPage> {
  GetUserUid? user;
  final GetStorage gs = GetStorage();

  List<model.GetPostUser>? userPosts;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;

  int followersCount = 0;
  int followingCount = 0;
  int postsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      loadDataUser(),
      loadUserPosts(),
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
              Get.to(() => AdminDetailPost(postId: postId));
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