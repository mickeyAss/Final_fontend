import 'dart:convert';
import 'dart:developer';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/edit_profile.dart';
import 'package:fontend_pro/models/get_user_uid.dart';
import 'package:fontend_pro/pages/user_detail_post.dart';
import 'package:fontend_pro/models/get_post_user.dart' as model;

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  GetUserUid? user;
  final GetStorage gs = GetStorage();
  late Future<void> _loadUserFuture;
  late Future<List<model.GetPostUser>> userPostsFuture;
  late AnimationController _profileAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _profileAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserFuture = loadDataUser();
    userPostsFuture = loadUserPosts(); // คืนค่า Future<List<GetPostUser>>

    // Setup animations
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _profileAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _profileAnimationController.forward();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _profileAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<void> loadDataUser() async {
    if (user != null) {
      setState(() {
        _isLoading = true;
      });
    }

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
      _loadUserFuture = loadDataUser(); // โหลดข้อมูล user ใหม่
      userPostsFuture = loadUserPosts(); // คืนค่า Future<List<GetPostUser>>
    });
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

    return posts;
  }

// ถ้าต้องการดึงเฉพาะ URL รูปภาพทั้งหมดจากโพสต์เหล่านี้ ก็ทำแบบนี้ได้
  Future<List<String>> loadAllUserPostImages() async {
    final posts = await loadUserPosts();
    final List<String> imageUrls = [];

    for (var postUser in posts) {
      for (var image in postUser.images) {
        imageUrls.add(image.image);
      }
    }

    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading:
          false, // เพิ่มบรรทัดนี้เพื่อไม่ให้แสดงปุ่มกลับอัตโนมัติ
      title: Column(
        children: [
          Text(
            user?.name ?? "Profile",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            width: 30,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.black,
                size: 18,
              ),
            ),
            onPressed: _showSettingsBottomSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          // Profile Image with minimal design
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: NetworkImage(user?.profileImage ?? ''),
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name/Description
          if (user?.personalDescription != null &&
              user!.personalDescription!.trim().isNotEmpty)
            Text(
              user!.personalDescription!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            )
          else
            GestureDetector(
              onTap: () => Get.to(() => const EditProfilePage()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'เพิ่มชื่อของคุณ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard("30", "โพสต์", Icons.grid_view_rounded),
              _buildStatCard("100", "ติดตาม", Icons.favorite_rounded),
              _buildStatCard("120", "ผู้ติดตาม", Icons.people_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Get.to(() => const EditProfilePage()),
                  child: const Center(
                    child: Text(
                      "แก้ไขโปรไฟล์",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: const Icon(
                  Icons.share_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Custom Tab Design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                _buildCustomTab(
                  icon: Icons.grid_view_rounded,
                  label: "โพสต์",
                  index: 0,
                  isSelected: selectedIndex == 0,
                ),
                _buildCustomTab(
                  icon: Icons.favorite_rounded,
                  label: "ถูกใจ",
                  index: 1,
                  isSelected: selectedIndex == 1,
                ),
                _buildCustomTab(
                  icon: Icons.bookmark_rounded,
                  label: "บันทึก",
                  index: 2,
                  isSelected: selectedIndex == 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Posts Grid
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
      ),
    );
  }

  Widget _buildCustomTab({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid(List<model.GetPostUser> posts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_rounded,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPostsWidget() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              size: 40,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ยังไม่มีโพสต์',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เริ่มแชร์ความทรงจำดีๆ ของคุณ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'สร้างโพสต์แรก',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade800,
              Colors.grey.shade600,
            ],
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
  

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
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
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              'ไม่สามารถโหลดโพสต์ได้',
              style: TextStyle(
                color: Colors.grey.shade600,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'บัญชี',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSettingsItem(
                icon: Icons.logout_rounded,
                title: 'ออกจากระบบ',
                color: Colors.black87,
                onTap: _showLogoutDialog,
              ),
              _buildSettingsItem(
                icon: Icons.delete_outline,
                title: 'ลบบัญชีผู้ใช้',
                color: Colors.black54,
                onTap: () {
                  Navigator.of(context).pop();
                  Get.snackbar(
                    'ลบบัญชี',
                    'ยังไม่ได้เชื่อม API สำหรับลบบัญชี',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.grey.shade200,
                    colorText: Colors.black87,
                    borderRadius: 12,
                    margin: const EdgeInsets.all(16),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: color,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ออกจากระบบ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'ยกเลิก',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            gs.erase().then((_) {
                              Navigator.of(context).pop();
                              Get.offAllNamed('/login');
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'ออกจากระบบ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
