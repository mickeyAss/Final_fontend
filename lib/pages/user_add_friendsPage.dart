import 'dart:async';
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
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  final GetStorage gs = GetStorage();
  late int loggedInUid;

  Set<int> followingUserIds = {};

  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeData();
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
  }

  /// ================== API Load Users ==================
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

  /// ================== API Search Users ==================
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        filteredUsers = user;
      });
      return;
    }

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response =
          await http.get(Uri.parse("$url/user/search-users?name=$query"));

      if (response.statusCode == 200) {
        final searchResults = getAllUserFromJson(response.body);
        setState(() {
          filteredUsers = searchResults;
        });
        log('Search results: ${searchResults.length} users');
      } else {
        log('Search failed: ${response.body}');
        setState(() {
          filteredUsers = [];
        });
      }
    } catch (e) {
      log('Error searching users: $e');
      setState(() {
        filteredUsers = [];
      });
    }
  }

  /// ================== API Follow / Unfollow ==================
  Future<void> followUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse('$url/user/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "follower_id": loggedInUid,
          "following_id": targetUserId,
        }),
      );

      if (response.statusCode == 200) {
        log('ติดตามผู้ใช้ $targetUserId สำเร็จ');
        setState(() {
          followingUserIds.add(targetUserId);
        });
      } else {
        log('เกิดข้อผิดพลาดในการติดตาม: ${response.body}');
        _showErrorSnackBar('ไม่สามารถติดตามได้ในขณะนี้');
      }
    } catch (e) {
      log('Error following user: $e');
      _showErrorSnackBar('เกิดข้อผิดพลาดในการติดตาม');
    }
  }

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
        log('เลิกติดตามผู้ใช้ $targetUserId สำเร็จ');
        setState(() {
          followingUserIds.remove(targetUserId);
        });
      } else {
        log('เกิดข้อผิดพลาดในการเลิกติดตาม: ${response.body}');
        _showErrorSnackBar('ไม่สามารถเลิกติดตามได้ในขณะนี้');
      }
    } catch (e) {
      log('Error unfollowing user: $e');
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลิกติดตาม');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// ================== UI ==================
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
            // Search Header
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
                              color: Colors.grey[600], size: 22),
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded,
                                    color: Colors.grey[600], size: 20),
                                onPressed: () {
                                  searchController.clear();
                                  searchUsers('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          searchUsers(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'พบผู้ใช้ ${filteredUsers.length} คน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isRefreshing) ...[
                        const Spacer(),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // User List
            Expanded(
              child: _buildUserList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
          strokeWidth: 2,
        ),
      );
    }

    if (_errorMessage != null && user.isEmpty) {
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
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _refreshData,
              child: const Text(
                'ลองใหม่',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    if (filteredUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
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
                  const SizedBox(height: 8),
                  Text(
                    'ลากลงเพื่อรีเฟรช',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.black,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
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
                                  border:
                                      Border.all(color: Colors.white, width: 2),
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
                              isFollowing
                                  ? 'คุณติดตามผู้ใช้นี้แล้ว'
                                  : 'แนะนำสำหรับคุณ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isFollowing
                                    ? Colors.green[600]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isFollowing ? Colors.grey[100] : Colors.black87,
                          foregroundColor:
                              isFollowing ? Colors.black87 : Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isFollowing
                                  ? Colors.grey[300]!
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                              isFollowing
                                  ? Icons.person_remove_rounded
                                  : Icons.person_add_rounded,
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
      ),
    );
  }
}
