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
import 'package:fontend_pro/models/get_post_user.dart' as model;

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  int selectedIndex = 0;
  GetUserUid? user;
  final GetStorage gs = GetStorage();
  late Future<void> _loadUserFuture;
  late Future<List<model.GetPostUser>> userPostsFuture;
  bool _isLoading = false;

  int followersCount = 0;
  int followingCount = 0;
  int postsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserFuture = loadDataUser();
    userPostsFuture = loadUserPosts();
  }

  Future<void> loadDataUser() async {
    setState(() {
      _isLoading = true;
    });

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
          _isLoading = false;
        });
        log("โหลดข้อมูลสำเร็จ: ${response.body}");
        
        await _loadFollowCounts();
        
      } else {
        log('โหลดข้อมูลไม่สำเร็จ: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
        throw Exception('โหลดข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      rethrow;
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadUserFuture = loadDataUser();
      userPostsFuture = loadUserPosts();
    });
    
    _loadPostsCount();
  }

  Future<List<model.GetPostUser>> loadUserPosts() async {
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
      postsCount = posts.length;
    });

    return posts;
  }

  Future<void> _loadPostsCount() async {
    try {
      final posts = await loadUserPosts();
      setState(() {
        postsCount = posts.length;
      });
    } catch (e) {
      log('Error loading posts count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          FutureBuilder(
            future: _loadUserFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  user == null) {
                return _buildLoadingWidget();
              } else if (snapshot.hasError && user == null) {
                return _buildErrorWidget();
              }

              return RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.black,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildProfileHeader()),
                    SliverToBoxAdapter(child: _buildActionButtons()),
                    SliverToBoxAdapter(child: _buildPostsSection()),
                  ],
                ),
              );
            },
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile picture
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user?.profileImage != null
                      ? NetworkImage(user!.profileImage!)
                      : null,
                  child: user?.profileImage == null
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
              ),

              const SizedBox(width: 28),

              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(postsCount.toString(), "โพส"),
                    _buildStatColumn(followersCount.toString(), "ผู้ติดตาม"),
                    _buildStatColumn(followingCount.toString(), "กำลังติดตาม"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Name and bio
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
              onTap: () => Get.to(() => const EditProfilePage()),
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
    );
  }

  

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
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
            onTap: () => Get.to(() => const EditProfilePage()),
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
    );
  }

  Widget _buildPostsSection() {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Tab bar
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              _buildTab(Icons.grid_on_outlined, 0),
              _buildTab(Icons.bookmark_border, 1),
              _buildTab(Icons.favorite_border, 2),
            ],
          ),
        ),

        // Posts content
        FutureBuilder<List<model.GetPostUser>>(
          future: userPostsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildPostsLoadingWidget();
            } else if (snapshot.hasError) {
              return _buildPostsErrorWidget();
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyPostsWidget();
            }

            return _buildPostsGrid(snapshot.data!);
          },
        ),
      ],
    );
  }

  Widget _buildTab(IconData icon, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey[400],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid(List<model.GetPostUser> posts) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postUser = posts[index];
        final imageUrl =
            postUser.images.isNotEmpty ? postUser.images.first.image : null;

        return GestureDetector(
          onTap: () {
            Get.to(() => UserDetailPost(postUser: postUser));
          },
          child: Container(
            color: Colors.grey[100],
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.broken_image,
                        color: Colors.grey[400],
                        size: 40,
                      );
                    },
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

  Widget _buildEmptyPostsWidget() {
    if (selectedIndex == 0) {
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
              'แชร์ภาพถ่าย',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เมื่อคุณแชร์ภาพถ่ายและวิดีโอ ภาพเหล่านั้น\nจะปรากฏในโปรไฟล์ของคุณ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {},
              child: const Text(
                'แชร์ภาพถ่ายแรกของคุณ',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
            child: Icon(
              selectedIndex == 1 ? Icons.bookmark_border : Icons.favorite_border,
              size: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            selectedIndex == 1 ? 'ภาพที่บันทึกไว้' : 'ภาพที่ชื่นชอบ',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedIndex == 1 
                ? 'เมื่อคุณบันทึกภาพถ่ายและวิดีโอ\nภาพเหล่านั้นจะปรากฏที่นี่'
                : 'เมื่อคุณกดใจภาพถ่ายและวิดีโอ\nภาพเหล่านั้นจะปรากฏที่นี่',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.black,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          const Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _loadUserFuture = loadDataUser();
              });
            },
            child: const Text(
              'ลองใหม่',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildPostsLoadingWidget() {
    return Container(
      height: 200,
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildPostsErrorWidget() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'ไม่สามารถโหลดโพสต์ได้',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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