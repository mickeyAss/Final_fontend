import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fontend_pro/pages/edit_profile.dart';
import 'package:fontend_pro/models/get_user_uid.dart';
import 'package:fontend_pro/pages/user_detail_post.dart';
import 'package:fontend_pro/pages/user_my_likes_tab.dart';
import 'package:fontend_pro/models/get_post_user.dart' as model;
import 'package:fontend_pro/models/get_post_like.dart' as modelp;

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  int selectedIndex = 0;
  GetUserUid? user;
  final GetStorage gs = GetStorage();
  
  // เก็บข้อมูลไว้ใน state แทนการใช้ Future
  List<model.GetPostUser>? userPosts;
  List<modelp.GetPostLike>? likedPosts;
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

  // โหลดข้อมูลครั้งแรกเมื่อเข้าหน้า
  Future<void> _initializeData() async {
    await Future.wait([
      loadDataUser(),
      loadUserPosts(),
      _loadLikedPosts(),
    ]);
    
    setState(() {
      _isInitialLoading = false;
    });
  }

  Future<void> loadDataUser() async {
    try {
      final uid = gs.read('user');
      log("กำลังโหลดข้อมูลของ UID: $uid");

      if (uid == null) {
        throw Exception('ไม่พบ UID ใน GetStorage');
      }

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

  // เรียกเมื่อผู้ใช้ pull-to-refresh เท่านั้น
  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.wait([
        loadDataUser(),
        loadUserPosts(),
        _loadLikedPosts(),
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
      final uid = gs.read('user');
      log('UID ที่โหลดข้อมูล: $uid');
      if (uid == null) {
        throw Exception("ไม่พบ UID");
      }

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

  Future<void> _loadLikedPosts() async {
    try {
      final userId = gs.read('user');
      if (userId == null) return;

      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final uri = Uri.parse('$url/image_post/liked-posts/full/$userId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          likedPosts = modelp.getPostLikeFromJson(response.body);
        });
      } else {
        setState(() {
          likedPosts = [];
        });
        throw Exception('Failed to load liked posts');
      }
    } catch (e) {
      log('Error loading liked posts: $e');
      setState(() {
        likedPosts = [];
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
        automaticallyImplyLeading: false,
        title: Text(
          user?.name ?? "username",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.black,
              size: 28,
            ),
            onPressed: _showSettingsBottomSheet,
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
                            )
                          else
                            GestureDetector(
                              onTap: () =>
                                  Get.to(() => const EditProfilePage()),
                              child: Text(
                                'เพิ่มชื่อและคำอธิบาย',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        width: double.infinity,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () =>
                                Get.to(() => const EditProfilePage()),
                            child: const Center(
                              child: Text(
                                "แก้ไขโปรไฟล์",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
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
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: selectedIndex == 0
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedIndex = 0;
                                        });
                                      },
                                      child: Icon(
                                        Icons.grid_on_outlined,
                                        color: selectedIndex == 0
                                            ? Colors.black
                                            : Colors.grey[400],
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: selectedIndex == 1
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedIndex = 1;
                                        });
                                      },
                                      child: Icon(
                                        Icons.bookmark_border,
                                        color: selectedIndex == 1
                                            ? Colors.black
                                            : Colors.grey[400],
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: selectedIndex == 2
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedIndex = 2;
                                        });
                                      },
                                      child: Icon(
                                        Icons.favorite_border,
                                        color: selectedIndex == 2
                                            ? Colors.black
                                            : Colors.grey[400],
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    List<dynamic>? posts;
    
    if (selectedIndex == 2) {
      posts = likedPosts;
    } else {
      posts = userPosts;
    }

    // แสดง loading indicator เฉพาะตอน refresh
    if (posts == null && _isRefreshing) {
      return Container(
        height: 200,
        child: const Center(
          child: CircularProgressIndicator(
              color: Colors.black, strokeWidth: 2),
        ),
      );
    }

    // ถ้าไม่มีข้อมูลหรือข้อมูลว่าง
    if (posts == null || posts.isEmpty) {
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
                border: Border.all(
                    color: Colors.black, width: 2),
              ),
              child: Icon(
                selectedIndex == 2
                    ? Icons.favorite_border
                    : Icons.camera_alt_outlined,
                size: 24,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              selectedIndex == 2
                  ? 'ยังไม่มีโพสต์ที่ถูกใจ'
                  : 'แชร์ภาพถ่าย',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              selectedIndex == 2
                  ? 'เมื่อคุณกดใจภาพถ่ายและวิดีโอ\nภาพเหล่านั้นจะปรากฏที่นี่'
                  : 'เมื่อคุณแชร์ภาพถ่ายและวิดีโอ ภาพเหล่านั้น\nจะปรากฏในโปรไฟล์ของคุณ',
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54),
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
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts![index];
        String? imageUrl;

        if (selectedIndex == 2) {
          // สำหรับโพสต์ที่ถูกใจ ใช้ modelp.GetPostLike
          final likedPost = post as modelp.GetPostLike;
          imageUrl = likedPost.images.isNotEmpty
              ? likedPost.images.first.image
              : null;
        } else {
          // สำหรับโพสต์ของผู้ใช้ ใช้ model.GetPostUser
          final userPost = post as model.GetPostUser;
          imageUrl = userPost.images.isNotEmpty
              ? userPost.images.first.image
              : null;
        }

        return GestureDetector(
          onTap: () {
            if (selectedIndex == 0) {
              final userPost = post as model.GetPostUser;
              Get.to(() => UserDetailPost(postUser: userPost));
            }
          },
          child: Container(
            color: Colors.grey[100],
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(
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

  void _showSettingsBottomSheet() {
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
                leading: const Icon(Icons.settings_outlined),
                title: const Text('การตั้งค่า'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('กิจกรรมของคุณ'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('QR Code'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('บันทึกแล้ว'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ออกจากระบบ'),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.logout, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'ออกจากระบบ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await logoutUser();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> logoutUser() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      await gs.erase();
      Get.offAllNamed('/login');
    } catch (e) {
      log("เกิดข้อผิดพลาดขณะออกจากระบบ: $e");
    }
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