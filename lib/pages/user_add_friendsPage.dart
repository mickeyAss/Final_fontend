import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_user.dart';

class UserAddFriendspage extends StatefulWidget {
  const UserAddFriendspage({super.key});

  @override
  State<UserAddFriendspage> createState() => _UserAddFriendspageState();
}

class _UserAddFriendspageState extends State<UserAddFriendspage> {
  List<GetAllUser> user = [];
  List<GetAllUser> filteredUsers = [];
  late Future<void> loadData_user;
  TextEditingController searchController = TextEditingController();

  final GetStorage gs = GetStorage();
  late int loggedInUid;

  // เก็บ uid ของผู้ใช้ที่ติดตามอยู่ (สถานะติดตาม)
  Set<int> followingUserIds = {};

  @override
  void initState() {
    super.initState();

    dynamic rawUid = gs.read('user');
    if (rawUid is int) {
      loggedInUid = rawUid;
    } else if (rawUid is String) {
      loggedInUid = int.tryParse(rawUid) ?? 0;
    } else {
      loggedInUid = 0;
    }

    loadData_user = loadDataUser(loggedInUid);
  }

  void filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = user;
      } else {
        filteredUsers = user
            .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'ค้นหาเพื่อน',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Header Container with Search
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อเพื่อน...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.search_rounded, 
                            color: Colors.grey[600], 
                            size: 22
                          ),
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, 
                                  color: Colors.grey[600], 
                                  size: 20
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  filterUsers('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, 
                          horizontal: 20
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      onChanged: (value) {
                        filterUsers(value);
                        setState(() {});
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  Row(
                    children: [
                      Icon(Icons.people_outline_rounded, 
                        size: 20, 
                        color: Colors.grey[600]
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'พบผู้ใช้ ${filteredUsers.length} คน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User List
            Expanded(
              child: FutureBuilder(
                future: loadData_user,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'กำลังโหลดข้อมูล...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.red[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              searchController.text.isNotEmpty 
                                ? Icons.search_off_rounded 
                                : Icons.people_outline_rounded,
                              size: 48,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchController.text.isNotEmpty 
                              ? 'ไม่พบผู้ใช้ที่ค้นหา' 
                              : 'ไม่มีผู้ใช้งานให้แนะนำ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final users = filteredUsers[index];
                      final isFollowing = followingUserIds.contains(users.uid);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // บรรทัดแรก: รูปโปรไฟล์และชื่อ
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.grey[200]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.network(
                                            users.profileImage ?? '',
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 28,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isFollowing)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Colors.green[500],
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          users.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isFollowing ? 'คุณติดตามผู้ใช้นี้แล้ว' : 'แนะนำสำหรับคุณ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isFollowing ? Colors.green[600] : Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // บรรทัดที่สอง: ปุ่มติดตาม
                              SizedBox(
                                width: double.infinity,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing ? Colors.grey[100] : Colors.black87,
                                      foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: isFollowing ? Colors.grey[300]! : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      minimumSize: const Size(double.infinity, 40),
                                    ),
                                    onPressed: () {
                                      if (isFollowing) {
                                        unfollowUser(users.uid);
                                      } else {
                                        followUser(users.uid);
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isFollowing ? Icons.person_remove_rounded : Icons.person_add_rounded,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isFollowing ? 'เลิกติดตาม' : 'ติดตาม',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadDataUser(int loggedInUid) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final response = await http.get(Uri.parse("$url/user/users-except?uid=$loggedInUid"));

    if (response.statusCode == 200) {
      user = getAllUserFromJson(response.body);
      filteredUsers = user; // Initialize filtered list
      log('response : ${response.body}');

      // TODO: ดึงข้อมูล user ที่ติดตามอยู่จริงจาก API และเก็บใน followingUserIds
      // ตัวอย่าง:
      // final followingResp = await http.get(Uri.parse("$url/user/following?uid=$loggedInUid"));
      // if (followingResp.statusCode == 200) {
      //   List<int> followingList = parseFollowingIds(followingResp.body);
      //   followingUserIds = followingList.toSet();
      // }

      setState(() {});
    } else {
      log('Error loading user data: ${response.statusCode}');
    }
  }

  Future<void> followUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse('$url/user/follow'),
        headers: {'Content-Type': 'application/json'},
        body: '{"follower_id": $loggedInUid, "following_id": $targetUserId}',
      );

      if (response.statusCode == 200) {
        log('ติดตามผู้ใช้ $targetUserId สำเร็จ');

        setState(() {
          followingUserIds.add(targetUserId);
        });
      } else {
        log('เกิดข้อผิดพลาดในการติดตาม: ${response.body}');
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  Future<void> unfollowUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final uri = Uri.parse('$url/user/unfollow');

      // สร้าง request แบบ manual เพราะ http.delete ไม่รองรับ body
      final request = http.Request('DELETE', uri);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'follower_id': loggedInUid,
        'following_id': targetUserId,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        log('เลิกติดตามผู้ใช้ $targetUserId สำเร็จ');
        setState(() {
          followingUserIds.remove(targetUserId);
        });
      } else {
        log('เกิดข้อผิดพลาดในการเลิกติดตาม: ${response.body}');
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}